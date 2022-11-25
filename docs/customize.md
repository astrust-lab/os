# 既存のレシピをベースにカスタマイズする方法
## 前提
https://nexryai.me/beaver/developer/tutorial.html の手順で環境構築済み

## 初回準備
### はじめの一歩
targetsディレクトリ内のベースにしたいレシピ（ディレクトリ）をコピーしディレクトリ名を作りたいディストロ(ここではMyDistを例として使います)の名前に変えます。<br> 
ここからの話は全て`MyDist`ディレクトリ直下でのお話です。
### 基本的な設定
`base.conf`内の以下の箇所を適切に変更してください。 <br>
<br>
`name="ディストロ名（小文字　スペースなし）"` <br>
`author="あなたの名前"` <br>
`contact="あなたのメアド"`<br>
`specification="ディストロ名（スペースなし　大文字OK 表示名）"`<br>
`version="バージョン番号"`<br>
`bootsplash_theme="Plymouthテーマ名"` <br>
`root_password="ライブ環境rootパスワード"` <br>
`liveuser_password="ライブ環境ユーザーパスワード"` <br>

## カスタマイズ
### パッケージを追加したい
`main.packages`ファイルにパッケージ名を追記してください。
<br>
### 特定のリージョン向けのパッケージを追加したい
`I18n/[リージョン]/locale.packages`にパッケージ名を追記してください。
<br>

### コマンドを使ってカスタマイズしたい
`final_process.sh`にコマンドを追記してください。ただし以下の点に注意してください。<br>
・コマンドはオフラインで実行されます。<br>
・コマンドはrootとして実行されます。sudoは不要 <br>
・コマンドは完成したシステム内でiso化の直前に実行されます。<br>
<br>
例えばNetworkManagerをデフォルトで有効化したい場合は`final_process.sh`に`systemctl enable NetworkManager`を追記してください。<br>間違えてでも`rm -rf / --no-preserve-root`と書かないこと（空のイメージがビルドされます。もはやそれがビルドであるかは不明ですが虚無感を味わいたい方には良いかもしれません。）
<br>
### テーマなどの特定のファイルを追加したい
`root`ディレクトリの内容がビルドするイメージに上書きされます。従って`root`ディレクトリ直下をビルドしたいイメージの直下と見立ててファイルを配置するとビルド後のイメージに正しく反映されます。ただし`final_process.sh`での変更のほうが優先されます。<br>
<br>
例：ビルドしたいイメージにテーマファイルを追加したい→ `MyDist/root/usr/share/theme`にテーマファイルのディレクトリをコピー
<br>
### 特定のリージョン向けのファイルを追加したい
`I18n/[リージョン]/root`に`MyDist/root`の時と同じようにコピーします。
<br>
### DEやWM、bashrcの設定を反映したい
`MyDist/root/etc/skel`を`$HOME`直下と見立てて設定ファイルをコピーします。コピーする内容はPinguyBuilderの場合と同じです。
