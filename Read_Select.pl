#! /usr/bin/perl

use Data::Dumper qw(Dumper); # Load Dumper.
print "\n";
$RefSolFileName = "refsolvsolub.dat";
$netpath = "Master_Data"; # DEVELOPMENT LOCATION.
$SolvData = "Solvents.txt";
my %Solvents;		# This hash holds all of the solvent cosmo file locations (key = Solvent ID).
my %Densities;		# This hash holds all of the solvent density information (key = Solvent ID).
my %SolventProps;	# This hash holds all of the solvent properties information (key = Solvent ID).
my %RefSolub; # This hash holds the solubility data keyed by Solvent ID.
my %SelectSolub;
my @RefSolubKeys; # Holds the sorted keys of the RefSolub hash.
my $RefSolNum; # Holds the number of reference solvent that have been used.
my @RefSols; # Holds the reference solubilities (g/g)
my @RefLogSols; # Holds the log of reference solubilities.
my @Means;
my @StDevs;

Read_Solv_Data(); # Read Solvent Data in.
Read_RefSol_Data(); # Read in and Store the experimental solubility data.
#print Dumper %RefSolub;

$CurrCalcPath = "Calcs/Select/"; # Path to the calculations.
# Find all of the TAB files.
	my @Files = <$CurrCalcPath*.tab>;
	@Files = sort @Files; # Ensure that the files are in ASCIIbetical order. So all of the reference solvents will be grouped together, then ordered by Select solvent.
# Extract the Predicted Solublities:
	foreach my $i (@Files) {
		$i =~ m/(\d{3})/; # Identify the Reference solvent. First instance of three consecutive digits (this is the reference solvent).
		$CurrRefSolv = $1 + 0; # Convert from 'text' to numerical value.
		$Res = Read_Solub($i); # Extract the solubility from the TAB file.
		push ( @{$SelectSolub{$CurrRefSolv}}, $Res); # Place the extracted solubility into the SelectSolub hash.
	}
#print Dumper %SelectSolub;


# Loop through all of the reference solvents in turn and calc the Mean, Stdev and APScore.

print "@RefSolubKeys\n";
for (my $key = 0; $key < scalar(@RefSolubKeys); $key++) {
	print "Key is: $RefSolubKeys[$key]\t";	
	# Extract all of the predicted solubilities, based upon the reference solvent.		
		@CurrPredSol = @{$SelectSolub{$RefSolubKeys[$key]}}; # In this case solvent 19 is the first solvent.
		#print "\nPredicted:\t@CurrPredSol\n";
	# Create an array of all of the LOG predicted solubilities.
		my @LogPredSol = @CurrPredSol;
		foreach my $i (@LogPredSol) {$i = log($i)} # Take logs.
		#print "\nLog:\t@LogPredSol\n";
		my @CurrExpt = @RefSols;
		splice @CurrExpt, $key, 1;
		my @CurrLogExpt = @RefLogSols;
		splice @CurrLogExpt, $key, 1;
		
	# Calculate the Predicted - Experimental.
		@DiffPredObs = map { $CurrLogExpt[$_] - $LogPredSol[$_] } 0 .. $#LogPredSol;
		#print "\nDifferences:\t@DiffPredObs\n";
	# Calculate the Mean and Stdev.
		$CurrMean = Mean(@DiffPredObs);
		$CurrStdev = StDev(@DiffPredObs);
		print "Mean = $CurrMean\t(". sprintf("%.2f", exp(abs($CurrMean))) .") \tStdev = $CurrStdev\tAPS = ". APScore($CurrMean, $CurrStdev) ."\n";
		push @Means, $CurrMean;
		push @StDevs, $CurrStdev;
		push @APS, APScore($CurrMean, $CurrStdev);
		
}

$Idx_Min = minindex(\@APS);
$BestSolv_ID = $RefSolubKeys[$Idx_Min];
print "Best solvent: $Solvents{$BestSolv_ID}[1] ($BestSolv_ID) <$Idx_Min>\n";

exit;

