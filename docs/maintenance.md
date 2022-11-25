# メンテナンスについて
AlexandriteOSのメンテナンス作業はアップストリームの更新の適用は主です。

## 手順1

### 補助スクリプトを使った更新の適用
`targets/alexandrite-workstation/copilot`ディレクトリ内に複数のディレクトリがあります。各ディレクトリ内のスクリプトのコメントを参考にして最新版のURLを設定してください。<br>
後は`./copilot.sh alexandrite-workstation`を実行すると自動的にリモートでの反映が適用されます。

### 手動での更新の適用
一部のGnome拡張機能は自動更新できません<br>
`targets/alexandrite-workstation/overlay/alexandrite-shell/root/usr/share/gnome-shell/extensions/`にgnomeの拡張機能が格納されています。

#### Hide_Activities@shay.shayel.org と syspeek-gs@gs.eros2.info のアップデート
`metadata.json`というファイルの`shell-version`に最新のGnomeのバージョンを足してください。例えばgnome43に対応する場合こうなります。
この２つは単純な拡張機能なので上流からの更新を適用しなくても大抵の場合動きます。
```
  "shell-version": [
    "3.10",
    "3.12",
    "3.14",
    "3.16",
    "3.18",
    "3.20",
    "3.22",
    "3.24",
    "3.26",
    "3.28",
    "3.30",
    "3.34",
    "3.32",
    "3.36",
    "3.38",
    "40",
    "41",
    "42", ←ここにカンマを足して
    "43" ←ここに新しいバージョンを書く
  ],

```

## 手順2
本番環境にデプロイします。build.shに`--release`オプションを付けるとデプロイされます。資格情報がと追加のセットアップが必要なので中の人に連絡してください。

