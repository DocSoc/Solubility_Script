#! /usr/bin/perl

# Conversion of solubilities in mg/mL to g/g and vice versa.
BEGIN { $| = 1 }	# Turn on autoflush for STDOUT.
my $Script_Data_Directory = "Master_Data"; # Location of the Data File (/projects/PharmDev/....)
my $Solvent_Data = "Solvents.txt";
my %Solvents; # This hash holds all of the solvent cosmo file locations (key = Solvent ID).
my %Densities; # This hash holds all of the solvent density information (key = Solvent ID).
my %SolventProps; # This hash holds all of the solvent properties information (key = Solvent ID).
my @Inputs = (1.23, 11.6, 97, 52, 23);

$DenOpt = 1;
$SolventID = 1; # 29 acetone.
$Temp =  25;

Read_Solv_Data();

for($j=1;$j<=272;$j++) {

my @Output1;
my @Output2;

print "\nConversion\n\n";
print "Solvent ID = $j\tDensity = ";
print (GetSolRho($j, $Temp));
print "\tSolute Option = $DenOpt\n\n"; 

	foreach $Input (@Inputs) {
		$Output = ConvmgmL2gg($j, $Input, $DenOpt, $Temp);
		print "$Input mg/mL is $Output g/g\n";	
		push @Output1, $Output;
	}
	print "\n";
	foreach $Input (@Output1) {
		$Output = Convgg2mgmL($j, $Input, $DenOpt, $Temp);	
		print "$Input g/g is $Output mg/mL\n";
		push @Output2, $Output;
	}
	print "\n";
} # END for loop $j.
exit;

sub ConvmgmL2gg {
	# Conversion of solubility in mg/mL to g/g (of solvent).
		# Pass: Solvent ID, Solubility in mg/mL, solute option and temperature.
		# Return: Solubility in g/g.
		# Dependences: GetSolRho()
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
		# Dependences:
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
		# Dependences: None.
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
	# Pass: None.
	# Return: None.
	# Dependences: None.
	# Global Variables: $Script_Data_Directory, $Solvent_Data, %Solvents, %Densities and %SolventProps.
	# (c) David Hose. Feb 2017.
	open (FH_SOLV, "<" . $Script_Data_Directory . "/" . $Solvent_Data) or die "Can't Open $!."; # Open Solvent Master Data File.
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
} # END Read_Solv_Data()