sub Read_RefSol_Data {
	# Reads in the Reference solubilities.
		# Pass: NONE.
		# Return: The number of reference solvent solubilities that has been read in.
		# Dependences: NObs(), Mean() and StDev().
		# Global Variables: $RefSolFileName and @RefSolub.
	# (c) David Hose. Feb 2017.
	# Open Reference Solubility File.
		open (FH_REFSOL, "<", $RefSolFileName) or die "Can't open Reference Solubility File $!.\n";
	# Read in contents of control file.
		my $RefSolNum = 0; # Tracks the row numnber of the array and hence number of solubility measurements.
		REF_LOOP:	while(<FH_REFSOL>) {
							next REF_LOOP if($_ =~ /^\W/); # Skip header (header start line with text and not a number).
							chomp;
							@temp = split(/\t/, $_);
							# Is there any valid data to be used?  If not read next line.
								# $temp[1] holds the Solvent ID number.
								# If it is blank or hold none digit data, therefore no solvent ID. Skip line.
									next REF_LOOP if($temp[1] eq "" || $temp[1] =~ /^\D+/); # 
								# $temp[2] holds the Solubility Value.
								# If all of the elements in this subarray contains either blanks "" or "NA", then there is no solubility data.  Skip line.
									next REF_LOOP if(($temp[2] eq "" || $temp[2] =~ /na/i));
							# Build the Reference Solubility Data for this solvent's measurements.
								my $Key = $temp[1]; # Key the hash for the Solvent ID number.
								$RefSolub{$Key}[0] = $temp[2]; # The average solubility value (mg/mL) supplied by Simon.
								$RefSolub{$Key}[1] = ConvmgmL2gg($temp[1], $temp[2], $DenOpt, $Temperature); # The solubility value (g/g).
								$RefSolub{$Key}[2] = log($RefSolub{$Key}[1]); # Take logs of the solubility.
							$RefSolNum++; # Increment row counter.
		} # END while loop over FH_REFSOL.
		close FH_REFSOL; # Close Reference Solubility File.
		# Set up arrays for analysis.
			@RefSolubKeys = sort { $a <=> $b } (keys %RefSolub); # Extract the hash keys and numerical sort them.
			$RefSolNum = scalar(@RefSolubKeys); # Number of reference solvents.
			foreach my $i (@RefSolubKeys) {
				push @RefSols, @{$RefSolub{$i}}[1];
				push @RefLogSols, @{$RefSolub{$i}}[2];
			}
			shift @RefSols; # Discard empty first element.
			shift @RefLogSols; # Discard empty first element.
		return ($RefSolNum);
} # END Read_RefSol_Data()

sub Read_Solub {
	# Extracts the Solubility value from file.
		# Pass: Filename to be opened.
		# Return: Solubility value.
		# Dependences: NONE.
		# Global Varaibles: NONE.
	# (c) David Hose. Feb. 2017.
	my $FN = $_[0];
	my $Solub; # Holds the free energy of fusion value.
	open (FH_SOLUB_READ, "<$FN") or die "Can't open $!. LINE:" . __LINE__ ."\n"; # Open the Gfus calculation file.
	# LogMessage upon error required here.
	while(<FH_SOLUB_READ>) {
	# Find the line containing the solute (Compound Number 1).
		if($_ =~ /^\s{3}1\s\S/i) {
			my @temp = split(/\s+/, $_);
			$Solub = $temp[12];
			last; # Skip rest of file.
		}
	} # END FH_GFUS_READ while loop.
	close FH_SOLUB_READ; # Close the input file.
	return $Solub;
} # END Read_Solub()

sub NObs {
	# Determine the number of values in the array.
		# Pass: An array of numbers.
		# Return: Number entries in the array.
		# Dependences: NONE.
		# Global Variables: NONE.
	# (c) David Hose, Feb, 2017.
		my $nobs = scalar(@_);
} # END NObs()

sub Mean {
	# Calculate the mean.
		# Pass: An array of numbers.
		# Return: The mean.
		# Dependences: NObs()
		# Global Variables: NONE.
	# (c) David Hose, Feb, 2017.
		my $m = 0;
		foreach $i (@_) {$m = $m + $i}
		$m = $m / NObs(@_);
		return (sprintf("%.2f", $m)); # Return value to 2 dp.
} # END Mean()

