## アップデーター関係の仕様

### すべてのはじまり
`sudo zypper dup`などのコマンドでアップデートが行われた際、システムファイルは更新されるがユーザースペース（ここではホームディレクトリ下にある設定ファイルなどのこと）のファイルは更新されない。システムファイルとユーザースペースに不整合が発生するとデスクトップが壊れるためアップデート直後の初回ログイン時にユーザースペースのアップデートを行う必要がある。この一連の処理の流れの備忘録です。

### 注意
そもそもユーザースペースとシステムファイルの間に不整合が発生するようなアップデートを行うシーンは稀であるため、このドキュメントを参考にする必要があるシーンは少ないです。


#### /etc/profile.d/sysupd-script.sh
ソースコードは`targets/alexandrite-workstation/overlay/alexandrite-shell/root/etc/profile.d/sysupd-script.sh`にあります。<br>
このスクリプトがログイン時に必ず呼び出されます。このスクリプトは`/usr/libexec/sysupd-script`を呼び出します。

#### /usr/libexec/sysupd-script
ソースコードは`targets/alexandrite-workstation/overlay/alexandriteos-system/root/usr/libexec/sysupd-script`にあります。<br>
このスクリプトの役割はユーザースペースとシステムファイルの整合性を検証することです。dconf(レジストリ)の`org.alexandriteos.userspace_version`にユーザースペースのバージョンが格納されています。またシステムファイルのバージョンが`/usr/share/alexandrite/version`の`version`セクションに格納されています。この２つの数値が等しい場合、sysupd-scriptはユーザースペースとシステムファイルの整合性は取れていると見なし何も行いません。<br>
しかしこれらの値が異なる場合、これはアップデート後最初のログインでありユーザースペースとシステムファイル間の整合性が失われていると見なし`/usr/share/system-updates/upd.sh`を実行します。<br>
実行後は`org.alexandriteos.userspace_version`を現在のシステムファイルのバージョンに設定し次システムファイルがアップデートされるまでは`/usr/share/system-updates/upd.sh`を実行しないようにします。

#### /usr/share/system-updates/upd.sh
ソースコードは`targets/alexandrite-workstation/overlay/alexandriteos-system/root/usr/share/system-updates/upd.sh`にあります。<br>
これにはユーザースペースとシステムファイルの整合性を取るための一連の処理が記述されています。例えば`gsettings set org.gnome.desktop.interface icon-theme "Adwaita"`というコマンドをこのスクリプトが実行することで3.20で行われたアイコンテーマのAdwaitaへの変更にユーザースペースの設定を合わせています。<br>
また最も重要なことはこのスクリプトはアップデート後最初のログイン時に必ず実行されるため不具合の修正にも利用できるということです。実際以下の部分で3.00に存在する日本語入力の不具合を修正しています。<br>
```
# 日本語入力のバグ修正
dconf write /org/gnome/desktop/input-sources/mru-sources "[('ibus', 'mozc-jp'), ('xkb', 'jp')]" && dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'jp'), ('ibus', 'mozc-jp')]"
```
このコマンドは3.00でなくてもアップデート後に毎回実行されますが特にそれで生じる問題はありません。しかしもし特定のバージョン（ここでは例として3.00）からのアップデート後のみ実行したいコマンドがある場合、以下のように書くと良いでしょう。<br>
```
userspace_version=`dconf read /org/alexandriteos/userspace_version`

if [ "$userspace_version" = "3.00" ]; then
	ここに処理を書く
fi

```
