#! /usr/bin/perl

# Method for determination of Accurcy (Trueness) and Precision (spread) scores for ranking.
# This will be used to decide which solvent will be used as the reference solvent for subsequent predictions.

my @APScores = (); # Holds the APScores

@means = (0.5, 0.1, -0.1, 0.1, 0.2);
@stdevs = (0.8, 2.0, 1.9, 3.0, 1.0);

for(my $i=0; $i< scalar(@means); $i++) {
	$Result = APScore($means[$i], $stdevs[$i]);
	print "APScore = $Result\n";
	push @APScores, APScore($means[$i], $stdevs[$i]);
}

$Idx_Min = minindex(\@APScores);

print "The index of the min value is $Idx_Min and the value is $APScores[$Idx_Min]\n";
exit;

sub APScore {
	# Predefined weighting values (for tuning).
			my $WtA = 1.0;		# Weighting to be given to the accuracy (mean).
			my $WtP = 1.0;		# Weighting to be given to the precision (spread).
			my $APScore = sqrt(($WtA*$_[0])**2 + ($WtP*$_[1])**2);
			return $APScore;
} # END APScore()

sub minindex {
	# Determine the index of the array that contains the lowest value.
	  my( $aref, $idx_min ) = ( shift, 0 );
	  $aref->[$idx_min] < $aref->[$_] or $idx_min = $_ for 1 .. $#{$aref};
	  return $idx_min;
}

