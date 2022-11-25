#! /usr/bin/env bash

#
#     beaver build script
#
#     (c)2020-2022 Project Alexandrite
#
#     build.sh
#

set -eu
trap sigint sigint
trap error_exit ERR

# カレントディレクトリ取得
current_dir="$(cd "$(dirname "${0}")" && pwd)"

# このスクリプトを実行したユーザー
non_root_user=${SUDO_USER}

# tmpfsの制限
tmpfs_limit=8000M

# デバッグモードか
debug_mode=false

# セーフモード（tmpfs不使用モード）の場合trueになる
do_not_use_tmpfs=false

# ビルドの高速化を使うか（大容量RAMが必要）
use_thunderbuild=false

# 値がreleaseの場合パッケージ化とデプロイを行う。通常はnightly。
build_type=nightly



function sigint() {
    # この関数内ではエラーを無視する
    set +e

    _msg_error "割込を検出。強制終了します。"
    
    umount $current_dir/tmp > /dev/null 2>&1
    umount $current_dir/out/build > /dev/null 2>&1
    
    rm -rf $current_dir/tmp > /dev/null 2>&1
    rm -rf $current_dir/out > /dev/null 2>&1
    
    exit 1    
}

function error_exit() {
    # この関数内ではエラーを無視する
    set +e

    _msg_error "エラーを検出。中止します。"
    
    umount $current_dir/tmp > /dev/null 2>&1
    umount $current_dir/out/build > /dev/null 2>&1
    
    rm -rf $current_dir/tmp > /dev/null 2>&1
    rm -rf $current_dir/out > /dev/null 2>&1
    
    exit 1    
}

function _msg_error(){ echo -e "\e[31m✗\e[m" "[ERROR] ${*}" >&2; }
function _msg_warn (){ echo -e "\e[33m!\e[m" "[WARNING] ${*}" >&1; }
function _msg_info (){ echo -e "\e[32m✓\e[m" "[INFO] ${*}" >&1; }
function _msg_debug (){ [[ ${debug_mode} = true ]] && echo -e "\e[34mi\e[m" "[DEBUG] ${*}" >&1; }


function critical_error () {
    echo -e "\e[31m✗ [ERROR] (${1}: ${2}: ${3}) \e[m" >&2;
    exit 1
}

function chk-command () {
    local chk_command="${1}"
    echo -n "[INFO] checking $chk_command"
    if type "${chk_command}" > /dev/null 2>&1; then
      echo -e ">>>" "\e[32m✓\e[m" "ok!"
    else
      echo -e ">>>" "\e[31m✗\e[m" "not found!"
      _msg_error "${chk_command} が使用できないため続行できません。中止します。"
      exit 1
    fi
}


# オプション解析
opts=("t:" "l:" "d" "v:" "b" "s" "r") optl=("target:" "lang:" "debug" "version:" "boost" "safemode" "release")
getopt=(-o "$(printf "%s," "${opts[@]}")" -l "$(printf "%s," "${optl[@]}")" -- "${@}")
getopt -Q "${getopt[@]}" || exit 1 # 引数エラー判定
readarray -t opt < <(getopt "${getopt[@]}") # 配列に代入
eval set -- "${opt[@]}" # 引数に設定
unset opts optl getopt opt # 使用した配列を削除

while true; do
  case "${1}" in
    "-t" | "--target" ) target="${2}"       && shift 2 ;;
    "-l" | "--lang"   ) over_locale="${2}"  && shift 2 ;;
    "-d" | "--debug" ) debug_mode=true   && shift 1 ;;
    "-v" | "--version") over_version="${2}" && shift 2 ;;
    "-b" | "--boost" ) use_thunderbuild=true   && shift 1 ;;
    "-s" | "--safemode" ) do_not_use_tmpfs=true   && shift 1 ;;
    "-r" | "--release" ) build_type=release   && shift 1 ;;
    "--"              ) shift 1             && break   ;;
    *) 
        exit 1
        ;;
  esac
done
#target="${1-""}"

# 生存確認
chk-command kiwi-ng
chk-command xorriso
chk-command sha256sum



# debugモードか
if [ "${debug_mode}" = true ]; then
    _msg_info "デバッグモードを利用します。イメージのビルドを行いません。"
