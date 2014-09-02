#!/usr/bin/perl

use Getopt::Long;

my ( $help, $input_file, $output_file );

my $help = 0;

GetOptions(
    'h'     => \$help,
    'i=s'  => \$input_file,
    'o=s' => \$output_file,
) or exit  "Usage: $0 -h for help\n";

#die "Missing -o use $0 -h for usage" unless $args{o};


printhelp() if $help;
print $input_dir;
if ($input_file && $output_file) { process_file(); } else { printhelp(); }

sub process_file {

#open master DNS file
open(FH,"$input_file") || die "Could not open input file, $infile\n";
open(OUT,">>$output_file") || die "Could not open output file, $outfile\n";
print OUT "// SLAVE ZONES\n\n// master domains\n";
while ( $line = <FH> ) {
	if ($line =~ /Domain Masks/) {
		chomp $line;
		print OUT "$line\n";
	}
	if ($line =~ /zone "/) {
		chomp $line;
		print OUT "$line\n";
		print OUT "\t\tmasters { 94.236.41.85\;}\;\n";
		foreach (0..1) {
			my $outline = <FH>;
			chomp $outline;
			$outline =~ s/type master/type slave/g;
			$outline =~ s/file "master/file "slaves/g;
				print OUT "$outline\n";
		}
			print OUT "\t\tallow-transfer { 94.236.41.85\;}\;\n\t\}\;\n";
	}
		
}
}
close FH;
close OUT;
exit 0;

sub printhelp {
print "\n$0 -i <file> -o <file> \n\n -i Input file (Master Zone file)\n -o Output file (Slave Zone file)\n\n";
exit 1;
}

exit;
