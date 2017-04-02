#! /usr/bin/perl

# Perl script to process measured solubilities, determine the best reference solvent, and then run a series of predictions.

BEGIN { $| = 1 }	# Turn on autoflush for STDOUT.
my $debug = 1; # DEVELOPMENT ONLY.
my $LiveRun = 0; # DEVELOPMENT ONLY.  Set 1 for running the COSMOtherm Calculations.  Ensure COSMOtherm module has been loaded for the current terminal session.
my $Cluster = 3; # Local (0), Cluster (1), No calculation (3). 

# Load any required packages:
	if($debug == 1) {use Data::Dumper qw(Dumper)} # Load the Data Dumper for checking data structures of complex variables.
	use Cwd;
	use File::Path;

### Variables: ###
	## Script Information (Only change ** lines upon script updates).
			my $author = "David Hose";		# Primary Author.
			my $verauthor = "David Hose"; 	# Subversion Author.**
			my $version = "0.1a";			# Script Version.**
			my $versiondate = "Mar 2017";	# Date of current version of the script.**
			my @Temp = split(/\//, $0);		# Automatically get the name of the script using one of perl's special variables.
			my $scriptname = $Temp[-1];		# Last element of the array in the script name.
			my $scriptpath = join '/', @Temp[0..$#Temp-1]; # Path to the script.  This isn't working as intended in UNIX environ.
	## Key file locations:
		## Network files (Key master files).
			my $netpath = "/projects/PharmDev/COSMOtherm/Ref_Solubility/Master_Data";	# Provisional location.
			$netpath = "Master_Data"; # DEVELOPMENT LOCATION.
			my $SolvData = "Solvents.txt";
		## COSMOtherm Related Directories.
			my $appsdir = "/apps"; # Points to applications directory (UNIX environment).
			$appsdir = "apps" if($LiveRun == 0); # DEVELOPMENT LOCATION.
			my $cosmologicdir = "$appsdir/cosmologic"; # Points to the cosmologic directory within the application directory (UNIX environment).
			my $cosmodbpath; # Path of the COSMOtherm compound database.  NEEDS SORTING OUT IN CTD_PATH SO @COSMO_DB CAN BE CORRECTLY SET UP.
		## Log file settings.
			my $LogFileName = join('', "SolLog-", time(), ".log"); # Log file name (only use a limited number of digits). REPLACE WITH TIMESTAMP.
			$LogFileName = join('', "SolLog-", "000001" , ".log"); # DEVELOPMENT. REMOVE IN PRODUCTION.
			$LogLevel = 3; # 1 = Sparse, 2 = Normal and 3 = Verbose. (Allow this to be set by the Parser!!!)	
		## Data files for the script to work with.
			my $CTRLFileName = "control.dat";				# DEVELOPMENT DEFAULT. # Control file. (Application and Parameter years, and temperature).
			my $ProjectFileName = "project.dat";			# DEVELOPMENT DEFAULT. # Project Information file.
			my $SoluteFileName = "Solubility_Test.list";	# DEVELOPMENT DEFAULT. # Solute List.
			my $RefSolFileName = "refsolvsolub.dat";		# Holds the filename that contains the solubility information.
			my $SolventFile = "solventlist.dat";			# Holds the list of Solvents for which predictions are to be made in.
		## Calculation subdirectory names.
			my $CalcsDir = "Calcs";
			my @Subdir = ("Ref", "Select", "Pred"); # Names to be used of the calculation subdirectories:
				#	[0] = Reference / Gfus calculations.
				#	[1] = Selection.
				#	[2] = Predictions.
		
		
	## General variables:
		# Misc:
			my @usr;		# Holds ID information about the user
			my @scriptdur;	# Holds the start, end and duration times of the script.
		# COSMOtherm related variables:
			# General:
				my $AppYear;	# Holds the Application Year (COSMOtherm version).
				my $ParamYear;	# Holds the Parameterisation Year (COSMOtherm parameterisation).
				my @Years;		# Holds the available COSMOtherm application versions.
				my $cdir;		# Holds the path and name of the required CTD file (Used by COSMOtherm).
				my $ctd;		# Holds the name of the required CTD file (Used by COSMOtherm).
				my $ldir;		# Holds the path of the license file (Used by COSMOtherm).
			# COSMOtherm Database location Variables.
				my @COSMO_DB;
				# $COSMO_DB[0] path is set later when all key parameters are known.  Points to the COSMOlogic database.
				$COSMO_DB[1] = "/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE"; # Points to the Company database.
			
		# Project related variables:
			my $ProjectName;	# Project Name (AZDxxxx or pre-nomination name).
			my $Compound;		# AZxxxxxxxx name.
			my $AltName;		# Alternative compound name (trivial name).
			my $Client;			# Name of the client who requested the work.
		# Solvent Properties 'Database' variables:
			my %Solvents;		# This hash holds all of the solvent cosmo file locations (key = Solvent ID).
			my %Densities;		# This hash holds all of the solvent density information (key = Solvent ID).
			my %SolventProps;	# This hash holds all of the solvent properties information (key = Solvent ID).
		# Script control...
			my $DenOpt = 1;		# Defines which density to use for the solute. 1 = 1.335, 2, = 1.000, 3 = Solvent Density.
			my $TExpt_C;		# The temperature of the solubility measurement.
			
			#my @RefSolub; 	# 2D Array that holds the reference solubility data.  This data will be in mg/mL.
			my %RefSolub;
			my $RefSolNum;	# Holds the number of reference solvent solubilities.
			
			my $Solute; # Holds the name of the solute.
			
			my @TestSolvents; # Hold the list of Solvents in which solubility predictions are to be made.
			my $Curr_Ref_Solub; # Hold the Current Reference Solubility.
			my @Solvents; # Holds the list of Prediction Solvents.
			my %SelectSolub;
			
			my @RefLogSols; # Holds the LOG of reference solubilities.
			my @Means; # Holds the Means of the LOG of pred/obs solubilities.
			my @StDevs; # Holds the StDev of the LOG of pred/obs solubilities.
		

### MAIN ROUTINE STARTS HERE ###
	## INITIALISATION ##
		# This section of code:
			# Welcomes the User,
			# Starts a LogFile running,
			# Checks COSMOtherm is loaded,
			# Loads the Control parameters (setting appropriate paths),
			# Loads the Project information and
			# Reads in Solvent Properties.
		$scriptdur[0] = time(); # Note start time for script.
		User(); # Determine who's running the script (for reports and personalisation).
		Hello(); # Welcome User.
		# Start log file.
			print "\tStarting Log file: $LogFileName\n";
			open (FH_LOG, ">$LogFileName") or die "Can't open the Log File $!. LINE:". __LINE__ ."\n"; # Open the log file.
			LogFileHeader(); # Write general details of the script to the log file.
			LogMessage("MESSG: STARTING SCRIPT", 1);
			LogMessage("MESSG: INITIALIATION", 1);
		# Initialisation: Checks and populate variables.
			print "\tConfirm COSMOtherm installed...";
			COSMOthermInstalled(); # Check that COSMOtherm is installed if not exit.
			@Years = YearVersions(); # Determine the Year codes of the available COSMOtherm versions.
			print "DONE.\n";
			print "\tConfirm R is installed...";
			RInstalled(); # Check that R iinstalled.
			print "DONE.\n\tRead Control Parameters '$CTRLFileName'...";
			CTRL_Read(); # Read in CONTROL Parameters (Application Year, Parameterisation, and Temperature).
			print "DONE.\n\tCOSMOtherm Directory Locations...";
			CTD_Path(); # Formally set Application Year (numerical) and Parametermisation.  Defines Parameter and License files locations.
			$COSMO_DB[0] = "$cosmologicdir/COSMOthermX$AppYear/COSMOtherm/DATABASE-COSMO/BP-TZVPD-FINE"; # Path to COSMOlogic can now be set.
			print "DONE.\n\tRead Master Solvent Data '$SolvData'...";
			Read_Solv_Data(); # Read in Master Solvent Data.
			print "DONE.\n\tRead Project Information '$ProjectFileName'...";
			Read_Project(); # Read in Project Information.
			print "DONE.\n\tRead Solute File '$SoluteFileName'...";
			$Solute = (Read_Solutes($SoluteFileName))[0]; # An array is returned (future codes).  Only the first element is required.
			print "DONE.\n\tRead Solvent File '$SolventFile'...";
			@TestSolvents = Read_Solvents($SolventFile); # Create a list of solvents to read prediction upon.
			print "DONE.\n";
	## END INITIALISATION ##
	## REFERENCE SOLUBILITY DATA ##
		# This section of code:
			# Reads in the experimental reference solubility information.
		print "\tRead Experimental Reference Solvent Solubility Data '$RefSolFileName'...";
			$RefSolNum = Read_RefSol_Data();
		print "DONE.\n";
	## END REFERENCE SOLUBILITY DATA ##
	## PERFORM THE REFERENCE SOLUBILITY CALCULATIONS IN COSMOTHERM ##
		# This section of code...
			# Creates the Calculation Directory and Reference Subdirectory.
		LogMessage("MESSG: Starting Gfus Calculations.", 1);
		# Make a directory to store all of the calculations.
			mkdir "$CalcsDir", 0777; # ERROR capture required.
		# Make a subdirectory for the references calculations.
			mkdir "$CalcsDir/Ref", 0777; # ERROR capture required.
		# For each of the solvents for which there is a reference solubility measurement, set up calculations...
			print "\tFree-Energy of Fusion Calculations.\n";
			my $cnt = 0; # A counter.
			my $cals = scalar(@RefSolubKeys); # Number of calculations to be run.
			foreach my $CurrSolv (@RefSolubKeys) {
				#$CurrSolv = $RefSolub[$i][1]; # Pulls back the Solvent ID Number.
				LogMessage("MESSG: Free-Energy Calculation in Solvent $CurrSolv.", 1);
				my $msg; # Holds an error message,
				$cnt++; # Increment counter.
				$CurrFile = sprintf("Gfus%.3d", $CurrSolv); # Creates the File name based upon the Solvent ID Number.
				$CurrSolvName = ${$Solvents{$CurrSolv}}[0]; # Pulls back the Solvent common name.
				my $lognote = "[". sprintf("%2.d", $cnt)  .":". sprintf("%2.d", $cals) ."] $CurrFile\tReference Solvent: '$CurrSolvName'.";
				print "\t\t$lognote\n"; # Inform user which INP file is being set up.
				LogMessage("MESSG: Setting up $lognote", 3);
				open (FH_OUTPUT, ">$CalcsDir/Ref/$CurrFile.inp") or $msg = "Can't open Reference Calculation File. $! LINE:". __LINE__;
				LogErrMessg($msg) if ($msg ne ""); # Handle the error.
				
				COSMO_Files ($ctd, $cdir, $ldir); # Add ctd parameters, directory and license locations.
				COSMO_Print(1); # Gfus Print options.
				COSMO_Comment(1, $CurrSolv); # Add an appropriate comment line.
				COSMO_Solute(1, $Solute); # Add Solute line(s) based upon the calculation option.
				COSMO_Solv($CurrSolv); # Add Solvent line(s).
				$Curr_Ref_Solub = $RefSolub{$CurrSolv}[1]; # Pull back the correct solubility for the current solvent.
				COSMO_Route(1); # Add Option 1 (Gfus) Routecard.
				close FH_OUTPUT; # Close the Current Reference Solvent COSMOtherm .INP file.
				# Run/Submit Calculation.
					if($Cluster == 0) {
						COSMO_Submit(1); # COSMOtherm calculation run locally. (Will wait until calculation returns).
					}
					elsif($Cluster == 1) {
						COSMO_Submit(2); # COSMOtherm calculation submitted to cluster. (Moves on before calculations are complete).
					}
					else {
						# No calculations are run.  DEVELOPMENT.
					}
			} # END for loop @RefSolubKeys (Current Solvent)
		LogMessage("MESSG: Completed Gfus Calculations.", 1);
		print "\tExtracting Free-Energy Results.\n";
		LogMessage("MESSG: Extracting Gfus results.", 1);
		# Collect Gfus results from the resultant TAB files.
			$CurrCalcPath = "Calcs/Ref/"; # SMARTEN UP.
			my @Files = <$CurrCalcPath*.tab>;
			# Numerically sort filenames?!
			foreach $File (@Files) {
				my $Filename = (split(/\//, $File))[-1]; # Filename is last element of the array.
				$Filename =~ m/([0-9]{3})/; # Find and extract the numeric portion of the filename.
				my $SolvID = $1+0; # Reference Solvent ID Number ($1) and convert text to numeric.
				my $SolvName = $Solvents{$SolvID}[0]; # Pull back the reference solvent's name.
				my $Gfus = Read_Gfus($File); # Extract the Gfus value from the file.
				$RefSolub{$SolvID}[3] = $Gfus; # Store the value of Gfus in RefSolub hash. Use position 3 of the array.
				LogMessage("MESSG: Gfus = $Gfus kcal/mol SolventID:$SolvID '$SolvName'", 3);
			} # END foreach loop.
		LogMessage("MESSG: Extracting Gfus Completed.", 1); 
	## END PERFORM THE REFERENCE SOLUBILITY CALCULATIONS IN COSMOTHERM ##
	if($debug == 1) { # Dump / export raw data in debug mode.
		open (TEST, ">VariableDump.txt");
		print TEST "############\nDump of \%RefSolub Variable.\n############\n\n";
		print TEST Dumper %RefSolub;
		close TEST;
	}
	## PERFORM SOLUBILITY CALCULATIONS BASED UPON Gfus DATA ##
		print "\tSolubility Calculations based upon Reference Solvent Gfus Data.\n";
		LogMessage("MESSG: Running Solubility Calculated Based upon Gfus Values.", 1); 
		mkdir "$CalcsDir/Select", 0777; # ERROR CAPTURE REQUIRED.
		my $cnt = 0; # A counter.
		my $cals = scalar(@RefSolubKeys)**2 - scalar(@RefSolubKeys);
		for (my $i = 0; $i < scalar(@RefSolubKeys); $i++) {
			my $CurrRefSolv = $RefSolubKeys[$i];
			my $Gfus = $RefSolub{$CurrRefSolv}[3];
			my @tmp = @RefSolubKeys;
			my $msg; # Holds an error message.
			splice @tmp, $i, 1;
			foreach $SelectSolv (@tmp) {
				$cnt++; # Increment counter.
				my $FN = sprintf("Sol%.3d%.3d", $CurrRefSolv, $SelectSolv); # Creates the appropriate filename.
				my $lognote = "[". sprintf("%3.d", $cnt)  .":". sprintf("%3.d", $cals) ."]  $FN.";
				print "\t\t$lognote\n"; # Inform user of progress.
				LogMessage("MESSG: Setting up $lognote", 3);
				open (FH_OUTPUT, ">$CalcsDir/Select/$FN.inp") or $msg = "Can't create INP file. $!. LINE:" . __LINE__;
				LogErrMessg($msg) if ($msg ne ""); # Handle the error.
				COSMO_Files ($ctd, $cdir, $ldir); # Add ctd parameters, directory and license locations.
				COSMO_Print(2); # Select Print options.
				COSMO_Comment(2, $SelectSolv, $CurrRefSolv); # Comment line.
				COSMO_Solute(2, $Solute, $Gfus); # Add Solute line(s) based upon the calculation option.
				COSMO_Solv($SelectSolv); # Add Solvent line(s).
				COSMO_Route(2); # Add Option 2 (Solubility) Routecard.
				close FH_OUTPUT;
				# Run/Submit Calculation.
					if($Cluster == 0) {
						COSMO_Submit(1); # COSMOtherm calculation run locally. (Will wait until calculation returns).
					}
					elsif($Cluster == 1) {
						COSMO_Submit(2); # COSMOtherm calculation submitted to cluster. (Moves on before calculations are complete).
					}
					else {
						# No calculations are run.  DEVELOPMENT.
					}
			} # END foreach loop.
		} # END for loop.
		print "\tProcess Data.\n\tAnalysis of Results:\n";
		$CurrCalcPath = "Calcs/Select/"; # Path to the calculations. SMARTEN UP
		# Find all of the TAB files.
			my @Files = <$CurrCalcPath*.tab>;
			@Files = sort @Files; # Ensure that the files are in ASCIIbetical order. So all of the reference solvents will be grouped together, then ordered by Select solvent.
		# Extract the Predicted Solublities:
			foreach my $i (@Files) {
				$i =~ m/(\d{3})/; # Identify the Reference solvent. First instance of three consecutive digits (this is the reference solvent).
				my $CurrRefSolv = $1 + 0; # Convert from 'text' to numerical value.
				my $Res = Read_Solub($i); # Extract the solubility from the TAB file.
				push ( @{$SelectSolub{$CurrRefSolv}}, $Res); # Place the extracted solubility into the SelectSolub hash.
			}
		if($debug == 1) { # Dump / export raw data in debug mode.
			open (TEST, ">>VariableDump.txt");
			print TEST "############\nDump of \%SelectSolub Variable.\n############\n\n";
			print TEST Dumper \%SelectSolub;
			close TEST;
			open (FH_DUMPER, ">Exported.txt") or die "Can' Export Data.";
			print FH_DUMPER "\t1\t2\t3\t4\t5\t6\t7\t8\t9\t10\t11\t12\t13\t14\t15\t16\t17\t18\n";
			print FH_DUMPER "\t19\t29\t30\t39\t41\t42\t50\t55\t61\t65\t66\t75\t80\t104\t108\t110\t116\t124\n";
			print FH_DUMPER "\t21.84\t4.28\t0.9\t44.37\t3.32\t2.34\t5.88\t3.75\t18.83\t38.55\t10.57\t6.36\t22.16\t1.6\t31.79\t0.15\t0.4\t35.64\n";
			print FH_DUMPER "RefSols\t@RefSols\n";
		}
		# Loop through all of the reference solvents in turn and calculate the Mean, Stdev and APScore of the Pred-Obs values.
			for (my $key = 0; $key < scalar(@RefSolubKeys); $key++) {
				print "\t\tReference Solvent: $RefSolubKeys[$key]\t";	
				print FH_DUMPER "Ref: $RefSolubKeys[$key]\n" if($debug ==1);	# Debug mode.
				# Extract all of the predicted solubilities, based upon the reference solvent.
					@CurrPredSol = @{$SelectSolub{$RefSolubKeys[$key]}};
					print FH_DUMPER "Predictions\t@CurrPredSol\n" if($debug ==1); # Debug mode.
				# Create an array of all of the LOG predicted solubilities.
					my @LogPredSol = @CurrPredSol;
					foreach my $i (@LogPredSol) {$i = log($i)} # Take logs.
						print FH_DUMPER "LogPredictions\t@LogPredSol\n" if($debug ==1); # Debug mode.
						my @CurrExpt = @RefSols;
						splice @CurrExpt, $key, 1;
						print FH_DUMPER "Expt\t@CurrExpt\n" if($debug ==1); # Debug mode.
						my @CurrLogExpt = @RefLogSols;
						splice @CurrLogExpt, $key, 1;
						print FH_DUMPER "LogExpt\t@CurrLogExpt\n" if($debug ==1); # Debug mode.
				# Calculate the Predicted - Experimental.
					my @DiffPredObs = map { $CurrLogExpt[$_] - $LogPredSol[$_] } 0 .. $#LogPredSol;
					print FH_DUMPER "PredvsObs\t@DiffPredObs\n\n" if($debug ==1); # Debug mode.
				# Calculate the Mean and Stdev.
					my $CurrMean = Mean(@DiffPredObs);
					my $CurrStdev = StDev(@DiffPredObs);
					my $CurrAPS = APScore($CurrMean, $CurrStdev);
					
					print "Mean = " . sprintf("%6.2f", $CurrMean) . "\t Stdev = ". sprintf("%5.2f", $CurrStdev)."\tAPS = " . sprintf("%5.3f", $CurrAPS) .
					"\tGfus = ". sprintf("%5.2f", $RefSolub{$RefSolubKeys[$key]}[3]) . " kcal/mol.\n";
					push @Means, $CurrMean;
					push @StDevs, $CurrStdev;
					push @APS, $CurrAPS;
			} # END for loop $key
			close FH_DUMPER if($debug ==1); # DEVELOPMENT.
		# Determine which is the best Reference Solvent.
			$Idx_Min = minindex(\@APS); # Determine the index in the array that contains the lowest APS.
			$BestSolv_ID = $RefSolubKeys[$Idx_Min];
			print "\tBest Reference Solvent is $Solvents{$BestSolv_ID}[1] ($BestSolv_ID)\n";
			LogMessage("MESSG: Best Reference Solvent: $Solvents{$BestSolv_ID}[1] ($BestSolv_ID", 1);
		if($debug == 1) { # Dump / export raw data in debug mode.
			open (TEST, ">>VariableDump.txt");
			print TEST "############\nDump of \@Means Variable.\n############\n\n";
			print TEST Dumper \@Means;
			print TEST "############\nDump of \@StDevs Variable.\n############\n\n";
			print TEST Dumper \@StDevs;
			print TEST "############\nDump of \@APS Variable.\n############\n\n";
			print TEST Dumper \@APS;
			close TEST;
		}

## PREDICTION OF SOLUBILITIES USING THE REFERENCE SOLVENT ##
	my $Ref_Gfus;
	my $Mean_Flag = 0;
	my $Select_ID = 0;
	if($Mean_Flag == 1) {
		# Use the mean Gfus value for the Prediction.
		my @Gfus;
		foreach my $i (@RefSolubKeys) {
			push @Gfus, $RefSolub{$i}[3];
		}
		$Ref_Gfus = Mean(@Gfus);
		print "\tAverage Gfus is: ". sprintf("%.2f", $Ref_Gfus) .".\n";  # sprintf this.
	}
	elsif($Select_ID != 0) {
		# Has a specific Solvent been requested for the Predictions?  Non-zero values of this variable will hold the Solvent ID to be used.
		# Check to see that the requested solvent ID is valid (have the appropriate calculations been run?
		if($Select_ID ~~ @RefSolubKeys) {
			# If the requested ID is Valid Solvent ID then set Gfus.
				$Ref_Gfus = $RefSolub{$Select_ID}[3];
				print "\tUsing User selected Solvent $Select_ID as the reference solvent. Gfus = ". sprintf("%.2f", $Ref_Gfus) .".\n";
		} else {
			# Report and error.
				print "\tError that Solvent can't be used!!!\n";
				exit;
		}
	}
	else {
		$Ref_Gfus = $RefSolub{$BestSolv_ID}[3];
		print "\tGfus for the best solvent is: ". sprintf("%.2f", $Ref_Gfus) .".\n"; # sprintf this.
	}
	
	mkdir "$CalcsDir/Pred", 0777; # ERROR capture required.
	# Ensure that the training solvents are also included in the Prediction set.
		@MergedSolvents = (@TestSolvents, @RefSolubKeys); # Merge the two solvent lists.
		my @seen;
		@seen{@TestSolvents} = ();
		@MergedSolvents = (@TestSolvents, grep{!exists $seen{$_}} @RefSolubKeys); # Exclude duplicates.
		@TestSolvents = sort { $a <=> $b } @MergedSolvents; # Numerical sort the new list of solvents.
	foreach my $PredSolv (@TestSolvents) {
		print "\tCurrent Solvent: $PredSolv\t";
		my $FN = sprintf("Pred%.3d", $PredSolv); # Creates the appropriate filename.
		print "$FN\n";
	#	my $lognote = "[". sprintf("%3.d", $cnt)  .":". sprintf("%3.d", $cals) ."]  $FN.";
	#	print "\t\t$lognote\n"; # Inform user of progress.
	#	LogMessage("MESSG: Setting up $lognote", 3);
		open (FH_OUTPUT, ">$CalcsDir/Pred/$FN.inp") or $msg = "Can't create INP file. $!. LINE:" . __LINE__;
		LogErrMessg($msg) if ($msg ne ""); # Handle the error.
		COSMO_Files ($ctd, $cdir, $ldir); # Add ctd parameters, directory and license locations.
		COSMO_Print(2); # Select Print options.
		COSMO_Comment(3, $PredSolv, $Ref_Gfus); # Comment line.
		COSMO_Solute(3, $Solute, $Ref_Gfus); # Add Solute line(s) based upon the calculation option.
		COSMO_Solv($PredSolv); # Add Solvent line(s).
		COSMO_Route(2); # Add Option 2 (Solubility) Routecard.
		close FH_OUTPUT;
	#	# Run/Submit Calculation.
	#		if($Cluster == 0) {
	#			COSMO_Submit(1); # COSMOtherm calculation run locally. (Will wait until calculation returns).
	#		}
	#		elsif($Cluster == 1) {
	#			COSMO_Submit(2); # COSMOtherm calculation submitted to cluster. (Moves on before calculations are complete).
	#		}
	#		else {
	#			# No calculations are run.  DEVELOPMENT.
	#		}
	} # END foreach loop.
	
	$CurrCalcPath = "Calcs/Pred/"; # Path to the calculations. SMARTEN UP
	# Find all of the TAB files.
		my @Files = <$CurrCalcPath*.tab>;
		my %PredSol; # This hash will hold the predicted solubilities - key is solvent ID.
		@Files = sort @Files; # Ensure that the files are in ASCIIbetical order.
		# Extract the Predicted Solublities:
			foreach my $i (@Files) {
				my $Res = Read_Solub($i); # Extract the solubility from the TAB file.
				print "\tSolubility is $Res from file $i\n";
				$i =~ m/(\d{3})/; # Identify the Reference solvent. First instance of three consecutive digits (this is the reference solvent).
				my $CurrSolv = $1 + 0; # Convert from 'text' to numerical value.
				$PredSol{$CurrSolv}[0] = $Res;
				# Convert the solubilities to mg/mL.
				$PredSol{$CurrSolv}[1] = Convgg2mgmL($CurrSolv, $Res, $DenOpt, $Temperature);
			}
	
	if($debug == 1) { # Dump / export raw data in debug mode.
			open (TEST, ">>VariableDump.txt");
			print TEST "############\nDump of \%PredSol Variable.\n############\n\n";
			print TEST Dumper \%PredSol;
			close TEST;
		}

		




#sleep(1);

## NORMAL TERMINATION ##
	{
	$scriptdur[1] = time();
	print "\n";
	Goodbye();
	my $msg = Duration($scriptdur[2]);
	LogMessage("SCRIPT COMPLETE. Duration = $msg", 1);
	close FH_LOG; # Close the log file.
	exit; # Catch all exit.
	}

### MAIN ROUTINE FINISHES HERE ###
	
### SUBROUTINES ###

## HELLO and GOODBYE ##

sub Hello {
	# Hello message for the user.
	print <<ENDHELLO;

		                      ( ~!~ ~!~ )
		.-----------------oOOo----(_)----oOOo--------------------------.
		|                                                              |
		|                   A Perl Script for:                         |
		|                                                              |
		| ..--**  **--.. |
		| ..--**  **--.. |
		|                                                              |
		|                      .oooO                                   |
		|                      (   )   Oooo.                           |
		.-----------------------\\ (----(   )---------------------------.
		                         \\_)    ) /
		                               (_/

		Script:  $scriptname
		Author:  $author.
		Version: $version ($versiondate).
			
ENDHELLO
TimeSalute(); # Print a meesage that's appropriate for the time of day.
print "\n\n";
} # END Hello()

sub Goodbye {
	# Say Goodbye to the user and inform them of the script duration.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: NONE.
		# Global Variables: @scriptdur.
	# (c) David Hose, February 2017.
	$scriptdur[2] = $scriptdur[1] - $scriptdur[0];
	my $runtime = Duration($scriptdur[2]);
	print <<ENDGOODBYE;
	Script completed. Goodbye $usr[2].
	Duration: $runtime.

ENDGOODBYE
} # END Goodbye()

sub Usage {
print <<ENDUSAGE;

		                       ..--** Solubility.pl **--..

	This script...

	Solubility.pl [--help]

	Switches:

		--help : This help page.
		
	See supporting documentation for further details.

ENDUSAGE
exit; # Exit.
} # END Usage()

sub User() {
	# Determines who the script user is (get login ID, Real name and first name).
		# Pass: NONE.
		# Return: NONE.
		# Dependences: NONE.
		# Global Variables: @usr
	# (c) David Hose. February 2017.
	@usr = ((getpwuid($<))[0], (getpwuid($<))[6]); # Store user's login ID and Real Name.
	$usr[1] =~ s/\./ /g; # Replace peroids in the real name if present.
	$usr[2] = (split(/\s/, $usr[1]))[0]; # Separate out the first name of the user.
} # END User()

sub Parser {
	# Parser to override some settings if required.
} # END Parser()

## LOG FILE RELATED ##

sub LogFileHeader {
	# Creates the header information in the log file.
		# Pass: NONE (Data is pulled from Global Level or Environment).
		# Return: NONE.
		# Dependences: LogTime(). use Cwd;
		# Global Variables: FH_LOG
	# (c) David Hose. March 2017.
	chomp(my $hostname = `hostname -s`);
	my $dir = getcwd();
	# Header section:
		print FH_LOG "GENERAL INFORMATION\n\n";
		print FH_LOG "Executed on ", LogTime(), "\n\n";
	# Script information:
		printf FH_LOG ("%-15s: %s\n", "Log File Name", $LogFileName); # The name of the logfile.
		printf FH_LOG ("%-15s: %s\n", "Perl Script", $scriptname); # The name of the script.
		#printf FH_LOG ("%-15s: %s\n", "Script Path", $scriptpath); # The path to the script. This needs modification for UNIX environ.
		printf FH_LOG ("%-15s: %s\n", "Primary Author", $author); # Primary author.
		printf FH_LOG ("%-15s: %s\n", "Version Author", $verauthor); # Version author.
		printf FH_LOG ("%-15s: %s (%s)\n\n", "Version", $version, $versiondate); # Version number and date of the script.
	# User and machine information:
		printf FH_LOG ("%-15s: %s\n", "User ID", $usr[0]); # User login ID.
		printf FH_LOG ("%-15s: %s\n", "User realname", $usr[1]); # User's realname.
		printf FH_LOG ("%-15s: %s\n", "Hostname", $hostname); # Machine's ID.
		printf FH_LOG ("%-15s: %s\n", "Data Path", $dir); # Working directory.
		print FH_LOG "\nDETAILS\n\n";
} # END LogFileHeader()

sub LogMessage {
	# Print a message to the log file depending upon the level of reporting required.
		# Pass:
			# $Message The message to be displayed in the log file.
			# $LogFlag The Message level [1 = Sparse/Errors, 2 = Normal and 3 = Verbose]
		# Return: Date / Time.
		# Dependences: NONE
		# Global Variables: $LogLevel
	# (c) David Hose. March 2017.
	# Variables:
		my $Message = $_[0];
		my $LogFlag = $_[1];
	print FH_LOG "", TimeNow(2), " : $Message\n" if ($LogFlag <= $LogLevel);
} # END LogMessage()

sub LogErrMessg {
	# Reports an error message to both screen and LogFile.
		# Pass: Error Message.
		# Return: NONE.
		# Dependences: LogMessage().
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
	my $msg = $_[0];
	LogMessage("ERROR: $msg", 1); # Print error to the LogFile.
	print "ERROR: $msg\nTerminating script.\n\n";
	exit; # Hard exit.
} # END LogErrMessg()

## TIME RELATED FUNCTIONS ##

sub LogTime {
	# Generates a current date and time message ["YYYY/MM/DD at HH:MM:SS"].
		# Pass: NONE
		# Return: Date / Time.
		# Dependences: NONE
		# Global Variables: NONE
	# (c) David Hose. March 2017.
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $Time =  sprintf("%4d/%02d/%02d at %02d:%02d:%02d", ($year+1900), $mon, $mday, $hour, $min, $sec);
		return ($Time);
} # END LogTime()

sub TimeNow {
	# Returns the current time in either HH:MM or HH:MM:SS format.
		# Pass: Time option
		# Return: Time in appropriate format.
		# Dependences: LogMessage()
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
			# Pass:
			# $_[0] The required format option. 1 = HH:MM, 2 = HH:MM:SS.
		# Variables:
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		# Sub:
			if($_[0] == 1) {
				return(join(':', sprintf("%02d", $hour), sprintf("%02d", $min)));
			} elsif ($_[0] == 2) {
				return(join(':', sprintf("%02d", $hour), sprintf("%02d", $min), sprintf("%02d", $sec)));
			} else {
				LogMessage("ERROR: TimeNow(). Invalid Option requested ($_[0]).", 1);
			}
			exit; # Catch All exit.
} # END TimeNow()

sub Duration {
	# Calculates the elapsed time in a more human readable form from the number of seconds that have been passed to the routine.
		# Pass: Number of seconds.
		# Return: $Time (duration in human form)
		# Dependences: LogMessage()
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
		# Variables:
			my ($DayLabel, $HourLabel, $MinuteLabel, $SecondLabel);
			my $secs = shift; # Number of seconds to be processed.
			my $Short = shift; # Short format = 0 (abbreviated d, hr(s), min(s) and sec(s)), long format = 1 (days, hours, minutes and seconds).
	# Determine the number of complete days, hours, minutes and seconds.
		my $NumDays = int($secs/(24*60*60));
		my $NumHours = int($secs/(60*60))%24;
		my $NumMinutes = ($secs/60)%60;
		my $NumSeconds = $secs%60;
	# Determine correct pluralisation for the days, hours, minutes and seconds.
		if($Short == 1) {
			# Long format.
				if($NumDays == 1) {$DayLabel = "day"} else {$DayLabel = "days"};
				if($NumHours == 1) {$HourLabel = "hour"} else {$HourLabel = "hours"};
				if($NumMinutes == 1) {$MinuteLabel = "minute"} else {$MinuteLabel = "minutes"};
				if($NumSeconds == 1) {$SecondLabel = "second"} else {$SecondLabel = "seconds"};
		} else {
			# Short format.
				if($NumDays == 1) {$DayLabel = "d"} else {$DayLabel = "d"};
				if($NumHours == 1) {$HourLabel = "hr"} else {$HourLabel = "hrs"};
				if($NumMinutes == 1) {$MinuteLabel = "min"} else {$MinuteLabel = "mins"};
				if($NumSeconds == 1) {$SecondLabel = "sec"} else {$SecondLabel = "secs"};
		}
	if ($NumDays != 0) {
		# Quote the time as Day(s), Hour(s) and Minute(s).
			$Time = sprintf("%d %s %d %s and %d %s", $NumDays, $DayLabel, $NumHours, $HourLabel, $NumMinutes, $MinuteLabel);
	}
	if ($NumDays == 0 && $NumHours != 0) {
		# Quote the time as Hour(s) and Minute(s).
			$Time = sprintf("%d %s and %d %s", $NumHours, $HourLabel, $NumMinutes, $MinuteLabel);
	}
	if ($NumDays == 0 && $NumHours == 0 && $NumMinutes != 0) {
		# Quote the time as Minute(s) and Second(s).
			$Time = sprintf("%d %s and %d %s", $NumMinutes, $MinuteLabel, $NumSeconds, $SecondLabel);
	}
	if ($NumDays == 0 && $NumHours == 0 && $NumMinutes == 0 && $NumSeconds != 0) {
		# Quote the time as Seconds.
			$Time = sprintf("%d %s", $NumSeconds, $SecondLabel);
	}
	if ($NumDays == 0 && $NumHours == 0 && $NumMinutes == 0 && $NumSeconds == 0) {
		# Quote the time as Seconds.
			$Time = "Less than 1 second";
	}
	return($Time);
} # END of Duration().

sub TimeSalute {
	# Create a message based upon the time of day.
		# Pass: NONE
		# Return: $TimeMsg (A greeting).
		# Dependences: NONE.
		# Global Variables: $usr[2].
	# (c) David Hose. March 2017.
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $TimeMsg;
	# Work out the period of the day.
		if($hour >= 7 && $hour < 8) {$TimeMsg = "A very early morning $usr[2]."}
		elsif($hour >= 8 && $hour < 12) {$TimeMsg = "Good morning $usr[2]."}
		elsif($hour >= 12 && $hour < 18) {$TimeMsg = "Good afternoon $usr[2]."}
		elsif($hour >= 18 && $hour < 20) {$TimeMsg = "Good evening $usr[2]."}
		else {$TimeMsg = "Weird time of day $usr[2]!"}
	# Add any special messages.
		if($wday ~~ [0,6]) {$TimeMsg = $TimeMsg . " Why are you working at the weekend? Do I need to email your manager?!"}
		if($wday == 1 && $hour >= 7 && $hour < 12) {$TimeMsg = $TimeMsg . " Don't you just hate Monday mornings!"}
		if($wday == 5 && $hour >= 12 && $hour < 16) {$TimeMsg = $TimeMsg . " It's POETS day!"}
		if($wday == 5 && $hour >= 16) {$TimeMsg = $TimeMsg . " It's Friday night! GO HOME!"}
	print "\t$TimeMsg"; # Output the message.
} # END TimeSalute()

## COSMOtherm RELATED ##

sub COSMOthermInstalled {
	# Check that the cosmologic directory is present in APPS directory. If not, prompt user to load the COSMOtherm module.
		# Pass: NONE.
		# Return: NONE.
		# Dependances: LogMessage(), Usage().
		# Global Variables: $appsdir
	# (c) David Hose. March 2017.
	# Variables:
		my $Flag = 0; # A flag.
		my $msg; # An error message.
	LogMessage("ENTER: COSMOthermInstalled()", 2);
	opendir(DIR, $appsdir) or $msg = "Can't open the APPS directory '$appsdir'. $!. LINE:". __LINE__;
	LogErrMessg($msg) if ($msg ne ""); # Handle the error.
	while (my $entry = readdir(DIR)) {
		next unless (-d "$appsdir/$entry"); # Only check for directories.
		$Flag = 1 if($entry eq "cosmologic"); # If the 'cosmologic' directory is found, set the flag.
	}
	closedir (DIR);
	# No 'cosmologic' directory?  Prompt user to load the module and exit.
		if($Flag == 0) {
			print "\nThe COSMOtherm module hasn't been loaded.\nPlease load COSMOtherm module and re-run script.\n\n";
			LogMessage("ERROR: COSMOtherm hasn't been Installed.", 1);
			LogMessage("Leave: COSMOthermInstalled() via Usage()", 2);
			Usage();
			exit; # Catch All exit.
		}
	LogMessage("LEAVE: COSMOthermInstalled()", 2);
} # END COSMOthermInstalled()

sub YearVersions {
	# Determines the year versions of COSMOtherm that are available.
	# Scan the directories in the cosmologic directory and determine the version years from the names.
		# Pass: NONE.
		# Return: @YearList
		# Dependences: LogMessage()
		# Global Variables: $cosmologicdir
	# (c) David Hose. March 2017.
	# Variables:
		my $msg; # An error message.
		my @YearList; # Holds the list of years found (reverse chronological order).
		my $Flag = 0;
	# Sub:
		LogMessage("ENTER: YearVersions()",2);
		opendir(DIR, $cosmologicdir) or $msg = "Can't open directory '$cosmologicdir'. $!. LINE:". __LINE__;
		LogErrMessg($msg) if ($msg ne ""); # Handle the error.
		while (my $file = readdir(DIR)) {
			next unless (-d "$cosmologicdir/$file"); # Only check for directories.
			next unless ($file =~ m/COSMOthermX/); # Only check for 'COSMOthermX## directories.
			$file =~ s/COSMOthermX//g; # Remove the 'COSMOthermX' portion of the filename to leave the year.
			push @YearList, $file; # Populate the YearList with the years found.
		}
		closedir (DIR);
		@YearList = reverse(sort @YearList); # Place the years into reverse chronological order.
		LogMessage("PARAM: Available COSMOtherm years: @YearList", 2);
		LogMessage("LEAVE: YearVersions()",2);
		return(@YearList); # Returns all years available in reverse chronological order.
} # END YearVersions()

sub CTD_Path {
	# Formally sets AppYear and ParamYear, as well as the Parametermisation file location.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: $AppYear, cdir, $ldir, $ctd, $cosmodbpath
	# (c) David Hose. March 2017.
	LogMessage("ENTER: CTD_Path()", 2);
	# Determine if the chosen COSMOtherm application year is available.
		# If choice year is 'default' use the most recent application year that has been loaded.
			$AppYear = $Years[0] if ($AppYear =~ /^Default/i);
		# Is the selected application year available?
			if($AppYear ~~ @Years) {
				LogMessage("PARAM: COSMOtherm Year is 20$AppYear.", 3);
			} else {
				my $msg = "ERROR: Application Year (20$AppYear) is not available.";
				LogMessage("$msg", 1);
				print "$msg\n";
				LogMessage("LEAVE: CTD_Path() via Usage().", 1);
				Usage(); # Gracefully terminate via Usage and add comment to the log.
			} # END if($AppYear ~~ @Years).
		# Set the Application Year directory.
			$cdir = $cosmologicdir . "/COSMOthermX$AppYear/COSMOtherm/CTDATA-FILES"; # CTD file path.
			$ldir = $cosmologicdir . "/COSMOthermX$AppYear/licensefiles/"; # Location of the license file.
	# Determine if the parameterisation year is appropriate and set up the correct path and name of the parameterisation file.
		# If the choice year is 'default' set Parameterisation year.
			$ParamYear = $AppYear if($ParamYear =~ /^Default/i);
		# Set Path and Filename depending upon Application and Parameterisation years.
		# If the parameter year starts with a non-digit, assume that this defines the name of a special parameterisation file.
			if($ParamYear =~ /^\D/) {
			$ctd = "$ParamYear";
			} else {
				# Catch an inappropriate Application/Parameterisation year combination.
					if($AppYear < $ParamYear) {
						my $msg = "Can't run parameters (20$ParamYear) that are newer than the Application (20$AppYear)";
						print "$msg\n";
						LogMessage("ERROR: $msg", 1);
						LogMessage("LEAVE: CTD_Path() via Usage()", 1);
						Usage(); # Gracefully terminate via Usage and add comment to the log.
					}
				# Add OLDPARAM directory sub-level.
					$cdir = $cdir . "/OLDPARAM" if($AppYear > $ParamYear);
				if($ParamYear <= $Years[0] && $ParamYear >= 12) {	
					# Known special cases (2012 and 2013 have the 2012 HB terms added).
						if($ParamYear == 12 || $ParamYear == 13) {$ctd = "BP_TZVPD_FINE_HB2012_C30_". $ParamYear ."01.ctd"}
					# General cases.
						if($ParamYear <= $Years[0] && $ParamYear >= 14) {$ctd = "BP_TZVPD_FINE_C30_" . $ParamYear . "01.ctd"}
				} else {
					my $msg = "Sorry there are no parameterisation files available for the year 20$ParamYear (2012 - 20$Years[0]).";
					print "$msg\n";
					LogMessage("ERROR: $msg", 1);
					LogMessage("LEAVE: CTD_Path() via Usage()", 1);
					Usage(); # Gracefully terminate via Usage and add comment to the log.
				}
			}
		######
		# Correctly determine the path to the COSMOtherm compound database.
			$cosmodbpath=0;
		######
	LogMessage("PARAM: License file path: $ldir", 2);
	LogMessage("PARAM: Parameterisation path: $cdir", 2);
	LogMessage("PARAM: Parameterisation file: $ctd", 2);
	LogMessage("LEAVE: CTD_Path()", 2);
} # END CTD_Path().

sub COSMO_Files {
	# Writes the appropriate COSMOtherm calculation parameter levels to the current filehandle FH_OUTPUT.
		# Pass:
			# $ctd hold the name of the COSMOtherm parameter file to be used.
			# $cdir Sets the directory where to search for the COSMOtherm parameter file. Default is to search in the current working directory.
				# The directory name must not contain blank spaces unless it is given in quotes.
			# $license holds the location of the license file.
		# Reference: COSMOtherm User Manual C30_1601.
		# Return:
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT, $ctd, $cdir, $license
	# Variables:
		my ($ctd, $cdir, $license) = @_;
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT
	# (c) David Hose. March 2017.
	# Sub:
		LogMessage("ENTER: COSMO_Files()", 3);
		# Check that the correct number of parameters has been passed.
			if(scalar(@_) != 3) {
				my $ErrMsg = "ERROR: COSMO_Files() Invalid number of parameters passed (" . scalar(@_) . ").";
				LogMessage($ErrMsg , 1);
				print "$ErrMsg\n";
				exit;
			}
		# Print file location line:
			print FH_OUTPUT "ctd = $ctd "; # Parametermisation.
			print FH_OUTPUT "cdir = \"$cdir\" "; # Parameterisation directory.
			print FH_OUTPUT "LDIR = \"$license\" "; # License file directory.
			print FH_OUTPUT "\n"; # EoL.
		LogMessage("LEAVE: COSMO_Files()", 3);
} # END COSMO_Files()

sub COSMO_Print {
	# Writes the appropriate COSMOtherm print options to the current filehandle FH_OUTPUT.
	# The option switch allows predefined print options to be used (intended to extendable for future versions).
		# Pass:
			# $_[0] The Optional Print commands to be included.
	# The print options are:
		# notempty: Print “NA” (Not Available) message to the name.tab table output file if empty table entries occur. By default an empty table entry is filled with blank spaces only.
		# wtln: Print full compound and/or molecule names to all tables in the name.tab table output file and the name.mom sigma-moments file.
			# By default the compound/molecule names are cropped after 20 characters.
		# VPfile: COSMOtherm automatically searches for the vapor pressure/property files for all molecules given in the compound input section.
			# The vapor pressure/property files are expected to be of the form name.vap, where name is the name derived from the according COSMO file as given in the compound input section.
		# EHfile: COSMOtherm automatically searches for the or gas phase energy files for all molecules given in the compound input section.
			# EHfile The gas phase energy files are expected to be of the form name.energy, or where name is the name from the according COSMO file (name.cosmo).
			# The energies are expected in units of hartrees.
			# By default the current working directory is searched, if the fdir command is used, the according path given by fdir is searched.
		# Reference: COSMOtherm User Manual C30_1601.
	# Options: (The if statements are to be modified in future versions).
		# 1 = Default (notempty wtln VPfile EHfile).
		# 2 = NOT Defined.
	# Return: NONE.
	# Dependences: LogMessage()
	# Global Variables: FH_OUTPUT
	# (c) David Hose. March 2017.
	# Variables:
		my $Options = $_[0];
		my $MaxOpts = 2; # Set this to the maximum number of options available (Change fo future expansions of options).
	# Sub:
		LogMessage("ENTER: COSMO_Print()", 3);
		# Check that the correct number of parameters has been passed.
		if(scalar(@_) != 1) {
				my $ErrMsg = "ERROR: COSMO_Print() Invalid number of parameters passed (" . scalar(@_) . ").";
				LogMessage($ErrMsg, 1);
				print "$ErrMsg\n";
				exit;
			}
		# Check that Option choice is valid.
			if($Options < 1 || $Options > $MaxOpts) {
				my $ErrMsg = "ERROR: COSMO_Print() Invalid Option value passed ($Options).";
				LogMessage($ErrMsg, 1);
				print "$ErrMsg\n";
				exit;
			}
	# Print selected options to current filehandle:
		if($Options ~~ [1,2]) {print FH_OUTPUT " unit"}
		if($Options ~~ [1,2]) {print FH_OUTPUT " notempty"}
		if($Options ~~ [1,2]) {print FH_OUTPUT " wtln"}
		if($Options ~~ [1,2]) {print FH_OUTPUT " ndgf"}
		if($Options ~~ [1,2]) {print FH_OUTPUT " ehfile"}
		if($Options ~~ [1]) {print FH_OUTPUT " long"}
		if($Options ~~ [3]) {print FH_OUTPUT " Boogie"}
		# Expansion of options: List the option numbers within the [] brackets.
			if($Options ~~ [1,2,3]) {}
		print FH_OUTPUT " \n"; # EoL.
		LogMessage("LEAVE: COSMO_Print()", 3);
} # END COSMO_Print()

sub COSMO_Comment {
	# Writes the appropriate Comment line to the current filehandle FH_OUTPUT.
		# Pass: Option number, Solvent number , Reference Solvent Number.
		# Options: 1: Gfus Calculations. 2: Selection Calculations. 3: NOT DEFINED (intended for future versions).
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT
	# (c) David Hose, March 2017.
	# Sub:
		LogMessage("ENTER: COSMO_Comment()", 3);
		# Option 1 (DGfus Calculaions):
			if($_[0] == 1) {
				LogMessage("MESSG: COSMO_Comment Option 1 (Gfus Calculation) selected.", 3);
				if(scalar(@_) < 2) {
					my $ErrMes = "ERROR: COSMO_Comment(). Not enough parameters passed for Option 1.";
					LogMessage($ErrMes, 1);
					print "$ErrMes\n";
					exit;
				}
				my $SolventName = $Solvents{$_[1]}[0];
				print FH_OUTPUT "!! Calculation of Gfus of $Compound in $SolventName (ID:$_[1]). !!\n";
			} # END of Option 1.
		# Option 2 (Selection).
			if($_[0] == 2) {
				LogMessage("MESSG: COSMO_Comment Option 2 (Selection Calcs) selected.", 3);
				if(scalar(@_) < 3) {
					my $ErrMes = "ERROR: COSMO_Comment(). Not enough parameters passed for Option 2.";
					LogMessage($ErrMes, 1);
					print "$ErrMes\n";
					exit;
				}
				print FH_OUTPUT "!! Solubility Calculation of Solute in Solvent \#$_[1] using Solvent \#$_[2] as reference. !!\n";
			} # END of Option 2.
		# Option 3 (Prediction).
			if($_[0] == 3) {
				LogMessage("MESSG: COSMO_Comment Option 3 (Prediction Calcs) selected.", 3);
				if(scalar(@_) < 3) {
					my $ErrMes = "ERROR: COSMO_Comment(). Not enough parameters passed for Option 3.";
					LogMessage($ErrMes, 1);
					print "$ErrMes\n";
					exit;
				}
				print FH_OUTPUT "!! Solubility Calculation of Solute in Solvent \#$_[1] using Gfus = $_[2] kcal/mol. !!\n";
			} # END of Option 2.
} # END COSMO_Comment()


sub COSMO_Solute {
	# Writes the solute path/filename information to the current COSMOtherm INP file.
		# Pass: Option, Solute path/name, [Gfus, Hfus, Tmelt] (latter 3 are optional dpending upon option).
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variable: NONE.
	# (c) David Hose. March 2017.
	LogMessage("ENTER: COSMO_Solute()", 1);
	my ($Opt, $Solute, $DGfus, $DHfus, $Tmelt) = @_;
	if($Opt == 1) {
		# Option 1: Write solute line 'as-is'.
			print FH_OUTPUT "$Solute";
			LogMessage("LEAVE: COSMO_Solute()", 1);
			return;	
	} # END Option 1.
	elsif($Opt == 2 || $Opt == 3) {
		# Options 2 and 3: Write solute with DGfus etc values.
			my @Temp = split(/\[/, $Solute); # Split the solute.
			my $Props = "[ ";
			if($DGfus eq "") {
				my $msg = "ERROR: No Gfus Value available. LINE:" . __LINE__;
				print "$msg\n";
				LogMessage("$msg", 1);
				exit;
			} else {
				$Props = $Props . " VPfile DGfus = $DGfus ";
				LogMessage("PARAM: Gfus = $DGfus", 3);
			}
		if($DHfus ne "" && $Tmelt ne "") {
			$Props = $Props . " DHfus = $DHfus TMELT_K = $Tmelt ";
			LogMessage("PARAM: Hfus = $DHfus", 3);
			LogMessage("PARAM: TMelt = $Tmelt", 3);
		}
		my $Temp = join("", $Temp[0], $Props, $Temp[1]);
		print FH_OUTPUT "$Temp";
		LogMessage("LEAVE: COSMO_Solute()", 1);
		return;
	} # END Options 2 and 3.
	elsif($Opt == 4) {
		# For expansion...
		LogMessage("LEAVE: COSMO_Solute()", 1);
		return;
	} # END Option 4.
	else {
		my $msg = "ERROR: INVALID OPTION.";
				print "$msg\n";
				LogMessage("$msg", 1);
				exit;
	}
} # END COSMO_Solute()

sub COSMO_Solv {
	# 
		# Pass: Solvent ID.
		# Return: Solvent Path/filename.
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT
	# (c) David Hose. March 2017.
		LogMessage("ENTER: Read_Solv()", 1); # Log file message.
		$Solv_ID = $_[0]; # Pick up the solvent number ID.
		@Data = @{$Solvents{$Solv_ID}}; # Pull out COSMOtherm solvent data from the Solvent Hash.
		$Subdir = lc(substr($Data[1], 0, 1));	# Grab the first character of the name (of sub-folder) and ensures that it's in lower case.
		if($Data[6] == 4) {$fdir=$COSMO_DB[0]} else {$fdir=$COSMO_DB[1]} # Select the correct database.
		# For a single conformer solvent.
			if ($Data[7] == 1) {
				print FH_OUTPUT "f = $Data[1]_c0.$Data[5] fdir=\"$fdir/$Subdir\" VPfile DGfus = 0 \n";
			}
		# For a multiple conformer solvent.
			if ($Data[7] > 1) {
				print FH_OUTPUT "f = $Data[1]_c0.$Data[5] fdir=\"$fdir/$Subdir\" Comp = $Data[1] [ VPfile DGfus = 0 \n";
				for ($conf = 1; $conf < ($Data[7] - 1); $conf++) {
					print FH_OUTPUT "f = $Data[1]_c$conf.$Data[5] fdir=\"$fdir/$Subdir\"\n"
				}
				$lastconf = $conf;
				print FH_OUTPUT "f = $Data[1]_c$lastconf.$Data[5] fdir=\"$fdir/$Subdir\" ]\n";
			} 
		LogMessage("PARAM: Solvent #$Solv_ID '$Data[0]'",3);
		LogMessage("MESSG: DB: $fdir",3);
		LogMessage("MESSG: Conformers: $Data[7]",3);
		#LogMessage("",3);
		LogMessage("LEAVE: Read_Solv()", 1);
		return;
} # END Select_Solv()

sub COSMO_Route {
	# Writes a COSMOtherm Routecard depending upon the option selected.
		# Pass: Option.
			# Option 1: Gfus Calculation. ref_sol_g value required for the solvent/solute combination, and Texp for the measurement.
			# Option 2: 
			# Option 3: 
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT, see options above.
	# (c) David Hose. March 2017.
	LogMessage("ENTER: COSMO_Route()", 3);
	my $Opt = $_[0];
	if($Opt == 1) {
		# Option 1: Gfus calculation.
		LogMessage("MESSG: Routecard 1: Gfus Calculation.", 3);
		LogMessage("PARAM: Temperature: $TExpt_C C. Ref_Sol: $Curr_Ref_Solub g/g.", 3);
		print FH_OUTPUT "solub=2 WSOL2 solute=1 tc=$TExpt_C ref_sol_g=$Curr_Ref_Solub \n";
	}
	elsif($Opt == 2 || $Opt == 3) {
		# Options 2 and 3:
		LogMessage("MESSG: Routecard $Opt selected.", 3);
		print FH_OUTPUT "solub=2 tc=$TExpt_C Iterative \n"
	}
	elsif($Opt == 4) {
		# Option 4: For expansion...
		LogMessage("MESSG: Routecard 4 selected.", 3);
	}
	else {
		LogMessage("ERROR: No valid Route option selected.", 1);
		exit;
	}
	LogMessage("LEAVE: COSMO_Route()", 3);
	return;
} # END COSMO_Route()

sub COSMO_Submit {
	# This subroute controls how and where the COSMOtherm Calculation is run (LOCAL vs CLUSTER).
	print ""; # DUMMY!
}

sub Read_Gfus {
	# Extracts the Gfus value from file.
		# Pass: Filename to be opened.
		# Return: Gfus value.
		# Dependences: NONE.
		# Global Varaibles: NONE.
	# (c) David Hose. February 2017.
	my $FN = $_[0];
	my $msg; # Holds an error message.
	my $Gfus; # Holds the free energy of fusion value.
	open (FH_GFUS_READ, "<$FN") or $msg = "Can't open Gfus File. $!. LINE:" . __LINE__; # Open the Gfus calculation file.
	LogErrMessg($msg) if ($msg ne ""); # Handle the error.
	while(<FH_GFUS_READ>) {
	# Find the line containing the solute (Compound Number 1).
		if($_ =~ /^\s{3}1\s\S/i) {
			my @temp = split(/\s+/, $_);
			$Gfus = $temp[6];
			last; # Skip rest of file.
		}
	} # END FH_GFUS_READ while loop.
	close FH_GFUS_READ; # Close the input file.
	return $Gfus;
} # END Read_Gfus()

sub Read_Solub {
	# Extracts the Solubility value from file.
		# Pass: Filename to be opened.
		# Return: Solubility value.
		# Dependences: NONE.
		# Global Varaibles: NONE.
	# (c) David Hose. February 2017.
	my $FN = $_[0];
	my $Solub; # Holds the free energy of fusion value.
	my $msg; # Holds an error message.
	open (FH_SOLUB_READ, "<$FN") or $msg = "Can't open. $!. LINE:" . __LINE__; # Open the Solubility calculation file.
	LogErrMessg($msg) if ($msg ne ""); # Handle the error.
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

## R RELATED ##

sub RInstalled {
	# Checks that R has been installed.
		# Pass: NONE.
		# Return: NONE:
		# Depences: LogMessage().
		# Global Variables: $appsdir
	# (c) David Hose. March 2017.
	my $Flag = 0; # A flag.
	my $msg; # An error message.
	LogMessage("ENTER: RInstalled()", 2);
	opendir(DIR, $appsdir) or $msg = "Can't open the APPS directory '$appsdir'. $!. LINE:". __LINE__;
	LogErrMessg($msg) if ($msg ne ""); # Handle the error.
	while (my $entry = readdir(DIR)) {
		next unless (-d "$appsdir/$entry"); # Only check for directories.
		$Flag = 1 if($entry eq "R"); # If the 'R' directory is found, set the flag.
	}
	closedir (DIR);
	# No 'R' directory?  Prompt user to load the module and exit.
		if($Flag == 0) {
			print "\nThe R module hasn't been loaded.\nPlease load R module and re-run script.\n\n";
			LogMessage("ERROR: R hasn't been Installed.", 1);
			LogMessage("Leave: RInstalled() via Usage()", 2);
			Usage();
			exit; # Catch All exit.
		}
	LogMessage("LEAVE: RInstalled()", 2);
} # END RInstalled().


## READ AND SET UP DATA TABLES ##

sub CTRL_Read {
	# Reads in data from the Control File (Application Year, Paramaterisations and Temperature).
		# Pass: NONE
		# Return: NONE
		# Dependences: LogMessage()
		# Global Variables: $CTRLFileName, $AppYear., $ParamYear, $Temperature
	# (c) David Hose. March 2017.
		LogMessage("ENTER: CTRL_Read()", 2);
		my $msg; # An error message.
		# Open Control File.
			open (FH_CTRL, "<", $CTRLFileName) or $msg = "Can't open Control File '$CTRLFileName'. $!. LINE:". __LINE__;
			LogErrMessg($msg) if ($msg ne ""); # Handle the error.
		# Read in contents of control file.
			while (<FH_CTRL>) {
				chomp;
				$Line = $_;
				@temp = split(/\t/, $_);
				if($Line =~ /^COSMOtherm/) {
					# What is the requested COSMOtherm Year based upon the COSMOtherm version?
						$AppYear = lc $temp[1];
				} # END 'Version' if.
				if($Line =~ /^Parameters/) {
					# What is the requested Parameterisation Year?
						$ParamYear = lc $temp[1];
				} # END 'Version' if.
				if($Line =~ /^Temperature/) {
					# What is the temperature of the reference solubility measurements and hence the temperature for the predictions?
						# Check that the temperature value is appropriate (e.g. it is a number and is within a reasonable range).
							# Check that it's a number.
								if ($temp[1] =~ /\d+|\d+.\d+/) {
									# Check that the temperature is in a reasonable range.  Expecting temperatures to be in degC, thus temperature less than 100.
										if($temp[1] > 100) {
											$msg = "ERROR: Temperature entered is greater than 100.  Expecting temperature in degC";
											LogMessage("$msg", 1);
											print "$msg\n";
											LogMessage("LEAVE: CTRL_Read() via Usage().", 1);
											Usage(); # Controlled exit.
										}		
								$TExpt_C = $temp[1];
								} else {
									$msg = "ERROR: No numerical value entered for the temperature!";
											LogMessage("$msg", 1);
											print "$msg\n";
											LogMessage("LEAVE: CTRL_Read() via Usage().", 1);
											Usage(); # Controlled exit.
								}
				} # END 'Temperature' if.
			} # END while loop over FH_CTRL.
	close FH_CTRL; # Close the Control File.
	LogMessage("PARAM: COSMOtherm Year $AppYear.", 3);
	LogMessage("PARAM: Parameterisation $ParamYear", 3);
	LogMessage("PARAM: Temperature $TExpt_C degC.", 3);
	LogMessage("LEAVE: CTRL_Read()", 2);
} # END CTRL_Read().

sub Read_Solv_Data {
	# This subroutine open the Master Solvent File, extracts solvent cosmo file locations,
	# solvent density and physical properities.  A set of hash variables are populated.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: LogMessage().
		# Global Variables: $netpath, $Solvent_Data, %Solvents, %Densities and %SolventProps.
	# (c) David Hose. February 2017.
		my $msg; # Holds an error message.
		LogMessage("ENTER: Read_Solv_Data()", 2);
		open (FH_SOLV, "<" . $netpath . "/" . $SolvData) or $msg = "Can't Open Solvent Data '$SolvData'. $!. LINE:". __LINE__; # Open Solvent Master Data File.
		LogErrMessg($msg) if ($msg ne ""); # Handle the error.
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
		LogMessage("LEAVE: Read_Solv_Data()");
} # END Read_Solv_Data()

sub Read_Project {
	# Reads in the Project information and sets appropriate variables.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: $ProjectFileName, $ProjectName, $Compound, $AltName and $Client.
	# (c) David Hose. February 2017.
	my $msg; # Holds an error message.
		LogMessage("ENTER: Read_Project()", 2);
		open (FH_PROJ, "<", $ProjectFileName) or $msg = "Can't open Project File '$ProjectFileName'. $!. LINE:". __LINE__; # Open Project File.
		LogErrMessg($msg) if ($msg ne ""); # Handle the error.
	# Read in contents of control file.
		while (<FH_PROJ>) {
			chomp;
			my @temp = split(/\t/, $_);
				if($_ =~ /^Project/) {
					# What is the name of the Project (AZDxxxx)?
						# Check that the Project name ID of the form 'AZDxxxx' where x are digits.
						if($_ =~ /azd\d{4}$/i) {
							$ProjectName = uc $temp[1]; # Ensure that it's in uppercase.
						} else {
							# Not an AZDxxxx project name (e.g. iENaC). Use the same case as written in the Project file.
							$ProjectName = $temp[1];
						}
				} # END 'Project' if.
				if($_ =~ /^Compound/) {
					# What is the name of the compound (AZxxxxxxxx)?  Only AZ numbers are valid.
						if($_ =~ /AZ\d{8}$/) {
							$Compound = uc $temp[1]; # Ensure that it's in uppercase.
						} else {
							my $msg = "Invalid AZ number entered (\"$temp[1]\") Using default name of 'NULL'.";
							print "$msg\n";
							LogMessage("MESSG: $msg", 3);
							$Compound = NULL;
						}
				} # END 'Compound' if.
				if($_ =~ /^Alternative/) {
					# What is the alterative name of the compound?  Especially important if there is no valid AZ number.
						$AltName = $temp[1];
						if($temp[1] eq "") {$AltName = "NA"}
				} # END 'Alternative' if.
				if($_ =~ /^Client/) {
					# What is the Client's name?
						if($temp[1] eq "") {
							# No name has been entered.
								my $msg = "No client name entered.  Using a default name of 'Test'.";
								print "$msg\n";
								LogMessage("MESSG: $msg", 3);
								$Client = "Test";
						} else {
							$temp[1] =~ s/(\w+)/\u\L$1/g; # Ensure that the client's name is appropriately capitalised.
							$Client = $temp[1];
						}
				} # END 'Client' if.
		} # END FH_PROJ while loop.
		close FH_PROJ; # Close Project File.
		# Log file messages:
			LogMessage("PARAM: Project: $ProjectName", 3);
			LogMessage("PARAM: Compound: $Compound", 3);
			LogMessage("PARAM: Alternative Name: $AltName", 3);
			LogMessage("PARAM: Client: $Client", 3);
			LogMessage("LEAVE: Read_Project()", 2);
} # END Read_Project()

sub Read_RefSol_Data {
	# Reads in the Reference solubilities.
		# Pass: NONE.
		# Return: The number of reference solvent solubilities that has been read in.
		# Dependences: NObs(), Mean() and StDev().
		# Global Variables: $RefSolFileName and @RefSolub.
	# (c) David Hose. February 2017.
	my $msg; # Error message.
	my @tmp; # Temporary array.
	my $RefSolNum = 0; # Tracks the row numnber of the array and hence number of solubility measurements.
	LogMessage("ENTER: Read_RefSol_Data()", 3);
	open (FH_REFSOL, "<", $RefSolFileName) or $msg = "Can't open Reference Solubility File. $!. LINE:". __LINE__; # Open Reference Solubility File.
	LogErrMessg($msg) if ($msg ne ""); # Handle the error.
	# Read in contents of control file.
		REF_LOOP:	while(<FH_REFSOL>) {
						next REF_LOOP if($_ =~ /^\W/); # Skip header (header starts line with text and not a number).
						chomp;
						@tmp = split(/\t/, $_);
						# Is there any valid data to be used?  If not read next line.
							# $tmp[1] holds the Solvent ID number. If it is blank or hold none digit data, therefore no solvent ID. Skip line.
								next REF_LOOP if($tmp[1] eq "" || $tmp[1] =~ /^\D+/); # 
							# $temp[2] holds the Solubility Value. If it contains either blanks "" or "NA", then there is no solubility data.  Skip line.
								next REF_LOOP if(($tmp[2] eq "" || $tmp[2] =~ /na/i));
						# Build the Reference Solubility Data for this solvent's measurements.
							my $Key = $tmp[1]; # Key the hash for the Solvent ID number.
							$RefSolub{$Key}[0] = $tmp[2]; # The average solubility value (mg/mL) supplied by Simon.
							$RefSolub{$Key}[1] = ConvmgmL2gg($tmp[1], $tmp[2], $DenOpt, $Temperature); # The solubility value (g/g).
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
		LogMessage("LEAVE: Read_RefSol_Data()", 3);
		return ($RefSolNum); # Returns the number of reference solvents found.
} # END Read_RefSol_Data()

sub Read_Solutes {
	# Extracts the solutes from a COSMOtherm list file.
		# Pass: Name of the COSMOtherm list file.
		# Return: An array of the solutes.
		# Dependences: LogMessage()
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
	my $File = $_[0];
	my $Line;				# Holds the current line that has been read in from the Solute list file.
	my @SOLUTES;			# This holds of the solutes file and path information.
	my $SoluteCnt = 0;		# This counts the number of SOLUTES.
	my $ConformerCnt = 0;	# This counts the number of conformers for a specific SOLUTE.
	my $FirstConformer;		# Hold file and path information about the first conformer of a SOLUTE.
	my $SoluteTempArray;	# A temp array.
	my $msg; # Holds an error message.
	LogMessage("ENTER: Read_Solutes()", 1); # Comments for LogFile.
	open (FH_SOLUTE, "<$File") or $msg = "Can't open the Solute list file '$File', $! LINE:" . __LINE__; # Open the solute list file.
	LogErrMessg($msg) if ($msg ne ""); # Handle the error.
	# Loop through the lines of the file.
		SOLUTELINE: while(<FH_SOLUTE>) {
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
	LogMessage("PARAM: $SOLUTES[0]", 3); # Only the first entry is important (this sub routine was written with a more general purpose).
	LogMessage("LEAVE: Read_Solutes()", 1); # Comment for LogFile.
	return(@SOLUTES);
} # END Read_Solutes()

sub Read_Solvents {
	# Reads in a list of Solvent ID's for which the solubility of the solute is to be predicted in.
		# Pass: Filename.
		# Return: Solvent List.
		# Dependences:
		# Global Variables:
	# (c) David Hose. March 2017.
		my $FN = $_[0]; # The filename of the list of solvents that solubility predictions have to be made.
		my $msg; # Holds an error message.
		my $str; # Holds the string of Solvent IDs. (form 1,2,5-10,115,...).
		my @tmp; # Temp array to process the string.
		my @Solvents; # This will hold the list of Solvent IDs to be returned.
		LogMessage("ENTER: Read_Pred_Solv()", 1);
		open (FH_SOLLIST, "<$SolventFile") or $msg = "Can't open Solvent List '$FN'. $! LINE:" . __LINE__;
		LogErrMessg($msg) if ($msg ne ""); # Handle the error.
		# Create a single line string of the Solvent ID numbers separated by commas (the solvents could be listed over multiple lines).
		while (<FH_SOLLIST>) {
			chomp;
			$str = "$str,$_";
		}
		close FH_SOLLIST;
	# Case 1 - "ALL" available Solvents are to be run.
		if($str =~ /^,all/i) {$str = "1-9,11-91,93-272"} # This should exclude those solvents that don't have TZVPD-Fine cosmo files.
	# Case 2 - Immiscible Solvents.
		if($str =~ /^,immisc/i) {
			$str = "1, 3, 4, 6, 7, 11, 14, 15, 18-26, 31-48, 50-55, 59, 60, 62-64, 66-68, 73, 74, 75, 81-84, 88-90, 92-96, 100-102, 104-106, 109-113, 117, 118, 122, 124, 125, 128-130, 132-137, 140-146, 154, 156, 158-161, 163, 165-170, 177-188, 190, 192-216, 218-221, 223, 224, 226, 230-232, 234, 236-243, 246, 264-269, 270, 272";
		} # CHECK for compounds that don't have TZVPD-Fine cosmo files.
	# Case 3 - Miscible Solvents.
		if($str =~ /^,misc/i) {
			$str = "2, 5, 8, 9, 12, 13, 16, 27-30, 49, 56, 58, 61, 65, 69, 70-72, 76-80, 85-87, 97-99, 103, 107, 108, 114-116, 119-121, 123, 126, 127, 131, 138, 147-150, 155, 157, 162, 164, 171, 172, 176, 189, 191, 217, 227-229, 233, 235, 244, 254, 260";
		} # CHECK for compounds that don't have TZVPD-Fine cosmo files.
	# Case 4 - General case & process the strings created by Cases 1 - 3..
		$str =~ s/\s//g; # Remove spaces ', '.
		@tmp = split(/,/, $str); # Split string by commas.
		# Loop through each element of @Temp looking for 'digit(s)-digit(s)' format that indicates a range. (9-14 means {9, 10, 11, 12, 13, 14}).
			foreach $i (@tmp) {
				if ($i =~ /\d+\-\d+/) {
					my $seq = "";
					$i =~ m/(\d+)\-(\d+)/;
					for ($j = $1; $j <= $2; $j++) {$seq = "$seq,$j"}
					$i = $seq; # Overwrite the current element with the required sequence.
				}	
			} # END foreach loop.
		$str = join(",", @tmp); # Rejoin the elements together (to integrate the new sequence(s)).
		@Solvents = split(/,/, $str); # Split string by commas.
		@Solvents = grep { $_ ne '' } @Solvents; # Remove any blank elements which might be present.
		@Solvents = sort { $a <=> $b } (@Solvents); # Sort the solvent IDs numerically.
		LogMessage("LEAVE: Read_Pred_Solv()", 1);
		return (@Solvents);
} # END Read_Pred_Solv()




## SOLUBILITY AND DENSITY CALCULATIONS ##

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

sub Convgg2RV {
	# Convert solubility from g per g to relative volumes.
		# Pass: Solubility in g/g, Solvent ID and Temperature..
		# Return: Solubility in RV.
		# Dependences: GetSolRho().
		# Global Variables:
	# (c) David Hose. March 2017.
	my ($Sol, $ID, $Temp) = @_;
	my $rho = GetSolRho($ID, $Temp);
	my $RV = ($Sol**-1)/$rho;
	return($RV);
} # END Convgg2RV()

sub GetSolRho {
	# Pulls back the density of the solvent based upon ID and temperature.
		# Pass: Solvent ID and Temperature (degC).
		# Return: Density (g/mL).
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

sub SolubClass {
	# Determines the USP solubility class.
		# Pass: Solubility in mL per g.
		# Return: ClassText and ClassNum.
		# Dependences: NONE.
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
	my @Class;
	if($_[0] < 1) 							{@Class = ("Very Soluble", 1)}
	elsif($_[0] >=    1 && $_[0] <    10)	{@Class = ("Free Soluble", 2)}
	elsif($_[0] >=   10 && $_[0] <    30)	{@Class = ("Soluble", 3)}
	elsif($_[0] >=   30 && $_[0] <   100)	{@Class = ("Sparingly Soluble", 4)}
	elsif($_[0] >=  100 && $_[0] <  1000)	{@Class = ("Slightly Soluble", 5)}
	elsif($_[0] >= 1000 && $_[0] < 10000)	{@Class = ("Very Slightly Soluble", 6)}
	else 									{@Class = ("Insoluble", 7)}
	return(@Class);
} # END SolubClass()







## STATISTICAL & MISC CALCULATIONS ##

sub NObs {
	# Determine the number of values in the array.
		# Pass: An array of numbers.
		# Return: Number entries in the array.
		# Dependences: NONE.
		# Global Variables: NONE.
	# (c) David Hose, February 2017.
		my $nobs = scalar(@_);
} # END NObs()

sub Mean {
	# Calculate the mean.
		# Pass: An array of numbers.
		# Return: The mean.
		# Dependences: NObs()
		# Global Variables: NONE.
	# (c) David Hose, February 2017.
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
	# (c) David Hose, February 2017.
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

sub APScore {
	# Predefined weighting values (for tuning).
			my $WtA = 1.0;		# Weighting to be given to the accuracy (mean).
			my $WtP = 1.0;		# Weighting to be given to the precision (spread).
			my $APScore = sqrt(($WtA*$_[0])**2 + ($WtP*$_[1])**2);
			return $APScore;
} # END APScore()

sub minindex {
	# Determine the index of the array that contains the lowest value.
	  my( $aref, $idx_min ) = ( shift, 0 );
	  $aref->[$idx_min] < $aref->[$_] or $idx_min = $_ for 1 .. $#{$aref};
	  return $idx_min;
}

### END OF SCRIPT ###
