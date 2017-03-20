#! /usr/bin/perl

# Determines the correct path to the required solvent.


$Solvent = 1;

## Key file locations:
		## Network files (Key master files).
			my $netpath = "/projects/PharmDev/COSMOtherm/Ref_Solubility/Master_Data";	# Provisional location.
			$netpath = "Master_Data"; # DEVELOPMENT LOCATION.
			my $SolvData = "Solvents.txt";	
		# Solvent Properties 'Database' variables:
			my %Solvents;		# This hash holds all of the solvent cosmo file locations (key = Solvent ID).
			my %Densities;		# This hash holds all of the solvent density information (key = Solvent ID).
			my %SolventProps;	# This hash holds all of the solvent properties information (key = Solvent ID).
			
		
			my @COSMO_DB;
				# The following is a temporary solution.
				$COSMO_DB[0] = "/apps/cosmologic/COSMOthermX16/COSMOtherm/DATABASE-COSMO/BP-TZVPD-FINE"; # Points to the COSMOlogic database (AUTOMATE THIS)
				$COSMO_DB[1] = "/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE"; # Points to the AZ database.

Read_Solv_Data();
COSMO_Solv(1); # Single Conformer - COSMOtherm DB.
COSMO_Solv(2); # Single Conformer - AZ DB.
COSMO_Solv(124); # Multiple Conformers -  AZ DB.
COSMO_Solv(9); # Multiple Conformers -  COSMOtherm DB.

exit;

sub COSMO_Solv {
	#
		# Pass: Solvent ID.
		# Return: Solvent Path/filename.
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT
	# (c) David Hose. March 2017.
		LogMessage("Enter: Read_Solv()", 1); # Log file message.
		$Solv_ID = $_[0]; # Pick up the solvent number ID.
		@Data = @{$Solvents{$Solv_ID}}; # Pull out COSMOtherm solvent data from the Solvent Hash.
		$Subdir = lc(substr($Data[1], 0, 1));	# Grab the first character of the name (of sub-folder) and ensures that it's in lower case.
		if($Data[6] == 4) {$fdir=$COSMO_DB[0]} else {$fdir=$COSMO_DB[1]} # Select the correct database.
		# For a single conformer solvent.
			if ($Data[7] == 1) {
				print "f = $Data[1]_c0.$Data[5] fdir=\"$fdir/$Subdir\" VPfile DGfus = 0 \n";
				# Might need to add DGfus = 0 to the above line.
			}
		# For a multiple conformer solvent.
			if ($Data[7] > 1) {
				print "f = $Data[1]_c0.$Data[5] fdir=\"$fdir/$Subdir\" Comp = $Data[1] [ VPfile DGfus = 0 \n";
				for ($conf = 1; $conf < ($Data[7] - 1); $conf++) {
					print "f = $Data[1]_c$conf.$Data[5] fdir=\"$fdir/$Subdir\"\n"
				}
				$lastconf = $conf;
				print "f = $Data[1]_c$lastconf.$Data[5] fdir=\"$fdir/$Subdir\" ]\n";
				# Might need to add DGfus = 0 to the above line.
			} 
		LogMessage("PARAM: Solvent #$Solv_ID '$Data[0]'",3);
		LogMessage("MESSG: DB: $fdir",3);
		LogMessage("MESSG: Conformers: $Data[7]",3);
		#LogMessage("",3);
		LogMessage("Enter: Read_Solv()", 1);
		return;
} # END Select_Solv()




sub LogMessage {
	print "";
}

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



