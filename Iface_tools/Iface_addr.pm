# ==============================================================================
#   機能
#     インターフェイスのアドレス処理
#   構文
#     USAGE 参照
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
package Iface_tools::Iface_addr;

use strict;
use warnings;

#use vars qw($VERSION);
#$VERSION = 'X.XX';

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(IFACE_ADDR_GET);

use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);

use Common_pl::Cmd_v;

######################################################################
# 変数定義
######################################################################
my $iface;

my $LINK = "ether";
my $FAMILY = "inet";
my $ADDRESS = "local";
my $SCOPE = "global";
my $cmd_line;
my $rc;
my @result;
my $result;
my @addr;

######################################################################
# サブルーチン定義
######################################################################
sub USAGE {
	print STDOUT <<EOF;
Usage:
    use Iface_tools::Iface_addr;
    IFACE_ADDR_GET([OPTION, ...] "IFACE");

    IFACE  : Specify the interface name to check an address.

OPTIONS:
    -l LINK    : {ether|ppp}
    -f FAMILY  : {link|inet|inet6}
    -a ADDRESS : {local|broadcast|peer}
    -s SCOPE   : {global|site|link|host}
EOF
}

# インターフェイスのアドレスの取得
sub IFACE_ADDR_GET {
	# オプションのチェック
	if ( not eval { GetOptionsFromArray( \@_,
		"l=s" => sub {
			$LINK = $_[1];
			if ( $LINK !~ m#^(?:ether|ppp)$# ) {
				print STDERR "-E Argument to \"-l\" is invalid -- \"$LINK\"\n";
				die;
			}
		},
		"f=s" => sub {
			$FAMILY = $_[1];
			if ( $FAMILY !~ m#^(?:link|inet|inet6)$# ) {
				print STDERR "-E Argument to \"-f\" is invalid -- \"$FAMILY\"\n";
				die;
			}
		},
		"a=s" => sub {
			$ADDRESS = $_[1];
			if ( $ADDRESS !~ m#^(?:local|broadcast|peer)$# ) {
				print STDERR "-E Argument to \"-a\" is invalid -- \"$ADDRESS\"\n";
				die;
			}
		},
		"s=s" => sub {
			$SCOPE = $_[1];
			if ( $SCOPE !~ m#^(?:global|site|link|host)$# ) {
				print STDERR "-E Argument to \"-s\" is invalid -- \"$SCOPE\"\n";
				die;
			}
		},
	) } ) {
		if ( $@ ne "" ) {
			print STDERR "-E $@\n";
		}
		return ();
	}

	# 第1引数のチェック
	if ( not defined($_[0]) ) {
		print STDERR "-E Missing IFACE argument\n";
		return ();
	} else {
		$iface = $_[0];
	}

	# アドレスの取得
	$cmd_line = "LANG=C ip addr show dev $iface 2>/dev/null";
	if ( not defined(open(COM, '-|', $cmd_line)) ) {
		return ();
	}
	#binmode(COM);
	@result = ();
	while ($result = <COM>) {
		chomp $result;
		push @result, $result;
	}
	close(COM);
	@addr = ();
	foreach $result (@result) {
		if ( $LINK eq "ether" ) {
			if ( $FAMILY eq "link" ) {
				if ( $result =~ m#^ +$FAMILY/$LINK ([0-9a-f:]+) brd ([0-9a-f:]+)#i ) {
					if ( $ADDRESS eq "local" ) {
						push @addr, $1;
					} elsif ( $ADDRESS eq "broadcast" ) {
						push @addr, $2;
					}
				}
			} elsif ( $FAMILY eq "inet" ) {
				if ( $result =~ m#^ +$FAMILY ([0-9.]+)/[0-9]+ brd ([0-9.]+) scope $SCOPE#i ) {
					if ( $ADDRESS eq "local" ) {
						push @addr, $1;
					} elsif ( $ADDRESS eq "broadcast" ) {
						push @addr, $2;
					}
				}
			} elsif ( $FAMILY eq "inet6" ) {
				if ( $result =~ m#^ +$FAMILY ([0-9a-f:]+)/[0-9]+ scope $SCOPE#i ) {
					if ( $ADDRESS eq "local" ) {
						push @addr, $1;
					}
				}
			}
		} elsif ( $LINK eq "ppp" ) {
			if ( $FAMILY eq "link" ) {
			} elsif ( $FAMILY eq "inet" ) {
				if ( $result =~ m#^ +$FAMILY ([0-9.]+) peer ([0-9.]+)/[0-9]+ scope $SCOPE#i ) {
					if ( $ADDRESS eq "local" ) {
						push @addr, $1;
					} elsif ( $ADDRESS eq "peer" ) {
						push @addr, $2;
					}
				}
			} elsif ( $FAMILY eq "inet6" ) {
				#if ( $result =~ m##i ) {
				#}
			}
		}
	}
	return (@addr);
}

1;