sub StDev {
	# Calculates the population standard deviation.
		# Pass: An array of numbers.
		# Return: The standard deviation.
		# Dependences: NObs(), Mean()
		# Global Variables: NONE.
	# (c) David Hose, Feb, 2017.
	if(NObs(@_) == 1) {
		# If the number of observations are 1, this leads to a div-by-zero error. To prevent runtime errors return a StDev value of 0.
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

sub ConvmgmL2gg {
	# Conversion of solubility in mg/mL to g/g (of solvent).
		# Pass: Solvent ID, Solubility in mg/mL, solute option and temperature.
		# Return: Solubility in g/g.
		# Dependences: GetSolRho()
		# Global Variables: NONE.
	# (c) David Hose, March 2017.
	my ($ID, $Sol, $Opt, $Temp) = @_;
	my $ConvSol;
	my $Soluterho;
	my $Solvrho = GetSolRho($ID, $Temp); # Pull back the density from the density hash, based upon ID and temperature.
	if($Opt == 1) {$Soluterho = 1.335} # Use the median density of organic compounds from the CCDC database.
	elsif($Opt == 2) {$Soluterho = 1.000} # Use the solute density of 1.000.
	else {$Soluterho = $Solvrho} # Use the solvent density as the density of the solute.
	# END if statement for $Soluterho.
	$ConvSol = $Sol / ((1000-$Sol/$Soluterho) * $Solvrho); # Conversion calculation.
	return($ConvSol);
} # END ConvmgmL2gg()

sub Convgg2mgmL {
	# Conversion of solubility in mg/mL to g/g (of solvent).
		# Pass: Solvent ID, Solubility in g/g, solute option and temperature.
		# Return: Solubility in mg/mL.
		# Dependences: GetSolRho()
		# Global Variables: NONE.
	# (c) David Hose, March 2017.
	my ($ID, $Sol, $Opt, $Temp) = @_;
	my $ConvSol;
	my $Soluterho;
	my $Solvrho = GetSolRho($ID, $Temp); # Pull back the density from the density hash, based upon ID and temperature.
	if($Opt == 1) {$Soluterho = 1.335} # Use the median density of organic compounds from the CCDC database.
	elsif($Opt == 2) {$Soluterho = 1.000} # Use the solute density of 1.000.
	else {$Soluterho = $Solvrho} # Use the solvent density as the density of the solute.
	# END if statement for $Soluterho.
	$ConvSol = (1000 * $Sol * $Solvrho * $Soluterho) / ($Soluterho + $Sol * $Solvrho); # Conversion calculation.
	return($ConvSol);
} # END Convgg2mgmL()

sub GetSolRho {
	# Pulls back the density of the solvent based upon ID and temperature.
		# Pass: Solvent ID and Temperature (degC).
		# Return: Density.
		# Dependences: NONE.
		# Global Variables:  %Densities.
	# (c) David Hose, March 2017.	
	my ($ID, $Temp) = @_;
	my @Coeffs = @{$Densities{$ID}}; # Get the data for the desired solvent.
	return $Coeffs[0] if($Coeffs[2] =~ /na/i); # Returns the default (RT) density of the solvent.
	# Calculate the density for the TDE equation parameters.
		my $tau = 1 - (($Temp + 273.15)/ $Coeffs[9]);
		my $Density = $Coeffs[2] + $Coeffs[3] * $tau**(0.35); # Result in kmol/cum.
		for(my $i = 1; $i <= 5; $i++) {$Density = $Density + $Coeffs[$i+3] * $tau**$i} # Higher polynonimal terms.
		$Density = $Density * $Coeffs[1] / 1000; # Converts to g/mL.
		$Density = sprintf("%.3f", $Density); 
	return($Density);
} # END GetSolRho()

sub Read_Solv_Data {
	# This subroutine open the Master Solvent File, extracts solvent cosmo file locations,
	# solvent density and physical properities.  A set of hash variables are populated.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: LogMessage().
		# Global Variables: $netpath, $Solvent_Data, %Solvents, %Densities and %SolventProps.
	# (c) David Hose. Feb 2017.
		my $msg; # An error message.
		LogMessage("Enter: Read_Solv_Data()", 2);
		open (FH_SOLV, "<" . $netpath . "/" . $SolvData) or $msg = "Can't Open Solvent Data '$SolvData'. $!. LINE:". __LINE__; # Open Solvent Master Data File.
			if($msg ne "") {
				LogMessage("ERROR: $msg\n", 1);
				print "$msg";
				exit;
			}
		LOOP_SOLV: while(<FH_SOLV>) {
			chomp;
			next LOOP_SOLV if($_ =~ /^\D/); # Skip header.
			my @temp = split(/\t/, $_); # Split the current line down to its component parts (TAB separated).
			# Extract from the @temp array the Solvent Location, Density Information, and Property Portions for further processing.
				my @SolvLoc = @temp[0..8]; # The location information of the cosmo files.
				my @DenDat = ($temp[0], @temp[12..21]); # Extract the Density Data.
				my @Props = ($temp[0], $temp[1], @temp[9..11]); # Get properties: Solvent ID, Name, CAS#, melting and boiling points.
				$Props[1] =~ s/\s\[.+\]$//g; # Tidy up the solvent name (removes sections that contain '[...]')
			# Build the appropriate hashes.
				for(my $i=0; $i<=7; $i++) {$Solvents{$SolvLoc[0]}[$i] = $SolvLoc[$i+1]} # Populate the Solvent hash using Solvent ID number as the key.
				for(my $i=0; $i<=9; $i++) {$Densities{$DenDat[0]}[$i] = $DenDat[$i+1]} # Populate the Densities hash using Solvent ID number as the key.
				for(my $i=0; $i<=3; $i++) {$SolventProps{$Props[0]}[$i] = $Props[$i+1]} # Populate the SolventProps hash using Solvent ID number as the key.
		} # END LOOP_SOLV while loop.
		close FH_SOLV; # Close Solvent Master Data File.
		LogMessage("MESSG: \%Solvents, \%Densities and \%SolventProps have been set up.", 3);
		LogMessage("Leave: Read_Solv_Data()");
} # END Read_Solv_Data()

sub LogMessage {
	print "";
}

sub APScore {
	# Predefined weighting values (for tuning).
			my $WtA = 1.0;		# Weighting to be given to the accuracy (mean).
			my $WtP = 0.0;		# Weighting to be given to the precision (spread).
			my $APScore = sqrt(($WtA*$_[0])**2 + ($WtP*$_[1])**2);
			return $APScore;
			# NOTE: Tests of the solubility data, indicates that the STDEV is larger than the MEANS.  Furthermore, the variation in STDEV is comparatively small.
			# Based upon these observations, the STDEV values have been excluded from the APScore calculation ($WtP = 0).
} # END APScore()

sub minindex {
	# Determine the index of the array that contains the lowest value.
	  my( $aref, $idx_min ) = ( shift, 0 );
	  $aref->[$idx_min] < $aref->[$_] or $idx_min = $_ for 1 .. $#{$aref};
	  return $idx_min;
}

