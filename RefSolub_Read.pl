#! /usr/bin/perl

print ("\nReference Solubility File Read.\n\n");

# Read in Reference Solubility file and set up key variables.

	my $RefSolFileName = "refsolvsolub.dat";
	my @RefSolub; # 2D Array that holds the reference solubility data.
	my $RefSolNum; # Holds the number of reference solvent solubilities.

$RefSolNum = Read_RefSol_Data();

# Test that data has been extracted and processed correctly.
	print "Number of reference solvents = $RefSolNum\n";
	
	for ($row = 0; $row < $RefSolNum; $row++) {
	    print "$RefSolub[$row][0]\t$RefSolub[$row][1]\t$RefSolub[$row][2]\t$RefSolub[$row][3]\t$RefSolub[$row][4]\t$RefSolub[$row][5]\t$RefSolub[$row][6]\t\n";
	}

exit;

sub Read_RefSol_Data {
	# Reads in the Reference solubilities.
	# Pass: None.
	# Return: The number of reference solvent solubilities that has been read in.
	# Dependences: NObs(), Mean() and StDev().
	# Global Variables: $RefSolFileName and @RefSolub.
	# (c) David Hose. Feb 2017.
	# Open Control File.
		open (FH_REFSOL, "<", $RefSolFileName) or die "Can't open Reference Solubility File $!.\n";
	# Read in contents of control file.
		my $RefSolNum = 0; # Tracks the row numnber of the array and hence number of solubility measurements.
		REF_LOOP:	while(<FH_REFSOL>) {
							next REF_LOOP if($_ =~ /^\W/); # Skip header (will start line with text).
							chomp;
							@temp = split(/\t/, $_);
							# Is there any valid data to be used?  If not read next line.
								# $temp[1] holds the Solvent ID number.
								# If it is blank or hold none digit data, therefore no solvent ID. Skip line.
									next REF_LOOP if($temp[1] eq "" || $temp[1] =~ /^\D+/); # 
								# $temp[2..4] holds the Solubility Values.
								# If all of the elements in this subarray contains either blanks "" or "NA", then there is no solubility data.  Skip line.
									next REF_LOOP if(($temp[2] eq "" || $temp[2] =~ /na/i) && ($temp[3] eq "" || $temp[3] =~ /na/i) && ($temp[4] eq "" || $temp[4] =~ /na/i));
							# Clean solubility data if required (for lines that have 0 < obs < 3.
								# Replace 'NA' (in lines that have either 1 or 2 'NA's with blanks.
									$temp[2] =~ s/na//i;
									$temp[3] =~ s/na//i;
									$temp[4] =~ s/na//i;
							# Build the Reference Solubility Data for this solvent's measurements.
								$RefSolub[$RefSolNum][0] = $RefSolNum + 1; # Entry Number.
								$RefSolub[$RefSolNum][1] = $temp[1]; # Solvent Number.
								$RefSolub[$RefSolNum][2] = $temp[2]; # Measurement #1.
								$RefSolub[$RefSolNum][3] = $temp[3]; # Measurement #2.
								$RefSolub[$RefSolNum][4] = $temp[4]; # Measurement #3.
							# Process the solubility data for calculation of mean and stdev.
								my @Sol = grep /\S/, @temp[2..4]; # Create / clear array holding the solubility data and remove blank elements.
								$RefSolub[$RefSolNum][5] = Mean(@Sol); # Calculate and add the mean of the measurements.
								$RefSolub[$RefSolNum][6] = StDev(@Sol); # Calculate and add the standard deviation of the measurements.
							$RefSolNum++; # Increment row counter.
		} # END while loop over FH_REFSOL.
		# Close Reference Solubility File.
			close FH_REFSOL;
		return $RefSolNum; # Returns the number of reference solvents solubilities.
} # END Read_RefSol_Data()

### STATISTICAL SUBROUTINES ###

sub NObs {
	# Determine the number of values in the array.
		my $nobs = scalar(@_);
} # END NObs()

sub Mean {
	# Calculate the mean.
		my $m = 0;
		foreach $i (@_) {$m = $m + $i}
		$m = $m / NObs(@_);
		return (sprintf("%.2f", $m)); # Return value to 2 dp.
} # END Mean()

sub StDev {
	if(NObs(@_) == 1) {
		# If the number of observations are 1, this leads to a div-by-zero error.
		# To prevent runtime errors return a StDev value of 0.
			return(0);
	} else {
		# Calculate the 'Sample' standard deviation.
		my $m = Mean(@_); # Calculate the mean.
		my $t = 0;
		foreach $i (@_) {$t = $t + ($i - $m)**2}
		my $stdev = sqrt($t / (NObs(@_) - 1));
		return (sprintf("%.2f", $stdev)); # Return value to 2 dp.
	}
} # END StDev()

