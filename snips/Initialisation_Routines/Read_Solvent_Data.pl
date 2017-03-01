#! /usr/bin/perl

# Read in the Solvent Data {COSMOtherm location DB, Densities and Properties}.

my $Script_Data_Directory = "../../Master_Data"; # Location of the Data File (/projects/PharmDev/....)
my $Solvent_Data = "Solvents.txt";
my %Solvents; # This hash holds all of the solvent cosmo file locations (key = Solvent ID).
my %Densities; # This hash holds all of the solvent density information (key = Solvent ID).
my %SolventProps; # This hash holds all of the solvent properties information (key = Solvent ID).

Read_Solv_Data();

my $debug = 1;
if($debug == 1) {
	use Data::Dumper qw(Dumper)
	print Dumper\%Densities;
	print Dumper\%Solvents;
	print Dumper\%SolventProps;
}

exit;

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