else
    _msg_info "イメージをビルドします。"
fi

# カレントディレクトリが取得できてるか（事故防止）
if [[ -z "${current_dir}" ]]; then
    _msg_error "current_dirが未定義です。終了します。"
    exit 1
fi

# 引数をチェック
[[ -z "${target}" ]] && _msg_error "ターゲットを指定してください" >&2 && exit 1

# targetsディレクトリが存在すればそれを使う
if [ -d "targets" ]; then
    _msg_info "targetsディレクトリが検出されました。targets内のターゲットディレクトリのみ使用します。"
    target=targets/${target}
fi

# ターゲットディレクトリをチェック
if [ -d "${target}" ]; then
    _msg_info "レシピ ${target} を使用します"
    target="$(realpath "${target}")"
    cd "${target}" || exit 1
else
    _msg_error "指定したレシピ（\"$target\"）が存在しません。中止します。"
    exit 1
fi

_msg_info "レシピに必要なファイルを確認しています"

if [ -f "${target}/base.conf" ] && [ -f "${target}/main.packages" ] && [ -f "${target}/bootstrap.packages" ]; then
   _msg_info "必要なファイルの存在を確認しました"
else
   _msg_error "レシピに必要なファイルが存在しません。中止します。"
   exit 1
fi


# 設定読み込み
_msg_info "base.confを読み込んでいます..."
source "${target}/base.conf"


# 引数が指定されている場合、値を上書き
locale="${over_locale-"${locale}"}"
version="${over_version-"${version}"}"



# ローカライズ確認
if [ -d "${target}/I18n/${locale}" ]; then
    _msg_info "リージョン ${locale} を使用します"
else
    _msg_error  "ローカライズファイルのディレクトリ（I18n/${locale}）が見つかりません。中止します。"
    exit 1
fi

if [ -f "${target}/I18n/${locale}/locale.conf" ]; then
   _msg_info "ローカライズの設定ファイルに ${locale}/locale.conf を使用します。"
else
   _msg_error "ローカライズ設定ファイル（I18n/$locale/locale.conf）が存在しません。中止します。"
   exit 1
fi

# ローカライズ設定読み込み
source "${target}/I18n/$locale/locale.conf"

# 一時ディレクトリ作成
cd "${current_dir}" || exit 1
_msg_info "一時ディレクトリを作成します。"
sudo rm -rf  tmp out

mkdir $current_dir/tmp
if [[ ${do_not_use_tmpfs} != true ]]; then
    _msg_info "一時ファイル用にtmpfsを作成します。"
    mount -t tmpfs -o size=1000M tmpfs $current_dir/tmp
else
    _msg_warn "一時ファイル用にtmpfsを使用しません。"
fi

mkdir -p out tmp/kiwi tmp/config

_msg_info "レシピからkiwi-ng向けの設定ファイルを生成します。"
mkdir tmp/config/root
mkdir tmp/beaver

