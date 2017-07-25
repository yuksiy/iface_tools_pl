#!/usr/bin/perl

# ==============================================================================
#   機能
#     リモートインターフェイスの状態処理
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

my $s_err = "";
$SIG{__DIE__} = $SIG{__WARN__} = sub { $s_err = $_[0]; };

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数

# プログラム内部変数
my $action;

my $HOST_ADDR;
my $STATUS;

my $FAMILY = "inet";
my $FLAG_OPT_COLORED = 0;
my $RETRY_NUM = "30";
my $RETRY_INTERVAL = "1";

my $rc;
my $ADDR_DESC;
my $cmd_line;
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
  iface_status.pl ACTION [OPTIONS ...] [ARGUMENTS ...]

ACTIONS:
    wait [OPTIONS ...] HOST_ADDR STATUS
       Wait for the host to be STATUS.

ARGUMENTS:
    HOST_ADDR : Specify the host address.
    STATUS    : Specify {up|down}.

OPTIONS:
    -f FAMILY  : {inet|inet6}
       Default is $FAMILY.
       (Available with: wait)
    -C (colored)
       Colored output.
       (Available with: wait)
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

use Common_pl::Cmd_v;
use Common_pl::Is_numeric;

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
	if ( "$ARGV[0]" =~ m#^(?:wait)$# ) {
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
	"f=s" => sub {
		$FAMILY = $_[1];
		if ( $FAMILY !~ m#^(?:inet|inet6)$# ) {
			print STDERR "-E Argument to \"-f\" is invalid -- \"$FAMILY\"\n";
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
if ( $action =~ m#^(?:wait)$# ) {
	# 第1引数のチェック
	if ( not defined($ARGV[0]) ) {
		print STDERR "-E Missing HOST_ADDR argument\n";
		USAGE();exit 1;
	} else {
		$HOST_ADDR = "$ARGV[0]";
	}
	# 第2引数のチェック
	if ( not defined($ARGV[1]) ) {
		print STDERR "-E Missing STATUS argument\n";
		USAGE();exit 1;
	} else {
		$STATUS = "$ARGV[1]";
	}
	if ( $STATUS !~ m#^(?:up|down)$# ) {
		print STDERR "-E Invalid STATUS -- \"$STATUS\"\n";
		USAGE();exit 1;
	}
}

# 変数定義(引数のチェック後)
if ( $FAMILY eq "inet" ) {
	$ADDR_DESC .= "IPv4";
} elsif ( $FAMILY eq "inet6" ) {
	$ADDR_DESC .= "IPv6";
}

if ( $action eq "wait" ) {
	# 処理開始メッセージの表示
	print " Waiting for $HOST_ADDR ($ADDR_DESC) to be $STATUS ";

	# リモートインターフェイスの状態待ち
	if ( $FAMILY eq "inet" ) {
		$cmd_line = "ping  -c 1 -w 1 $HOST_ADDR >/dev/null 2>&1";
	} elsif ( $FAMILY eq "inet6" ) {
		$cmd_line = "ping6 -c 1 -w 1 $HOST_ADDR >/dev/null 2>&1";
	}
	$count = 1;
	while (1) {
		$rc = SYS "$cmd_line";
		if ( $STATUS eq "up" ) {
			if ( $rc == 0 ) {
				ECHO_INFO " OK!\n";
				exit 0;
			}
		} elsif ( $STATUS eq "down" ) {
			if ( $rc != 0 ) {
				ECHO_INFO " OK!\n";
				exit 0;
			}
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

