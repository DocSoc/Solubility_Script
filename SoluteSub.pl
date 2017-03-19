#! /usr/bin/perl

# Reads the Solute File in and creates an array which contains all of the solutes.
# For the solubility script only the first compound will be used - the script is intended for more general use.

# Global Variables:
$AppYear = 17;

$Result = (Read_Solutes("Solute.list"))[1];
#$Result = (Read_Solutes("Solubility_Test.list"))[0];
print "$Result";
exit;

sub Read_Solutes {
	# Extracts the solutes from a COSMOtherm list file.
		# Pass: Name of the COSMOtherm list file.
		# Return: An array of the solutes.
		# Dependences: LogMessage()
		# Global Variables: NONE.
	# (c) David Hose. March, 2017.
	my $File = $_[0];
	my $Line;				# Holds the current line that has been read in from the Solute list file.
	my @SOLUTES;			# This holds of the solutes file and path information.
	my $SoluteCnt = 0;		# This counts the number of SOLUTES.
	my $ConformerCnt = 0;	# This counts the number of conformers for a specific SOLUTE.
	my $FirstConformer;		# Hold file and path information about the first conformer of a SOLUTE.
	my $SoluteTempArray;	# A temp array.
	# Comments for LogFile.
		LogMessage("Enter: Read_Solutes.", 1);
		LogMessage("Opening Solute File '$File'",3);
	open (FH_SOLUTE, "<$File") or die "Can't open the Solute list file, $! LINE:" . __LINE__ . "\n"; # Open the solute list file.
	# Loop through the lines of the file.
		SOLUTELINE:	while(<FH_SOLUTE>) {
			chomp;
			$Line = $_;
			# This section deals with compounds that have multiple conformers or are composites of multiple compounds (tautomers, etc.)
				# Search for the beginning of a multiple conformer compound (or composite compound).
					if($Line =~ "^Conformer") {
						$ConformerFlag = 1; # Found a multiple conformer compound.
						# Capture the Compound Name to be used.
							$ConformerName = $Line;
							$ConformerName =~ s/^Conformer\s=\s//; # Strip the "Conformer = " prefix from the line.
							$ConformerName =~ s/\s\[\svalue\s=\s0.0//; # Strip the " [ value = 0.0" suffix from the line.
						next SOLUTELINE;
					}
				# From the first line of a conformer section...
					if($Line =~ "^f = " && $ConformerFlag == 1 && $ConformerCnt == 0) {
						$Line =~ s/value\s\=\s0.0//; # Strip the " value = 0.0" suffix.
						$SoluteTempArray[$ConformerCnt] = $Line; # Write this to a temp array.
						$ConformerCnt++; # Increment the Conformer counter.
						next SOLUTELINE;
					}
				# From the other conformer lines.
					if($Line =~ "^f = " && $ConformerFlag == 1 && $ConformerCnt != 0) {
						$Line =~ s/value\s\=\s0.0//; # Strip the " value = 0.0" suffix.
						$SoluteTempArray[$ConformerCnt] = $Line; # Write this to a temp array.
						$ConformerCnt++; # Increment the Conformer counter.
						next SOLUTELINE;
					}
				# Last line of the Conformer section...
					if($Line =~ "^] Conformer") {
						$ConformerFlag = 0; # Reset FLAG for next time.
						$SoluteCnt++; # Increase the Solute counter.
						$MaxConformerCnt = $ConformerCnt; # Define the number of conformers that the compound has.
						$ConformerCnt = 0; # Reset Conformer counter for next time.
						# Take the contents of the temp array and construct the entry for the SOLUTES array.
							for (my $i = 0; $i < $MaxConformerCnt; $i++) {
								$SoluteFile = "$SoluteTempArray[$i] Comp = $ConformerName [ \n" if($i == 0);
								$SoluteFile = $SoluteFile . "$SoluteTempArray[$i] \n" if($i > 0 && $i < ($MaxConformerCnt - 1));
								$SoluteFile = $SoluteFile . "$SoluteTempArray[$i] ] Comp = $ConformerName \n" if($i == ($MaxConformerCnt - 1));
							}
						$SoluteFile =~ s/\/COSMOthermX\/\.\.//;
						$SoluteFile =~ s/\/COSMOthermX\d\d\//\/COSMOthermX$AppYear\//;
						#$SoluteFile =~ s/fdir=\"\.\./fdir=\"\/apps\/cosmologic\/COSMOthermX16\//g; # Modify relative to absolute path.
						$SOLUTES[$SoluteCnt] = $SoluteFile;
						next SOLUTELINE;
					}
			# This section deals with compounds that have single conformers.
				if($Line =~ "^f = " && $ConformerFlag == 0) {
					$SoluteCnt++;
					@TEMP = split(/\s+/, $Line);
					$CompoundName = $TEMP[2]; # Get the COSMOtherm filename of the first conformer.
					$CompoundName =~ s/_c0.cosmo//; # Strip out conformer number and extgension from the file name.
					$Path = $TEMP[3]; # Get the COSMOtherm path of the file.
					$SoluteFile = "f = $CompoundName\_c0.cosmo $Path Comp = $CompoundName\n";
					$SoluteFile =~ s/\/COSMOthermX\/\.\.//;
					$SoluteFile =~ s/\/COSMOthermX\d\d\//\/COSMOthermX$AppYear\//;
					$SOLUTES[$SoluteCnt] = $SoluteFile;
					next SOLUTELINE;
				}
		} # END while SOLUTELINE loop.
	close FH_SOLUTE; # Close solute list file.
	shift @SOLUTES; # Discard blank first entry.
	LogMessage("Leave: Read_Solutes.", 1); # Comment for LogFile.
	LogMessage("PARAM: $SOLUTES[0]", 3);
	return(@SOLUTES);

} # END Read_Solutes()

sub LogMessage {
#	print "";
}

