#!/usr/bin/perl

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
use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);
use NetAddr::IP;

my $s_err = "";
$SIG{__DIE__} = $SIG{__WARN__} = sub { $s_err = $_[0]; };

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数

# プログラム内部変数
my $action;

my $IFACE;
my $TARGET_ADDR;

my $LINK = "ether";
my $FAMILY = "inet";
my $ADDRESS = "local";
my $SCOPE = "global";
my $FLAG_OPT_COLORED = 0;
my $RETRY_NUM = "30";
my $RETRY_INTERVAL = "1";

my $rc;
my @IFACE_ADDR_GET_OPTIONS;
my $ADDR_DESC;
my @addr;
my $addr;
my $result;
my $count;

my $COLOR_NONE = "\e[00m";
my $COLOR_INFO = "\e[34;01m";	# light_blue
my $COLOR_ERR  = "\e[31;01m";	# light_red

######################################################################
# 関数定義
######################################################################
sub USAGE {
	print STDOUT <<EOF;
Usage:
  iface_addr.pl ACTION [OPTIONS ...] [ARGUMENTS ...]

ACTIONS:
    check [OPTIONS ...] IFACE TARGET_ADDR
       Check the address assigned to the interface.
    get   [OPTIONS ...] IFACE
       Get the address assigned to the interface.
    wait  [OPTIONS ...] IFACE
       Wait for the interface to be assigned an address.

ARGUMENTS:
    IFACE       : Specify the interface name.
    TARGET_ADDR : Specify the target address of the interface.

OPTIONS:
    -l LINK    : {ether|ppp}
       Default is $LINK.
       (Available with: check, get, wait)
    -f FAMILY  : {link|inet|inet6}
       Default is $FAMILY.
       (Available with: check, get, wait)
    -a ADDRESS : {local|broadcast|peer}
       Default is $ADDRESS.
       (Available with: check, get, wait)
    -s SCOPE   : {global|site|link|host}
       Default is $SCOPE.
       (Available with: check, get, wait)
    -C (colored)
       Colored output.
       (Available with: check, wait)
    -t RETRY_NUM
       Specify the number of retry times. Default is $RETRY_NUM.
       Specify 0 for infinite retrying.
       (Available with: wait)
    -T RETRY_INTERVAL
       Specify the interval seconds of retries. Default is $RETRY_INTERVAL.
       (Available with: wait)
    --help
       Display this help and exit.
EOF
}

use Common_pl::Is_numeric;
use Iface_tools::Iface_addr;

sub ECHO_INFO {
	my $msg = $_[0];

	if ( $FLAG_OPT_COLORED ) {
		print $COLOR_INFO, $msg, $COLOR_NONE;
	} else {
		print $msg;
	}
}

sub ECHO_ERR {
	my $msg = $_[0];

	if ( $FLAG_OPT_COLORED ) {
		print $COLOR_ERR, $msg, $COLOR_NONE;
	} else {
		print $msg;
	}
}

######################################################################
# メインルーチン
######################################################################

# ACTIONのチェック
if ( not defined($ARGV[0]) ) {
	print STDERR "-E Missing ACTION\n";
	USAGE();exit 1;
} else {
	if ( "$ARGV[0]" =~ m#^(?:check|get|wait)$# ) {
		$action = "$ARGV[0]";
	} else {
		print STDERR "-E Invalid ACTION -- \"$ARGV[0]\"\n";
		USAGE();exit 1;
	}
}

# ACTIONをシフト
shift @ARGV;

# オプションのチェック
if ( not eval { GetOptionsFromArray( \@ARGV,
	"l=s" => sub {
		$LINK = $_[1];
		if ( $LINK !~ m#^(?:ether|ppp)$# ) {
			print STDERR "-E Argument to \"-l\" is invalid -- \"$LINK\"\n";
			USAGE();exit 1;
		}
	},
	"f=s" => sub {
		$FAMILY = $_[1];
		if ( $FAMILY !~ m#^(?:link|inet|inet6)$# ) {
			print STDERR "-E Argument to \"-f\" is invalid -- \"$FAMILY\"\n";
			USAGE();exit 1;
		}
	},
	"a=s" => sub {
		$ADDRESS = $_[1];
		if ( $ADDRESS !~ m#^(?:local|broadcast|peer)$# ) {
			print STDERR "-E Argument to \"-a\" is invalid -- \"$ADDRESS\"\n";
			USAGE();exit 1;
		}
	},
	"s=s" => sub {
		$SCOPE = $_[1];
		if ( $SCOPE !~ m#^(?:global|site|link|host)$# ) {
			print STDERR "-E Argument to \"-s\" is invalid -- \"$SCOPE\"\n";
			USAGE();exit 1;
		}
	},
	"C" => \$FLAG_OPT_COLORED,
	"t=s" => sub {
		# 指定された文字列が数値か否かのチェック
		$rc = IS_NUMERIC("$_[1]");
		if ( $rc != 0 ) {
			print STDERR "-E Argument to \"-$_[0]\" not numeric -- \"$_[1]\"\n";
			USAGE();exit 1;
		}
		if ( "-$_[0]" eq "-t" ) {
			$RETRY_NUM = "$_[1]";
		}
	},
	"T=s" => sub {
		# 指定された文字列が数値か否かのチェック
		$rc = IS_NUMERIC("$_[1]");
		if ( $rc != 0 ) {
			print STDERR "-E Argument to \"-$_[0]\" not numeric -- \"$_[1]\"\n";
			USAGE();exit 1;
		}
		if ( "-$_[0]" eq "-T" ) {
			$RETRY_INTERVAL = "$_[1]";
		}
	},
	"help" => sub {
		USAGE();exit 0;
	},
) } ) {
	print STDERR "-E $s_err\n";
	USAGE();exit 1;
}

