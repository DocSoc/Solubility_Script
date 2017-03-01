
# Create a timestamp for unique filenames between script runs.
	$TS = time() % 65535;
	$Header = "Parameters\nOptions\n";
	$TS = 123;

my @RefSolvs = (  1,   2,   5,   9,  15,  23,  55, 101, 120, 150); # The Solvent IDs of the reference solvents.
my @PredSolvs = (3,4,6,7,8,10,11,12,13,14); # The Solvent IDs of the prediction solvents.

	$CalcDir = sprintf("Calcs_%.4X", $TS);
	mkdir $CalcDir, 0777; # Create directory to hold all of the calculations.

# Create the calculations files to determine the Gfus of the solute in each of the reference solvents from the measured solubilities.
	# Make directory for the RefSolv Calculations.
		mkdir "$CalcDir/Gfus", 0777; # Create directory to hold the Gfus calculations.
	foreach my $Ref (@RefSolvs) {
		my $FN = sprintf("Ref%.3d_%.4X", $Ref, $TS); # Create filename.
		print "$FN\tCreating..."; # Inform user of progress.
		open (FH_REF, ">$CalcDir/Gfus/$FN.inp") or die "Can't create INP file $!.\n";
		print FH_REF "$Header"; # Write the INP header (license, parameters etc.).
		print FH_REF "!! Gfus Calculation. Reference Solvent \#$Ref !!\n"; # Comment line.
		print FH_REF "SOLUTE FILE PATH INFORMATION.\n";
		print FH_REF "FILE PATH INFORMATION FOR REFERENCE SOLVENT \#$Ref.\n";
		print FH_REF "ROUTE CARD.\n";
		close FH_REF;
		print "Submitting..."; # Inform user of progress.
		print "Complete.\n"; # Inform user of progress.
	} # END @RefSolvs Calc loop.
	print "\n";

# Calc.
	mkdir "$CalcDir/Sol", 0777;
	for (my $Ref = 0; $Ref < 5; $Ref++) {
		my @temp = @RefSolvs;
		splice @temp, $Ref, 1;
		foreach my $Sol (@temp) {
			my $FN = sprintf("Sol%.3d%.3d_%.4X", $RefSolvs[$Ref], $Sol, $TS);
			print "$FN\tCreating..."; # Inform user of progress.
			open (FH_SOL, ">$CalcDir/Sol/$FN.inp") or die "Can't create INP file $!.\n";
			print FH_SOL "$Header"; # Write the INP header (license, parameters etc.).
			print FH_SOL "!! Solubility Calculation for Solvent \#$Sol using \#$RefSolvs[$Ref] as reference. !!\n"; # Comment line.
			print FH_SOL "SOLUTE FILE PATH INFORMATION.\n";
			print FH_SOL "FILE PATH INFORMATION FOR TEST SOLVENT \#$Sol.\n";
			print FH_SOL "ROUTE CARD.\n";
			close FH_SOL;
			print "Submitting..."; # Inform user of progress.
			print "Complete.\n"; # Inform user of progress.
		}
	} # END Solvents loop.
	print "\n";

	# Predictions.
		mkdir "$CalcDir/Pred", 0777;
		foreach my $Pred (@PredSolvs) {
			my $FN = sprintf("Pred%.3d_%.4X", $Pred, $TS); # Create filename.
			print "$FN\tCreating..."; # Inform user of progress.
			open (FH_PRED, ">$CalcDir/Pred/$FN.inp") or die "Can't create INP file $!.\n";
			print FH_PRED "$Header"; # Write the INP header (license, parameters etc.).
			print FH_PRED "!! Gfus Calculation. Reference Solvent \#$Ref !!\n"; # Comment line.
			print FH_PRED "SOLUTE FILE PATH INFORMATION.\n";
			print FH_PRED "FILE PATH INFORMATION FOR PREDICTION SOLVENT \#$Ref.\n";
			print FH_PRED "ROUTE CARD.\n";
			close FH_PRED;
			print "Submitting..."; # Inform user of progress.
			print "Complete.\n"; # Inform user of progress.
		} # END @RefSolvs Calc loop.
		print "\n";


