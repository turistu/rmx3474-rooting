use strict;
use MIME::Base64;
use Digest::MD5 qw(md5 md5_base64);
use Crypt::Rijndael;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Getopt::Std;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils;

my (%key, %opt);
getopts 'stk:', \%opt or die q{
usage:
  $0 -s
    server mode, would listen on port 7777 on all ipv4 interfaces
  $0 -k /path/to/unpacked_apk/assets/lk_unlock.crt [key value ...]
    client mode, possible options:
       udid [IMEI] chipId 0x[SERIALNO]
       cmd {apply-unlock|check-approve-result|...}
       url [...] model [...] otaVersion [...]
};

load_data();
if($opt{k}){
	$key{oppo_pubkey} = Crypt::OpenSSL::X509->new_from_file(
		$opt{k}, Crypt::OpenSSL::X509::FORMAT_ASN1)->pubkey;
}
if($opt{s}){
	server();
}elsif($opt{t}){
	request(url => 'https://localhost:7777/api/v2/', @ARGV);
}else{
	request(@ARGV);
}
#########################################################################

sub load_data {
	my $k;
	while(<DATA>){
		if(/^--*BEGIN ([^-]*)--*$/){
			$k //= $1 =~ y/A-Z /a-z_/r;
			$key{$k} = $_
		}elsif(/^>>+ (.*)/){
			$k = $1;
		}else{
			$key{$k} .= $_; undef $k if /^--*END/;
		}
	}
	#print PEM_cert2string(PEM_string2cert($key{certificate}));
}

sub ssl_connect {
	new IO::Socket::SSL(@_) // die "ssl_connect(@_): $!: $SSL_ERROR\n";
}
sub ssl_accept {
	use IO::Socket::SSL;
	my ($addr) = @_;
	my $srv = IO::Socket::SSL->new(
		LocalAddr => $addr,
		Listen => 10,
		SSL_cert => PEM_string2cert($key{certificate}),
		SSL_key => PEM_string2key($key{private_key}),
		ReuseAddr => 1,
	) // die "ssl_listen($addr): $SSL_ERROR\n";
	$SIG{CLD} = sub { wait };
	while(1){
		if(my $sock = $srv->accept) {
			defined(my $pid = fork) or die "fork: $!\n";
			return $sock if $pid == 0;
		}elsif(!$!{EINTR}) {
			die "accept: $!: $SSL_ERROR\n";
		}
	}
}

sub xcrypt {
	my ($k, $d) = @_;
	my $cy = new Crypt::Rijndael($k, Crypt::Rijndael::MODE_CTR());
	$cy->set_iv(md5($k));
	$cy->encrypt($d);
}
sub base64($) { encode_base64($_[0], '') }
sub unbase64($) { decode_base64($_[0]) }

