#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Getopt::Long qw(:config gnu_getopt auto_help auto_version);
use Pod::Usage;
use Net::IP;

our $VERION = '0.9.0';
my @ipv4;
my @ipv6;
my %revdomains;
my @input;
my @script;

my $man;
my $verbose = 0;
my $ttl = '3600';
my $host;
my $domain;
my $ipinfo;
my $net;
my $output;
my $doadd = 1;
my $dopurge = 1;
my $doforward = 1;
my $doreverse = 1;
my $doipv4 = 1;
my $doipv6 = 1;

my %opts = (
	'add|a!' => \$doadd,
	'domain|d=s' => \$domain,
	'forward|f!' => \$doforward,
	'host|h=s' => \$host,
	'ipinfo|i=s' => \$ipinfo,
	'ipv4|4!' => \$doipv4,
	'ipv6|6!' => \$doipv6,
	'man|m' => \$man,
	'net|n=s' => \$net,
	'output|o=s' => \$output,
	'purge|p!' => \$dopurge,
	'reverse|r!' => \$doreverse,
	'ttl|t=i' => \$ttl,
	'verbose|v' => \$verbose,
);
GetOptions(%opts);

pod2usage(-exitval => 0, -verbose => 2) if $man;
if (!$host) {
	$host = `hostname -s`;
	chomp $host;
}		
if (!$domain) {
	$domain = `hostname -d`;
	chomp $domain;
}

if ($ipinfo) {
	open(IFH, '<', $ipinfo) or die("Can't open ipinfo: $ipinfo");
	@input = <IFH>;
	close(IFH);
} else {
	if (!$net) {
		$net = 'eth0';
	}
	@input = `ip addr show $net`;
}

sub addrev($$$) {
	my ($addr, $expaddr, $zoneoffset) = @_;
	  
	my $rev = Net::IP::ip_reverse($expaddr);
	my @revarray = split(/\./, $rev);
	my $revdom = join('.', @revarray[$zoneoffset..$#revarray]);

	if (!exists($revdomains{$revdom})) {
		$revdomains{$revdom} = [];
	}
	
	push @{$revdomains{$revdom}}, $rev;
}
my $addr;
my $subnet;

foreach (@input) {
	if (m/^\s+inet\s+(\d{1,3}(\.\d{1,3}){3})\/(\d+).*scope global.*$/) {
		if ($doipv4) {
			$addr = $1;
			$subnet = $3;
			push @ipv4, $addr;
			addrev($addr, Net::IP::ip_expand_address($addr, 4), 4-int($subnet/8));
		}
	} elsif (m/\s+inet6\s+([[:xdigit:]:]+)\/(\d+).*scope global.*$/) {
		if ($doipv6) {
			$addr = $1;
			$subnet = $2;
			push @ipv6, $addr;
			addrev($addr, Net::IP::ip_expand_address($addr, 6), 32-int($subnet/4));
		}
	}
}
push @script, "zone $domain.";
push @script, "ttl $ttl";
if ($doforward) {
	if ($dopurge) {
		push @script, "update delete $host.$domain. A" if ($doipv4);
		push @script, "update delete $host.$domain. AAAA" if ($doipv6);
	}

	if ($doadd) {		foreach $addr (@ipv4) {
			push @script, "update add $host.$domain. A $addr";
		}		foreach $addr (@ipv6) {
			push @script, "update add $host.$domain. AAAA $addr";
		}
	}

	push @script, "send";
	push @script, "answer" if $verbose;
}

if ($doreverse) {
	foreach my $key (keys(%revdomains)) {
		push @script, "zone $key.";
		foreach $addr (@{$revdomains{$key}}) {
			push @script, "update delete $addr PTR" if ($dopurge);
			push @script, "update add $addr PTR $host.$domain." if ($doadd);
		}
		push @script, "send";
		push @script, "answer" if $verbose;
	}
}

my $outscript = join("\n", @script)."\n";

if ($output) {
	open(OFH, '>', $output) or die("Can't open output: $output");
	print OFH $outscript;
	close(OFH);
} else {
	print $outscript;
}

__END__

=head1 NAME

gennsupd - Generate nsupdate script

=head1 SYNOPSIS

gennsupd [options]

Options:

	-?	--help       	brief help message
	-m	--man           full documentation
	-a	--(no)add	(don't) generate add statements
	-d	--domain=s	domain name (default hostname -d)
	-f	--(no)forward	(don't) generate forward DNS entries	
	-h	--host=s	host name (default hostname -s)
	-i	--ipinfo=s	file containing output from 'ip addr show' (testing)
	-4	--(no)ipv4	(don't) generate IPv4 statements
	-6	--(no)ipv6	(don't) generate IPv6 statements
	-n	--net=s		network interface (default eth0) (not used if --ipinfo specified)
	-o	--output=s	write script to named file (default stdout)
	-p	--(no)purge	(don't) generate delete statements
	-r	--(no)reverse	(don't) generate reverse DNS entries
	-t	--ttl=n		time to live in seconds (default 3600)
	-v	--verbose	print verbose diagnostics

In most cases no options are required.

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.


=item B<--man>

Prints the manual page and exits.


=item B<--(no)add>

Generates add statements, since this is the default it is only useful when prefixed with no (eg --noadd).


=item B<--domain=s>

Specify the domain name in which the host resides.  If not specified then the result from executing hostname 
with the -d option is used.


=item B<--(no)forward>

Generate forward DNS entries, since this is the default it is only useful when prefixed with no (eg --noforward).


=item B<--host=s>

Specify the name of the host used in the DNS entries.  If not specified then the result from executing hostname 
with the -s option is used.


=item B<--ipinfo=s>

This is primarily used for testing. The argument is a file containing output from 'ip addr show'.


=item B<--(no)ipv4>

Generate IPv4 statements, since this is the default it is only useful when prefixed with no (eg --noipv4).


=item B<--(no)ipv6>

Generate IPv6 statements, since this is the default it is only useful when prefixed with no (eg --noipv6).


=item B<--net=s>

The network interface given as an argument to ip addr show.  It defaults to eth0. It is not used if the 
--ipinfo option is specified).


=item B<--output=s>

Write the output script to git given file.  The default is to use stdout.


=item B<--(no)purge>

Generates delete statements, since this is the default it is only useful when prefixed with no (eg --nopurge).


=item B<--(no)reverse>

Generate reverse DNS entries, since this is the default it is only useful when prefixed with no (eg --noreverse).


=item B<--ttl=n>

The TimeToLive for added DNS entries in seconds. The default is 3600 or one hour.

=item B<--verbose>

Display additional information. Currently it causes the server responses to be printed.

=back

=head1 DESCRIPTION

B<This program> generates a script for nsupdate that removes existing DNS entries 
and adds new ones for the specified host in the given domain.  It also removes and
adds the reverse DNS entries.  Both IPv4 and IPv6 are supported.

Options are available to override the automatically determined data and control the
operations performed.

=cut
