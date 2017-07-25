# iface_tools_pl

## 概要

ネットワークインターフェイス関連ツール (Perl)

## 使用方法

### iface_addr.pl

    各種インターフェイスに割り当てられたMAC/IPv4/IPv6アドレスをチェックします。
    # iface_addr.pl check -l インターフェイス種別 -f link  インターフェイス名 MACアドレス
    # iface_addr.pl check -l インターフェイス種別 -f inet  インターフェイス名 IPv4アドレス
    # iface_addr.pl check -l インターフェイス種別 -f inet6 インターフェイス名 IPv6アドレス

    各種インターフェイスに割り当てられたMAC/IPv4/IPv6アドレスを取得します。
    # iface_addr.pl get   -l インターフェイス種別 -f link  インターフェイス名
    # iface_addr.pl get   -l インターフェイス種別 -f inet  インターフェイス名
    # iface_addr.pl get   -l インターフェイス種別 -f inet6 インターフェイス名

    各種インターフェイスにMAC/IPv4/IPv6アドレスが割り当てられるまで待機します。
    # iface_addr.pl wait  -l インターフェイス種別 -f link  インターフェイス名
    # iface_addr.pl wait  -l インターフェイス種別 -f inet  インターフェイス名
    # iface_addr.pl wait  -l インターフェイス種別 -f inet6 インターフェイス名

### iface_status.pl

    リモートホストのIPv4/IPv6アドレスが有効になるまで待機します。
    # iface_status.pl wait -f inet  リモートホスト名 up
    # iface_status.pl wait -f inet6 リモートホスト名 up

    リモートホストのIPv4/IPv6アドレスが無効になるまで待機します。
    # iface_status.pl wait -f inet  リモートホスト名 down
    # iface_status.pl wait -f inet6 リモートホスト名 down

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux (Debian, Fedora)

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* perl
* [NetAddr-IP](http://search.cpan.org/dist/NetAddr-IP/)
* [common_pl](https://github.com/yuksiy/common_pl)

## インストール

ソースからインストールする場合:

    (Debian の場合)
    # make install

    (Fedora の場合)
    # make ENVTYPE=fedora install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/iface_tools_pl>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/iface_tools_pl/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2011-2017 Yukio Shiiya
