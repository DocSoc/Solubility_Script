#! /usr/bin/perl

my @array = (19, 21, 25); # List of solvents.

for (my $i = 0; $i < scalar(@array); $i++) {
	my $CurrRefSolv = $array[$i];
	my @tmp = @array;
	splice @tmp, $i, 1;
	foreach $SelectSolv (@tmp) {
		$FN = sprintf("File%.3d%.3d", $CurrRefSolv, $SelectSolv);
		print "Filename: $FN\n";


	} # END foreach loop.
} # END for loop.


