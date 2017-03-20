# Create a timestamp for unique filenames between script runs.
	$TS = time() % 65535; # This rolls around every 18:12:15.
	$CalcDir = sprintf("Calcs_%.4X", $TS);
	print "$CalcDir\n";
	
	$TS = time() % 16777215; # This rolls around every 194 days 04:20:15.
	$CalcDir = sprintf("Calcs_%.6X", $TS);
	print "$CalcDir\n";
	
	$TS = time() % 1048575; # This rolls around every 12 days 03:16:15.
	$CalcDir = sprintf("Calcs_%.5X", $TS);
	print "$CalcDir\n";
	