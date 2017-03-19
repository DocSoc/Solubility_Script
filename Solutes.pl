#! /usr/bin/perl
# User Controlled Variables (Defaults):
	my $Temperature = 25;							# Default temperature for the partition coefficient calculations.
	my $SolventFileName = "Solvents.txt";			# Default filename for the list of solvents (Ex. Spotfire).
	my $SolutesFileName = "Solubility_Test.list";			# Default filename for the list of solutes (Ex. COSMOtherm).
	my $ResultsFile = "PartitioningResults.txt";	# Name of the results file.
	my $FilePath = "COSMOthermData";				# The name of the sub-directory holding the COSMOtherm calculation results.
	my $Debugging = 0;								# Debugging Flag (0 = off, 1 = on) Creates some additional outputs.

	if ($Debugging == 1) {use Data::Dumper;} # Include the Dumper package.
	
# Main Variables:	
	# COSMOtherm related parameterisations and database paths:
		my	$Drive = "T";	# This is the DOS Drive letter to be used to access the external (non-local) COMSOtherm databases. These are the AZ, in-house, created databases.
		my	@ctd;	# This array holds the Parameterisation references for the lower and higher levels of theory (TZVP and TZVPD-Fine only).
		# These parameterisation names can be modified upon software upgrades.
			$ctd[0] = "BP_TZVP_C30_1601.ctd";				# BP TZVP level (Lower level of theory).
			$ctd[1] = "BP_TZVPD_FINE_C30_1601.ctd";	# BP TZVPD-Fine level (Higher level of theory).
		my	@cdir;	# These are the paths used in the header section of the LIST file. (cdir = "client directory"?)
			# These file paths can be modified upon software upgrades.
				$cdir[0] = "C:\\COSMOlogic\\COSMOthermX16\\COSMOthermX\\..\\COSMOtherm\\CTDATA-FILES";	# DOS Path.
				$cdir[1] = "/apps/cosmologic/COSMOthermX16/COSMOthermX/../COSMOtherm/CTDATA-FILES";		# UNIX Path.
		my	@fdir;	# This array holds the required paths for each of the databases in both DOS and UNIX formats. (fdir = "foreign directory"?)
			# Can be modified upon software upgrades or path changes (non-local files).  Note that the DOS drive letter is controlled by $Drive above.
			# Notation: The first index is the database [1-6] listed in SPOTFIRE.  The second index is the for DOS [0] or UNIX [1].
			# SPECIAL NOTE: The script assumes that the X drive has been mapped for COSMOtherm use under DOS.
			# If another drive letter has been mapped on the user machine then the LIST file will not correctly work, unless the $Drive value has been changed appropriately.
				$fdir[1][0] = "..\\COSMOtherm\\DATABASE-COSMO\\BP-TZVP-COSMO\\";								# DB_1: Local BP-TZVP: DOS Path.
				$fdir[1][1] = "/apps/cosmologic/COSMOthermX15/COSMOtherm/DATABASE-COSMO/BP-TZVP-COSMO/";									# DB_1: Local BP-TZVP: UNIX Path.
				$fdir[2][0] = "$Drive:\\AZ_BP_TZVP\\";															# DB_2: External COSMOconf BP-TZVP: DOS Path.
				$fdir[2][1] = "/dbs/AZcosmotherm/AZ_BP_TZVP/";													# DB_2: External COSMOconf BP-TZVP: UNIX Path.
				$fdir[3][0] = "";																				# DB_3: Not currently used: DOS Path.
				$fdir[3][1] = "";																				# DB_3: Not currently used: UNIX Path.
				$fdir[4][0] = "..\\COSMOtherm\\DATABASE-COSMO\\BP-TZVPD-FINE\\";								# DB_4: Local BP-TZVPD-FINE: DOS Path.
				$fdir[4][1] = "/apps/cosmologic/COSMOthermX15/COSMOtherm/DATABASE-COSMO/BP-TZVPD-FINE/";									# DB_4: Local BP-TZVPD-FINE: UNIX Path.
				$fdir[5][0] = "$Drive:\\AZ_BP_TZVPD-FINE\\";													# DB_5: External COSMOconf BP-TZVPD-FINE: DOS Path.
				$fdir[5][1] = "/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE/";											# DB_5: External COSMOconf BP-TZVPD-FINE: UNIX Path.
				$fdir[6][0] = "";																				# DB_6: Not currently used: DOS Path.
				$fdir[6][1] = "";																				# DB_6: Not currently used: UNIX Path.
		# The following lists the array positions for the required data input (Related to the output positions exported from the SPOTFIRE file).
			# Only change these is the Spotfire output table is modified.  Remember that Perl starts indexing arrays from 0 and not 1, hence (Column# - 1).
				my $Solvent_Pos = 1;		# (Column#-1) that contains the compound Name (Recognisable name and not the filename).
				my $File_Pos = 2;				# (Column#-1) that contains the compound Filename (excluding the extension).
				my @Ext_Pos = (3, 6);		# (Columns#-1) that contains the file extension (two columns) appropriate to the level of theory used to create them.
				my @DB_Pos = (4, 7);		# (Columns#-1) that contains the number of database references (two columns).
				my @Conf_Pos = (5, 8);	# (Columns#-1) that contains the number of conformers (two columns). [Should be the same at both levels of theory...]
			# Filename related:
				my @FileList;					# List of files to be processed (Reused).
			# General variables:
				my $Level = 1;				# This holds which level of theory is required; TZVP = 0, TZVPD-Fine = 1.  Default is for the highest level of theory.
				my @SOLUTES;					# This holds of the solutes file and path information.
				my $SoluteCnt = 0;		# This counts the number of SOLUTES.
				my $ConformerCnt = 0;	# This counts the number of conformers for a specific SOLUTE.
				my $FirstConformer;		# Hold file and path information about the first conformer of a SOLUTE.
				my @TEMP;							# General temporary array for holding data.
				my @Args;							# Holds the arguments for system calls.
				my @Results;					# Holds all of the results until output.
				my $Compcnt = 1;			# Counts the number compounds processed.
				my $DryFlag = 0;			# If DryFlag = 1, then dry solvents are assumed for the partition coefficient calculations.  Default is wet solvents.
				my $MutualFlag = 0;		# If MutualFlag = 1, then recalculate the wetting parameters at new temperature.
				my %Wetting;					# This hash holds all of solvent wetting parameters (mutual solubilities).


# Read in the SOLUTES to be processed from the COSMOtherm list.
				open (FH_SOLUTES, "<Solubility_Test.list") or die "Can't open the Solutes file $!"; # This is the list of solvents (From COSMOtherm).
				SOLUTELINE:	while(<FH_SOLUTES>) {
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
											$SoluteFile =~ s/fdir=\"\.\./fdir=\"\/apps\/cosmologic\/COSMOthermX15\//g; # Modify relative to absolute path.
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
										$SoluteFile =~ s/fdir=\"\.\./fdir=\"\/apps\/cosmologic\/COSMOthermX15\//g;
										$SOLUTES[$SoluteCnt] = $SoluteFile;
										next SOLUTELINE;
									}
				} # END of SOLUTES while loop.
				
#print "@SOLUTES\n";

#foreach $Solu (@SOLUTES) {print "$Solu"}
shift @SOLUTES;
print "$SOLUTES[0]\n";