# 引数のチェック
if ( $action =~ m#^(?:check)$# ) {
	# 第1引数のチェック
	if ( not defined($ARGV[0]) ) {
		print STDERR "-E Missing IFACE argument\n";
		USAGE();exit 1;
	} else {
		$IFACE = "$ARGV[0]";
	}
	# 第2引数のチェック
	if ( not defined($ARGV[1]) ) {
		print STDERR "-E Missing TARGET_ADDR argument\n";
		USAGE();exit 1;
	} else {
		$TARGET_ADDR = "$ARGV[1]";
	}
} elsif ( $action =~ m#^(?:get|wait)$# ) {
	# 第1引数のチェック
	if ( not defined($ARGV[0]) ) {
		print STDERR "-E Missing IFACE argument\n";
		USAGE();exit 1;
	} else {
		$IFACE = "$ARGV[0]";
	}
}

# 変数定義(引数のチェック後)
@IFACE_ADDR_GET_OPTIONS = ("-l", "$LINK", "-f", "$FAMILY", "-a", "$ADDRESS", "-s", "$SCOPE");
if ( $LINK eq "ether" ) {
	$ADDR_DESC = "Ether";
} elsif ( $LINK eq "ppp" ) {
	$ADDR_DESC = "PPP";
}
if ( $FAMILY eq "link" ) {
	$ADDR_DESC .= " MAC";
} elsif ( $FAMILY eq "inet" ) {
	$ADDR_DESC .= " IPv4";
} elsif ( $FAMILY eq "inet6" ) {
	$ADDR_DESC .= " IPv6";
}
if ( $ADDRESS =~ m#^(?:local|broadcast|peer)$# ) {
	$ADDR_DESC .= " $ADDRESS";
}

if ( $action eq "check" ) {
	# 処理開始メッセージの表示
	print " $ADDR_DESC address check ";

	# インターフェイスのアドレスの取得
	@addr = IFACE_ADDR_GET(@IFACE_ADDR_GET_OPTIONS, $IFACE);
	$result = 1;
	foreach $addr (@addr) {
		if ( $FAMILY eq "link" ) {
			$TARGET_ADDR =~ y#ABCDEF#abcdef#;
			if ( $addr eq $TARGET_ADDR ) {
				$result = 0;
			}
		} elsif ( $FAMILY eq "inet6" ) {
			if ( NetAddr::IP->new($addr) == NetAddr::IP->new($TARGET_ADDR) ) {
				$result = 0;
			}
		} else {
			if ( $addr eq $TARGET_ADDR ) {
				$result = 0;
			}
		}
	}
	if ( $result == 0 ) {
		ECHO_INFO "OK!\n";
		exit 0;
	} else {
		ECHO_ERR "NG! -- \"@addr\", \"$TARGET_ADDR\"\n";
		exit 1;
	}
} elsif ( $action eq "get" ) {
	# インターフェイスのアドレスの取得
	@addr = IFACE_ADDR_GET(@IFACE_ADDR_GET_OPTIONS, $IFACE);
	if ( scalar(@addr) > 0 ) {
		foreach $addr (@addr) {
			print "$addr\n";
		}
		exit 0;
	} else {
		exit 1;
	}
} elsif ( $action eq "wait" ) {
	# 処理開始メッセージの表示
	print " Connecting ";

	# アドレスの割り当て待ち
	$count = 1;
	while (1) {
		@addr = IFACE_ADDR_GET(@IFACE_ADDR_GET_OPTIONS, $IFACE);
		if ( scalar(@addr) > 0 ) {
			ECHO_INFO " OK!\n";
			exit 0;
		}
		$count = $count + 1;
		print ".";
		if ( ( $RETRY_NUM != 0 ) and ( $count > $RETRY_NUM ) ) {
			ECHO_ERR " NG! (timed out)\n";
			exit 1;
		}
		sleep $RETRY_INTERVAL;
	}
}

