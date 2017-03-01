#! /usr/bin/perl

# Experimental Solubility Information and conversions.
	@ExpSolmg = (  2.3, 32.1, 51.2, 29.8,  0.10,  9.3, 17.2); # Experimental Solubilities (mg/mL).
	#print "@ExpSolmg\n";
	@ExpSolg = SolConv(@ExpSolmg); # Convert solubility units (g/g).
	#print "@ExpSolg\n";
	@LnExpSolg = @ExpSolg;
	foreach $i (@LnExpSolg) {$i = log($i)} # Log conversion.
	#print "@LnExpSolg\n";
	$RefSolvs = scalar @ExpSolg; # Number of experimental solvents.
	#print "$RefSolvs\n";

# Predicted solubilities from the reference experimental solubilities (g/g).
	@PredSolg1 = (  2.3, 32.5, 50.0, 29.1,  0.20,  9.7, 17.5);
	@PredSolg2 = (  2.1, 32.1, 51.5, 29.3,  0.30,  9.5, 17.0);
	@PredSolg3 = (  1.6, 31.8, 51.2, 31.2,  0.01,  8.7, 16.2);
	@PredSolg4 = (  1.1, 28.1, 50.0, 29.8,  0.25, 12.3, 17.9);
	@PredSolg5 = (  2.2, 32.2, 51.3, 29.9,  0.10,  9.1, 17.1);
	@PredSolg6 = (  5.2, 28.2, 45.5, 35.5,  0.01,  9.3, 19.8);
	@PredSolg7 = (  4.4, 36.6, 65.6, 27.5,  0.50,  9.5, 17.2);
# Make a AoA of the predicted solubilities.
	@PredSolg = ( [@PredSolg1],
				  [@PredSolg2],
				  [@PredSolg3],
				  [@PredSolg4],
				  [@PredSolg5],
				  [@PredSolg6],
				  [@PredSolg7] );

for (my $i = 0; $i < $RefSolvs; $i++) {
	my @Temp;
	for (my $j = 0; $j < $RefSolvs; $j++) {
		$Temp[$j] = $PredSolg[$i][$j];
	}
	foreach $k (@Temp) {$k = log($k)} # Log conversion.
	@SolDiff = map { $Temp[$_] - $LnExpSolg[$_] } 0 .. $#Temp;
	splice @SolDiff, $i, 1;
	$Means[$i] = Mean(@SolDiff);
	}

print "The Means are: @Means\n";

exit;

sub SolConv {
# A dummy conversion.
	my @a = @_;
	foreach my $i (@a) {$i = $i + 0};
	return (@a);
}

sub Mean {
	my $m = 0;
	foreach my $i (@_) {$m = $m + $i}
	return ($m / scalar (@_));
}