# ユニット機能実行
# unit.confが存在するか確認
if [ -f "${target}/unit.conf" ]; then
    _msg_info "ユニット設定ファイル${target}/unit.confを読み込みます。"

    # 設定読み込み
    source "${target}/unit.conf" 

    # unit.confのunitsの値を配列に代入
    use_unit=($units)

    _msg_info "ターゲットディレクトリ：${target}"

    unit_counts=${#use_unit[@]}

    while [[ $unit_counts -gt 0 ]]; do

        unit_counts=$(( unit_counts - 1 ))
        unit_name=${use_unit[$unit_counts]}
        _msg_info "ユニット${unit_name}を読み込みます。"

        # ディレクトリ内にオーバーレイディレクトリが存在すればコピー
        _msg_info "ユニット${unit_name}のオーバーレイディレクトリをコピーします。"
        [[ -d "${current_dir}/units/${unit_name}/share/root" ]] && cp -r "units/${unit_name}/share/root" "tmp/config/"
        [[ -d "${current_dir}/units/${unit_name}/${base_dist}/root" ]] && cp -r "units/${unit_name}/${base_dist}/root" "tmp/config/"

        # パッケージリストがあれば追記
        _msg_info "ユニット${unit_name}のパッケージリストをマージします。"
        [[ -f "${current_dir}/units/${unit_name}/share/unit.packages" ]] && cat "units/${unit_name}/share/unit.packages" >> tmp/beaver/main.packages.tmp
        [[ -f "${current_dir}/units/${unit_name}/${base_dist}/unit.packages" ]] && cat "units/${unit_name}/${base_dist}/unit.packages" >> tmp/beaver/main.packages.tmp

        # スクリプトがあれば実行 (引数: ディストロ名)
        _msg_info "ユニット${unit_name}のunit.shを実行します。"
        [[ -d "${current_dir}/tmp/config/root" ]] && cd "tmp/config/root"
        [[ -f "${current_dir}/units/${unit_name}/share/unit.sh" ]] && bash ${current_dir}/units/${unit_name}/share/unit.sh $specification
        [[ -f "${current_dir}/units/${unit_name}/${base_dist}/unit.sh" ]] && bash ${current_dir}/units/${unit_name}/${base_dist}/unit.sh $specification


    done   

else
    _msg_info "おっと！ ${target}/unit.confが見つかりません。ユニットを利用しません。"
fi

target_basename=`basename ${target}`


cp -r "${target}/overlay" "tmp/config/"
cp "${target}/final_process.sh" "tmp/config/"
[[ -f "${target}/bootstrap.sh" ]] && cp "${target}/bootstrap.sh" "tmp/config/"
mv "tmp/config/final_process.sh" "tmp/config/config.sh"
[[ -f "tmp/config/bootstrap.sh" ]] && mv "tmp/config/bootstrap.sh" "tmp/config/post_bootstrap.sh"



# Flatpakパッケージを追加
if [ -f "${target}/flatpak.packages" ]; then
    _msg_info "Flatpakパッケージ一覧を読み込んでいます。"
    addpkg_flatpak_pkgs_list=`cat ${target}/flatpak.packages | tr "\n" " ";echo`
    addpkg_flatpak_pkgs_install_command="flatpak install ${addpkg_flatpak_pkgs_list} --assumeyes --system"

    _msg_info "利用パッケージ: ${addpkg_flatpak_pkgs_list}"

    echo "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo --system" >> tmp/config/config.sh
    echo ${addpkg_flatpak_pkgs_install_command} >> tmp/config/config.sh
else
    _msg_info "Flatpakパッケージを利用しません。"
fi

# パッケージの数をカウント
mainpkg_counts="$(sed '/^#/d' "${target}/main.packages" | wc -l)"
bootstrappkg_counts="$(sed '/^#/d' "${target}/bootstrap.packages" | wc -l)"
#localepkg_counts="$(sed '/^#/d' "${target}/I18n/${locale}/locale.packages" | wc -l)"
localepkg_counts="$(cat "${target}/I18n/${locale}/locale.packages" | grep -vE '^\s*$' | grep -vE '^\s*#' | wc -l)"


# コメントを除去したパッケージリストを作成
touch tmp/beaver/main.packages.tmp
sed '/^#/d' "${target}/main.packages" >> tmp/beaver/main.packages.tmp

touch tmp/beaver/bootstrap.packages.tmp
sed '/^#/d' "${target}/bootstrap.packages" >> tmp/beaver/bootstrap.packages.tmp

touch tmp/beaver/bootstrap.packages.tmp
#sed '/^#/d' "${target}/I18n/${locale}/locale.packages" > tmp/beaver/locale.packages.tmp
cat "${target}/I18n/${locale}/locale.packages" | grep -vE '^\s*$' | grep -vE '^\s*#' > tmp/beaver/locale.packages.tmp


# overlayディレクトリ内のパッケージを追加
if [[ ${build_type} = release ]]; then
    ls ${target}/overlay | sed 's/ /¥n/g' >> tmp/beaver/main.packages.tmp
fi


overlaydir_pkg_counts=`ls -l ${target}/overlay | grep ^d | wc -l`
mainpkg_counts=$(( mainpkg_counts + overlaydir_pkg_counts )) 


# xmlファイル生成
touch tmp/config/config.xml

_msg_info "config.xmlを生成します"

# xml生成処理では未定義の変数を許可する
set +u

# xml生成処理
cat <<EOF >  tmp/config/config.xml
<?xml version="1.0" encoding="utf-8"?>
<image schemaversion="$schemaversion" name="$name">
    <description type="system">
        <author>$author</author>
        <contact>$contact</contact>
        <specification>$specification</specification>
    </description>
    <profiles>
        <profile name="DracutLive" description="Simple Live image" import="true"/>
        <profile name="Live" description="Live image"/>
        <profile name="Virtual" description="Simple Disk image"/>
        <profile name="Disk" description="Expandable Disk image"/>
    </profiles>
    <preferences>
        <version>$version</version>
        <packagemanager>$packagemanager</packagemanager>
        <locale>$locale</locale>
        <keytable>$keytable</keytable>
        <timezone>$timezone</timezone>
        <rpm-excludedocs>$rpm_xcludedocs</rpm-excludedocs>
        <rpm-check-signatures>$rpm_check_signatures</rpm-check-signatures>
        <bootsplash-theme>$bootsplash_theme</bootsplash-theme>
        <bootloader-theme>$bootloader_theme</bootloader-theme>
        <type image="$image" flags="$flags" firmware="$firmware" kernelcmdline="$kernelcmdline" hybridpersistent_filesystem="$hybridpersistent_filesystem" hybridpersistent="$hybridpersistent" mediacheck="$mediacheck" squashfscompression="zstd">
            <bootloader name="$bootloader" console="$console" timeout="$timeout"/>
        </type>
    </preferences>
    <users>
        <user password="$root_password" pwdformat="plain" home="/root" name="root" groups="root"/>
        <user password="$liveuser_password" pwdformat="plain" home="/home/$liveuser_name" name="$liveuser_name" groups="$liveuser_name"/>
    </users>
EOF

# メインレポジトリの記述
if [ "$packagemanager" = "apt" ]; then
    echo "    <repository type=\"$repotype\" distribution=\"$apt_distro\" use_for_bootstrap=\"true\" components=\"main multiverse restricted universe\" repository_gpgcheck=\"false\">" >> tmp/config/config.xml
elif [ "$packagemanager" = "pacman" ]; then
    echo "    <repository alias=\"$repo1_alias\">" >> tmp/config/config.xml
else
    echo "    <repository type=\"$repotype\">" >> tmp/config/config.xml
fi

cat <<EOF >>  tmp/config/config.xml
        <source path="$url1"/>
    </repository>
EOF



addrepo_loop_count=1

# レポジトリの個数を判定
repository_counts=0
getRepoCounts_loop_count=0

while true
do
    getRepoCounts_loop_count=$(( getRepoCounts_loop_count + 1 ))
    getRepoCounts_loop_value_name=url$getRepoCounts_loop_count
    getRepoCounts_loop_url=${!getRepoCounts_loop_value_name}

    if [[ -z "${getRepoCounts_loop_url}" ]]; then
        _msg_info "${repository_counts}個のレポジトリを読み込みました。"
        break
    else        
        repository_counts=$(( repository_counts + 1 ))
        _msg_info "${repository_counts}個目のレポジトリとして ${getRepoCounts_loop_url} を使用します。"
    fi 
done


# レポジトリ追記
while [[ "${addrepo_loop_count}" != "${repository_counts}" ]]; do

    addrepo_loop_count=$(( addrepo_loop_count + 1 ))

    addrepo_loop_url_path="url${addrepo_loop_count}"
    addrepo_loop_repo_cmp="apt_repo${addrepo_loop_count}_cmp"
    addrepo_loop_repo_alias="repo${addrepo_loop_count}_alias"

    if [ "$packagemanager" = "pacman" ]; then
        echo "    <repository alias=\"${!addrepo_loop_repo_alias}\">" >> tmp/config/config.xml
    elif [ -z "${!addrepo_loop_repo_cmp}" ]; then
        echo "    <repository type=\"$repotype\" repository_gpgcheck=\"false\">" >> tmp/config/config.xml
    else
        echo "    <repository type=\"$repotype\" distribution=\"$apt_distro\" components=\"${!addrepo_loop_repo_cmp}\" repository_gpgcheck=\"false\">" >> tmp/config/config.xml
    fi

    {
        echo "        <source path=\"""${!addrepo_loop_url_path}""\"/>"
         echo "    </repository>"
    } >> tmp/config/config.xml
    
done



# テンプレを追記
echo '    <packages type="image" patternType="plusRecommended">' >> tmp/config/config.xml



# main.packagesのパッケージを追記
addpkg_main_loop_counts=0
while [[ ${addpkg_main_loop_counts} != ${mainpkg_counts} ]]; do
    addpkg_main_loop_counts=$(( addpkg_main_loop_counts + 1 ))
    echo "        <package name=\"$(head -n $addpkg_main_loop_counts tmp/beaver/main.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml    
done

# ローカライズパッケージを追記
while [[ ${addpkg_locale_loop_counts} != ${localepkg_counts} ]]; do
    addpkg_locale_loop_counts=$(( addpkg_locale_loop_counts + 1 ))
    echo "        <package name=\"$(head -n $addpkg_locale_loop_counts tmp/beaver/locale.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
done


# テンプレを追記
cat <<EOF >>  tmp/config/config.xml
    </packages>
    <packages type="bootstrap">
EOF


# bootstrap.packagesのパッケージを追記
while [[ ${addpkg_bootstrap_loop_counts} != ${bootstrappkg_counts} ]]; do
    addpkg_bootstrap_loop_counts=$(( addpkg_bootstrap_loop_counts + 1 ))
    echo "        <package name=\"$(head -n $addpkg_bootstrap_loop_counts tmp/beaver/bootstrap.packages.tmp | tail -n 1)\"/>" >> tmp/config/config.xml
done


# テンプレを追記
cat <<EOF >>  tmp/config/config.xml
    </packages>
</image>
EOF

# これ以降は再び未定義の変数を許可しない
set -u

#debugモードなら終了
if [ ${debug_mode} = true ]; then
    _msg_info "デバッグモードです。終了します。"
    exit 0
fi

# thunderbuildを利用する場合は準備
if [ ${use_thunderbuild} = true ]; then

    _msg_info "ビルドの高速化機能を利用します。"
    _msg_warn "警告： ビルドの高速化機能を利用しようとしています。この機能は最低でもRAMを10GB使用します。ビルドする前に他の全てのアプリケーションを終了し、ビルド中は他の作業を行わないでください。"

    mkdir -p $current_dir/out/build
    mount -t tmpfs -o size=$tmpfs_limit tmpfs $current_dir/out/build
    df

fi



# kiwi-ngでビルド
_msg_info  "kiwi-ngでのビルドを開始します。"

# これ以降エラーは無視（エラー処理があるため）
set +e

if sudo kiwi-ng system build --description "${current_dir}/tmp/config" --target-dir "${current_dir}/out"; then
    _msg_info "一時ファイルを削除します"
    [[ ${do_not_use_tmpfs} != true ]] && umount $current_dir/tmp
    [[ ${use_thunderbuild} = true ]] && umount $current_dir/out/build

    # md5sum生成
    cd out
    _msg_info "sha256チェックサムを生成します。"
    out_isofile=`find -name "*.iso"`
    touch "${out_isofile}.sha256"
    sha256sum ${out_isofile} > ${out_isofile}.sha256
    _msg_info "クリーンアップの実行中"
    rm -f *.changes *.verified *.result *.result.json
    cd ..
    
    rm -rf $current_dir/out/build $current_dir/tmp
    _msg_info "Done! :)"
    exit 0
else
    _msg_error "ビルドに失敗しました。kiwi-ngが0以外の終了コードで終了しました。エラーログを生成します。"

    # ログ生成
    touch out/error.log
    echo "beaver error log" > out/error.log
    date >> out/error.log
    echo "=======kiwi-ng log=======" >> out/error.log
    cat out/build/image-root.log >> out/error.log
    echo "=======config.xml=======" >> out/error.log
    cat tmp/config/config.xml >> out/error.log
    echo "=======filesystem=======" >> out/error.log
    df >> out/error.log
    # echo "=======file tree=======" >> out/error.log
    # tree out/build/image-root >> out/error.log

    _msg_info "out/error.log にログとデバッグに必要な情報が出力されました。"

    [[ ${do_not_use_tmpfs} != true ]] && umount $current_dir/tmp
    [[ ${use_thunderbuild} = true ]] && umount $current_dir/out/build
    rm -rf $current_dir/out/build $current_dir/tmp
    exit 1
fi
