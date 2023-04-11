#! /usr/bin/perl

use strict;

my %cfg = (
	cmd => 'acquireClientStatus',
	url => 'https://lkf.realmemobile.com/realme/v1/',
		# lkf. if oppo.version.exp feature, lk. otherwise

	# these are used to build the json POST data

	model => 'RMX3461',
		# ro.product.name [RMX3474EEA]
	pcb => '',
		# the serial number with 0x prepended [0x????????]
		# ro.vold.serialno
		# /proc/oppoVersion/serialID
		# /proc/oplusVersion/serialID **
	imei => '00',
		# the first IMEI
	otaVersion => 'RMX3461_EX_11.C.03_2022082721280117',
		# ro.build.version.ota [RMX3474_11.?.??_????_202?????????]
	clientStatus => 'i:0',
	adbDvice => '',
		# ro.oppo.operator []

	# these are used to build the O_NETON: ... HTTP header

	client_id => '000000000000000',
	sso_id => 0,
	rpmodel => 'RMX3461',		# ro.product.model [RMX3474]
	os_version => 'V1.0.0',		# ro.build_bak.version.opporom
	rom_version => '',		# ro.build_bak.display.id
	android_version => 31,		# Build.VERSION_SDK_INT [31]
	key_version => '1.0.3',
	network_type => 'WIFI',
	version_name => '1.0.1',
);

my $verbose;
my @cmds = qw(applyLkUnlock checkApproveResult updateLockStatus
		acquireClientStatus closeApply acquireApplyStatus);

#############################################################################

use Crypt::Rijndael;
use MIME::Base64;

sub pkcs5_pad {
	my ($s) = @_;
	my $p = 16 - length($s) % 16;
	$s . chr($p) x $p;
}
sub pkcs5_unpad {
	my ($s) = @_;
	my $l = ord substr $s, -1, 1;
	substr $s, 0, -$l;
}
sub encrypt {
	my ($d, $k) = @_; Crypt::Rijndael->new($k)->encrypt(pkcs5_pad($d));
}
sub decrypt {
	my ($d, $k) = @_; pkcs5_unpad(Crypt::Rijndael->new($k)->decrypt($d));
}

sub mk_neton_header {
	my $cfg = join ';', @cfg{qw(client_id sso_id rpmodel os_version rom_version android_version key_version network_type version_name)};
	unpack 'H*', encrypt($cfg, 'netton.client.st');
}

sub params_key {
	my ($random) = @_;
	my @junk = ("oppo1997", "baed2017", "java7865", "231uiedn",
		"09e32ji6", "0oiu3jdy", "0pej387l", "2dkliuyt",
		"20odiuye", "87j3id7w");
	# NB: it's not only us: their server-side code will also
	# treat any non-digit byte at the start of $random as '0' ;-)
	$junk[substr $random, 0, 1].substr($random, 4, 8);
}
sub mk_data {
	my ($data, $random) = @_;
	unless($random){
		my $r = '@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789!#$%&()';
		$random = join '', int(rand(10)), map substr($r, rand() * length($r), 1), 0..13;
	}
	my $key = params_key($random);
	encode_base64(encrypt($data, $key), '').$random;
}
sub mk_params {
	my $cfg = '{'.(join ',', map {
			my $v = $cfg{$_};
			$v =~ s/^i:// ? qq<"$_":$v> : qq<"$_":"$v">
		}
		qw(pcb imei model otaVersion clientStatus adbDvice)).'}';
	mk_data($cfg, @_);
}
sub decrypt_data {
	my ($d) = @_;
	$d =~ s/^\s+|\s+$//g;
	$d = $1 if $d =~ /^\{\s*"(?:resps|params)"\s*:\s*"(.*)"\s*\}$/;
	$d =~ s/\\u([0-9a-f]{4})/chr hex $1/ge;
	my $r = substr $d, -15, 16, '';
	decrypt(decode_base64($d), params_key($r));
}
sub mk_postdata {
	my $e = mk_params(@_);
	$e =~ s/=/\\u003d/g;
	qq<{"params":"$e"}>
}
sub query {
	my %a = @_; $cfg{$_} = $a{$_} for keys %a;
	require LWP::UserAgent;
	my $ua = new LWP::UserAgent;
	$ua->send_te(undef);
	$ua->default_headers(HTTP::Headers->new(
		encypt => 1, # sic, without the 'r'
		O_NETON => mk_neton_header(),
		'Accept-Encoding' => 'gzip',
		'User-Agent' => 'okhttp/3.8.1',
		'Keep-Alive' => undef,
	));
	my $c = mk_postdata;
	$c =~ /:"(.*)"/;
	warn "params\t", decrypt_data($1), "\n" if $verbose;
	die "unknown cmd '$cfg{cmd}'; it should be one of:\n  @cmds\n"
		unless grep $cfg{cmd} eq $_, @cmds;
	my $rsp = $ua->post("$cfg{url}$cfg{cmd}",
		'Content-Type' => 'application/json; charset=utf-8',
		Content => $c);
	die "post($cfg{url}$cfg{cmd}): ", $rsp->status_line, "\n"
		unless $rsp->is_success;
	my $d = $rsp->decoded_content;
	warn "response\t$d\n" if $verbose;
	if($d =~ /^\s*\{\s*"resps"\s*:\s*"(.*)"\s*\}$/){
		$d = decrypt_data($1);
		# warn "\n$d\n" if $verbose;
		print "$d\n";
	}else{
		die "unexpected response from $cfg{url}$cfg{cmd}\n$d\n";
	}
}
sub response {
	if($_[0] =~ /^\s*\{/){
		my $r = mk_data($_[0]); return qq<{"resps":"$r"}>;
	}
	my (%opt) = @_;
	my $code = delete($opt{resultCode}) // 0;
	my $msg = delete($opt{msg}) // "whatever";
	my $data = '';
	if(keys %opt){
		$data = ',"data":{'.(join ',', map {
			my $v = $opt{$_};
			$v =~ /^[01]$/ ? qq<"$_":$v> : qq<"$_":"$v">
		} keys %opt).'}';
	}
	my $r = mk_data(qq<{"resultCode":$code,"msg":"$msg"$data}>);
	qq<{"resps":"$r"}>;
}

$verbose = 1, shift if $ARGV[0] eq '-v';
if($ARGV[0] eq '-r'){
	shift;
	my $r = response(@ARGV);
	print $r;
	flush STDOUT;
	print STDERR "\n", decrypt_data($r), "\n";
}elsif($ARGV[0] eq '-d'){
	for(@ARGV){
		if(m/[^0-9A-Fa-f]/){
			print decrypt_data($_), "\n";
		}else{
			print decrypt(pack('H*', $_), 'netton.client.st');
		}
	}
}else{
	query(@ARGV);
}