sub mk_key_header {
	my ($ek, $pk) = @_;
	my $k = Crypt::OpenSSL::RSA->new_public_key($pk);
	$k->use_pkcs1_padding;
	base64($k->encrypt(base64($ek)));
}
sub mk_json {
	use List::Util qw(pairmap);
	return mk_json([@_]) if @_ > 1;
	my $d = shift; my $r = ref $d;
	$r eq 'ARRAY' ? '{'.join(',', pairmap {qq{"$a":}.mk_json($b)} @$d).'}' :
	$r eq 'SCALAR' ? $$d : qq{"$d"}
}
sub mk_data {
	my ($k, $t, @d) = @_;
	mk_json $t, base64 xcrypt $k, mk_json @d;
}
sub decrypt_data {
	my ($k, $d) = @_;
	$d = $1 if $d =~ /^\s*\{\s*"(?:resps|params)"\s*:\s*"(.*)"\s*\}\s*$/;
	$d =~ s/\\u([0-9a-f]{4})/chr hex $1/ge;
	xcrypt($k, unbase64($d));
}
sub request {
	my %cfg = (
		model => 'bananaphone',
		otaVersion => 'BAN1334_EX_13.Z.27_2107022913131313',
		chipId => '0xdeadbeef', # 0x + serialno
		udid => '123456789',	# imei
		clientLockStatus => \0,
		operator => '',
		token => '123456789',

		url => 'https://ilk.apps.coloros.com/api/v2/',
		cmd => 'get-all-status',
		@_
	);
	my ($host, $path) = $cfg{url} =~ m{^https?://([^/]+)(.*)};
	my $port = $host =~ s{:(\d+)$}{} ? $1 : 443;
	my @ssl = (PeerHost => $host, PeerPort => $port);
	my $pubkey;
	if($host eq 'localhost'){
		push @ssl,
			SSL_ca => [PEM_string2cert($key{certificate})],
			SSL_hostname => 'deeper';
		$pubkey = $key{public_key};
	}else{
		$pubkey = $key{oppo_pubkey};
	}
	# Crypt::OpenSSL::RSA->new_public_key($pubkey);
	my $ek = 'x' x 32;	# yes, this is supposed to be random
	my $data = mk_data $ek, 'params', map {$_, $cfg{$_}} qw(
		chipId udid model otaVersion token clientLockStatus operator
	);
	my $key_header = mk_key_header($ek, $pubkey);
	my $sock = ssl_connect @ssl;
	syswrite $sock, join "\r\n",
		"POST $path$cfg{cmd} HTTP/1.1",
		map("$_: $cfg{$_}", qw(model otaVersion)),
		"language: en-US",
		"key: $key_header",
		"Content-Type: application/json; charset=utf-8",
		"Content-Length: ".length($data),
		"Host: $host",
		"Connection: Keep-Alive",
		"Accept-Encoding: gzip",
		"User-Agent: okhttp/3.12.2",
		"", $data;
	local $/ = "\r\n\r\n";
	my $reply = <$sock>;
	warn $reply;
	if(my ($l) = $reply =~ /^Content-Length: *(\d+)/im){
		read $sock, $data, $l or die "read: $!";
		print map "$_\n", $data, decrypt_data($ek, $data);
	}else{
		undef $/;
		print <$sock>;
	}
}
sub reply {
	my ($sock, $ek, @reply) = @_;
	my $data = mk_data($ek, "resps", [code => \200, message => 'SUCCESS',
		@reply ? (data => [@reply]) : ()]);
	warn ">>> ", decrypt_data($ek, $data), "\n";
	syswrite $sock, join "\r\n",
		"HTTP/1.1 200 OK",
		"Content-Type: application/json; charset=utf-8",
		"Content-Length: ".length($data),
		"", $data;
}
sub server {
	my $sock = ssl_accept('0.0.0.0:7777');
	my $priv_key = Crypt::OpenSSL::RSA->new_private_key($key{private_key});
	$priv_key->use_pkcs1_padding;
	while(1){
		$/ = "\r\n\r\n";
		last unless defined($_ = <$sock>);
		my (%h, $data, $req);
		for(split /\r\n/, $_){
			if(/^(\w[\w-]*): *(.*)/){ $h{$1 =~ y/A-Z-/a-z_/r} = $2 }
			elsif(/^POST +(\S+)/){ $req = $1 }
		}
		if(my $l = $h{content_length}){
			read $sock, $data, $l or die "read: $!";
		}
		warn "\n##### $req\n";
		my $ek = unbase64 $priv_key->decrypt(unbase64 $h{key});
		warn "<<< ", decrypt_data($ek, $data), "\n";
		if($req =~ m{/check-approve-result$}){
			reply($sock, $ek, unlockCode => "12345");
		}else{
			reply($sock, $ek, applyStatus => \0, clientStatus => \0);
		}
	}
}


__DATA__

1000	apply-unlock
1001	check-approve-result 
1002	update-client-lock-status
1003	get-all-status
1004	lock-client

-1007	会员登录状态查询返回错误
	The member login status query returns an error

-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC2IRkAneQqcCmN
eJ3hMU3/w70vcWAXNS+gerECFho+raXlnD2JManYcpuZFRMgom1tNiLsZ1GwyqiA
ypuzkHfkwCNKblyvtA0jNoFyb+3HDb9+m5v2xgB+Qf1bddK+GtmRgco59KoBs78J
lKEXmKCVBMZ3193iRdd1C1QTkrRJoZrjmEzmBydGQ6IwIFBTYYRlqknNhWojRRvl
Nf4EfYKKjObcEeCpCFrd9cA4T4s0Dak9oraXyah2AQzm+JqIKziGzHc08pnyW9ex
74dMx5UYGeKF9KWQF//UX4IC1hR+AAtSWbP81nX2iNRr4zFno0dKL51+Bx+AaVRP
tYgXR8obAgMBAAECggEAV8Aqo7lvLWNNIfRzXQS8Z/aPOESP356oi9GRZ0fu7TQN
MkvM+kULaFYP0fntdVPNFUl4Gh7NpTh/Z043JpT8ryJD3qC914oQql6gj9qN3dIp
6X5f7s4Hfs2cnGxwVVfqa8j0/md7YcaQzLTnyM6o0CO03BkNtu+fl60VnTiZ1L9Q
Bv+JugToeDHEnGsECaIK3ArtvJ8c3GQhEZHSsPkXaUwl66WfNyQECB7O+GbT3hJl
64fC7HquAU9YNuWzt8oBF4HvaUtRaj323Qdat9YJPAjYeTovefk4GJVKQC3mETVN
Nt0D5L8ScBz4pOm8U9RHPyqPDrCCQnaJ11FEyb/hgQKBgQDfeaDn+QPlHfIAZRFY
P7MMVphKVLuDcVN7vDgE5vDdqi8kNvsn2HMOA4Jgd3gSGWyH4Gdh3Wv1zm9wDPou
YNau0A1GwpmMISrYKvgjYUNoshXar+CA4HYtsLhZ2FpU/rEihfT9q7e05UD2jONV
MabMslvi8gPekJ4UfyzOc7CCQwKBgQDQovs3DsAsc/3cDTfTpy/07cAhhtLnkyCr
VaghLQUmUP+Gps+tfZoS9xhy1A7UD+B3MKCWyQstNNqhy4wN3lEoejVfLyGkYCWC
UwdIbRln/MwFOZ3E633fOevBUcl2u3huomlLeqvD3PGplEMb/MZ9rauHwHzK3lcd
t0dQSGz3SQKBgGugfVEbSbfvyxxLkKXqz8WScvfhhQmR67388RHTU4++JcQQQrd2
9Dp8kC77erVkzzNFbSTh6dvRVzQk29y4QMyiYLKCiEbHtoWzdBw9/KQQmJvg9oO7
Fs98e9yxaRfkLdVNpKcDK4+Qlc/oHJhsOEP/ZmePXTO0fJ2sfhzT9N9XAoGAFc3C
lTlsafjhQdr7x5nEUEN8fcR6TAs7Mcys2nK7BAsY+Th7obTroinCm1WACzdxjOM/
FSMDkQDiDGCaTWS7dJB4/W6OhIAry1fj/fSw4AYySCWCUG8P44FJGxXyCP+EkYNV
n7a9NqXjd4ZwEP+0urOopnI+WHEuB4P85u36vUkCgYB725nwd8zRhWcBsIm5ZAMr
DMUSIpaoXdx4PrBcf3VvSsiLDVb7ozJDDeIczOzu6s2LU5rdKdCv4/NET0oDoMDG
bfZrEaezvsiqpHBC1bxTrHcagU9M0AqcN5HLTCKm9yAWyCfJSHNPTMSUe5H/5Y/q
Ian03PEny0/xf3Xldp6OzA==
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE REQUEST-----
MIICVjCCAT4CAQAwETEPMA0GA1UEAwwGZGVlcGVyMIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAtiEZAJ3kKnApjXid4TFN/8O9L3FgFzUvoHqxAhYaPq2l
5Zw9iTGp2HKbmRUTIKJtbTYi7GdRsMqogMqbs5B35MAjSm5cr7QNIzaBcm/txw2/
fpub9sYAfkH9W3XSvhrZkYHKOfSqAbO/CZShF5iglQTGd9fd4kXXdQtUE5K0SaGa
45hM5gcnRkOiMCBQU2GEZapJzYVqI0Ub5TX+BH2Ciozm3BHgqQha3fXAOE+LNA2p
PaK2l8modgEM5viaiCs4hsx3NPKZ8lvXse+HTMeVGBnihfSlkBf/1F+CAtYUfgAL
Ulmz/NZ19ojUa+MxZ6NHSi+dfgcfgGlUT7WIF0fKGwIDAQABoAAwDQYJKoZIhvcN
AQELBQADggEBADwW/Hu07hBvz7E2UMz1v4uTkEM/I70T/rr9A/0T6hpOuxTqxJr0
7mNsGRT5EMjPSbtz+1iL5Eyj3abVpKjERENVCWxw6HoqgMUEV9MysSsiyQk5n8yO
Bm1/mxmuQDGa49paz1kU1jTOUujgi8RcZTSvNtzFsbpFhcg0vxHxeXIY/jPedFGE
ALAGr5UO6TAp1rB7HdEcbCKMbeKbHbFzkHRLmLwRDIyX42xlw0JhlDKopagzRL7S
QqIFerqhKQ13t0L391+V8w2B4Xe/DqWJ75HcqCjyHIZhgacQh2Wac74JRCT4Gm5s
+gpK1FOrER/TxHsLt2hnxOs6sEye3Ebka3k=
-----END CERTIFICATE REQUEST-----
-----BEGIN CERTIFICATE-----
MIICqTCCAZECFF1QO2BP6wBCb0xQWzfktYWytpnXMA0GCSqGSIb3DQEBCwUAMBEx
DzANBgNVBAMMBmRlZXBlcjAeFw0yMzA0MjYxMjUxNDRaFw0yNDA0MjUxMjUxNDRa
MBExDzANBgNVBAMMBmRlZXBlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
ggEBALYhGQCd5CpwKY14neExTf/DvS9xYBc1L6B6sQIWGj6tpeWcPYkxqdhym5kV
EyCibW02IuxnUbDKqIDKm7OQd+TAI0puXK+0DSM2gXJv7ccNv36bm/bGAH5B/Vt1
0r4a2ZGByjn0qgGzvwmUoReYoJUExnfX3eJF13ULVBOStEmhmuOYTOYHJ0ZDojAg
UFNhhGWqSc2FaiNFG+U1/gR9goqM5twR4KkIWt31wDhPizQNqT2itpfJqHYBDOb4
mogrOIbMdzTymfJb17Hvh0zHlRgZ4oX0pZAX/9RfggLWFH4AC1JZs/zWdfaI1Gvj
MWejR0ovnX4HH4BpVE+1iBdHyhsCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAX474
x37qshEWK2fR19nQxkY5cjSWCDgm4qwWqasQKX31Jh+3uqw+9Dx60QtVsWZZEl67
b5+iv8Ww/qBg9wfQ/hnGhr/7EM7HE6OWDMLt4i1ZzQJOPIuHcLWhV3UvTzaUg/Yt
wbI1x3dh3PLEuBLiHcExWjZypDxH2DIRhTTqhbJ0z9FSWk2ljlpMWETdI7UoHu09
pC3Gy2wcZH4Up1PniJiTgr3ExN72eY/qdDnMVpFrJOLvA4VoJ+tDUt6Q9Ru80lSg
Vz+1Kuk2k9iKjn78nYjMz6fL3C82xsXxD9r5GX1l3xyA2HO52d+88ECIl2P9SmBv
sPAQaQWNv1UMFRagMw==
-----END CERTIFICATE-----
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtiEZAJ3kKnApjXid4TFN
/8O9L3FgFzUvoHqxAhYaPq2l5Zw9iTGp2HKbmRUTIKJtbTYi7GdRsMqogMqbs5B3
5MAjSm5cr7QNIzaBcm/txw2/fpub9sYAfkH9W3XSvhrZkYHKOfSqAbO/CZShF5ig
lQTGd9fd4kXXdQtUE5K0SaGa45hM5gcnRkOiMCBQU2GEZapJzYVqI0Ub5TX+BH2C
iozm3BHgqQha3fXAOE+LNA2pPaK2l8modgEM5viaiCs4hsx3NPKZ8lvXse+HTMeV
GBnihfSlkBf/1F+CAtYUfgALUlmz/NZ19ojUa+MxZ6NHSi+dfgcfgGlUT7WIF0fK
GwIDAQAB
-----END PUBLIC KEY-----
