#! /usr/bin/perl

# Routine Tests.

my $DensityFileName = "Densities.csv"; # Name of file containing the density information.
my %Densities; # This hash holds all of the solvent density information (key = Solvent ID).
ReadDensities();

if(1 == 1) {
	use Data::Dumper qw(Dumper);
	print Dumper\%Densities;
}

if(1 == 1) {
	$Temp = 20;
	for(my $i=1; $i<=3; $i++) {
		$Density = Density($i, $Temp);
		print "Density of Solvent $i is $Density at $Temp\n";
	}
}

if(1 == 1) {
	$ConcA1 = 97;
	$ConcC1 = ConvertA2C($ConcA1, 1, 20, 1);
	$ConcA2 = ConvertC2A($ConcC1, 1, 20, 1);
	print "Analytical = $ConcA1, Computational = $ConcC1, back to $ConcA2.\n";
}

exit;

## Density subroutines.
	# The following subroutines read the solvent density information from a data file and set up the appropriate hash, and will
	# calculate the solvent density for a desired temperature.  The solvent density is used in the conversion of concentration units.

sub ReadDensities {
	# Read density information in from file and create a hash.
	# Define $DensityFileName and %Densities in MAIN.
		open (FH_DEN, "<$DensityFileName"); # Open file containing the density information.
		LOOP1: while(<FH_DEN>) {
					 if($_ =~ /^\D/) {next LOOP1} # Skip over column headers.
					 chomp;
					 my @Temp = split(/,/); # CSV file.
					 for(my $i=0; $i<=9; $i++) {$Densities{$Temp[0]}[$i] = $Temp[$i+1]} # Populate the hash using Solvent ID number as the key.
		} # END FH_DEN while.
		close FH_DEN; # Close file containing the density information.
		
		# Additional notes:  May want to update this so that all solvent information is read in from a single file and processed into the appropriate variable.
		
} # END ReadDensities()

sub Density {
	# Calculatates the density of the solvent at the defined temperature.
	# Pass SolventID and Temperature (degC).
		#my $Solvent = $_[0];
		#my $Temp = $_[1];
		my ($Solvent, $Temp) = @_;
		my @Coeff = @{$Densities{$Solvent}};
		return $Coeff[0] if($Coeff[2] =~ /NA/i); # Return default (RT) density if the is parameters are missing (NA).
		# Calculate the density for TDE equation parameters.
			my $tau = 1 - (($Temp+273.15)/$Coeff[9]);
			my $Result = $Coeff[2] + $Coeff[3]*$tau**(0.35); # Result in kmol/cum.
			for(my $i=1;$i<=5;$i++) {$Result = $Result + $Coeff[$i+3] * $tau**$i} # Higher polynonimal terms.
			$Result = $Result * $Coeff[1] / 1000; # Convert to g / cm3.
			$Result =  sprintf("%.4f", $Result);
		return $Result;
} # END Density()

## Concentration Conversions:
	# The following subroutines convert concentration from mg/mL to g of solute per g of solvent and vice versa.

sub ConvertA2C {
	# Pass Concentration (mg/mL), Solvent ID, Temperature [degC], Solute Option [0 = use solvent density, 1 = use 1.335].
	# Return Concentration (g/g)
	# Dependencies: Density()
		my ($A, $Solvent, $Temp, $Opt) = @_;
		my $rho_Solvent = Density($Solvent, $Temp); # Pull solvent density.
		my @rho_Solute = ($rho_Solvent, 1.335); # Define Solute densities.
		my $C = $A / ((1000 - $A/$rho_Solute[$Opt])*$rho_Solvent);
		return $C;
} # END ConvertA2C()

sub ConvertC2A {
	# Pass Concentration (g/g), Solvent ID, Temperature [degC], Solute Option [0 = use solvent density, 1 = use 1.335].
	# Return Concentration (mg/mL)
	# Dependencies: Density()
		my ($C, $Solvent, $Temp, $Opt) = @_;
		my $rho_Solvent = Density($Solvent, $Temp); # Pull solvent density.
		my @rho_Solute = ($rho_Solvent, 1.335); # Define Solute densities.
		my $A = (1000 * $C * $rho_Solvent * $rho_Solute[$Opt]) / ($rho_Solute[$Opt] + $C * $rho_Solvent);
		return $A;
} # END ConvertC2A()


















