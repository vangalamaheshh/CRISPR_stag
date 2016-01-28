#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use IO::Compress::Gzip;

my $options = parse_options();
print_info( $$options{ 'out_file_20_bases' }, $$options{'out_file_full_seq'}, $$options{ 'universal_primer' }, $$options{ 'barcode' } );
exit $?;

sub parse_options {
	my $options = {};
	GetOptions( $options, 'out_file_20_bases|o=s', 'out_file_full_seq|f=s', 'universal_primer|u=s', 'barcode|b=s', 'help|h' );
	unless( $$options{ 'out_file_20_bases' } or $$options{ 'universal_primer' or $$options{ 'out_file_full_seq'} } 
        or $$options{ 'barcode' } ) {
		my $usage = "$0 <--out_file_20_bases|-o> <--out_file_full_seq|-f> <--universal_primer|-u> <--barcode|-b>";
		print STDERR $usage, "\n";
		exit 1;
	}
	return $options;
}

sub print_info {
	my( $out_file_20_bases, $out_file_full_seq, $uni_primer, $barcode ) = @_;
	my $GzipError = undef;
	my $out_20_bases = new IO::Compress::Gzip( $out_file_20_bases ) or die "IO::Compress::Gzip failed: $GzipError\n";
	my $out_full_seq = new IO::Compress::Gzip( $out_file_full_seq ) or die "IO::Compress::Gzip failed: $GzipError\n";
	while( my $header = <STDIN> ) {
		my $seq = <STDIN>;
        	my $sep = <STDIN>;
        	my $ascii = <STDIN>;
        	if( $seq =~ /(.*${barcode}${uni_primer})(.+)/ ) {
            		print $out_20_bases $header;
			print $out_full_seq $header;
            		print $out_20_bases substr( $seq, length( $1 ), 20 ), "\n";
			print $out_full_seq $seq;
            		print $out_20_bases $sep;
			print $out_full_seq $sep;
            		print $out_20_bases substr( $ascii, length( $1 ), 20 ), "\n";
			print $out_full_seq $ascii;
        	}
	}
}
