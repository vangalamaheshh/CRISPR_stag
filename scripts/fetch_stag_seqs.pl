#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use IO::Compress::Gzip;
use IO::Uncompress::Gunzip;

my $options = parse_options();
print_info( $$options{ 'ref_file' }, $$options{ 'out_file' }, $$options{ 'universal_primer' }, $$options{ 'barcode' } );
exit $?;

sub parse_options {
	my $options = {};
	GetOptions( $options, 'ref_file|r=s', 'out_file|o=s', 'universal_primer|u=s', 'barcode|b=s', 'help|h' );
	unless( $$options{ 'ref_file' } or $$options{ 'out_file' } or $$options{ 'universal_primer' } 
        or $$options{ 'barcode' } ) {
		my $usage = "$0 <--ref_file|-r> <--out_file|-o> <--universal_primer|-u> <--barcode|-b>";
		print STDERR $usage, "\n";
		exit 1;
	}
	return $options;
}

sub print_info {
	my( $ref_file, $out_file, $uni_primer, $barcode ) = @_;
	my $GunzipError = undef;
	my $in = new IO::Uncompress::Gunzip( $ref_file ) or die "gunzip failed: $GunzipError\n";
	my $GzipError = undef;
	my $out = new IO::Compress::Gzip( $out_file ) or die "IO::Compress::Gzip failed: $GzipError\n";
	while( my $header = <$in> ) {
		my $seq = <$in>;
        my $sep = <$in>;
        my $ascii = <$in>;
        if( $seq and $seq =~ /(.*${barcode}${uni_primer})(.+)/ ) {
            print $out $header;
            print $out substr( $seq, length( $1 ), 20 ), "\n";
            print $out $sep;
            print $out substr( $ascii, length( $1 ), 20 ), "\n";
        }
	}
}
