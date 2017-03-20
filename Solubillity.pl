#! /usr/bin/perl

# Perl script to process measured solubilities, determine the best reference solvent, and then run a series of predictions.

BEGIN { $| = 1 }	# Turn on autoflush for STDOUT.
my $debug = 1; # DEVELOPMENT ONLY.
my $LiveRun = 0; # DEVELOPMENT ONLY.  Set 1 for running the COSMOtherm Calculations.  Ensure COSMOtherm module has been loaded for the current terminal session.

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
			my @Temp = split(/\//, $0);
			my $scriptname = $Temp[-1]; # Pulls the name of the script from perl's special variables.
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
			my $CTRLFileName = "control.dat";				# DEVELOPMENT DEFAULT. # Control file. (Application and Parameter years, and temperature.
			my $ProjectFileName = "project.dat";			# DEVELOPMENT DEFAULT. # Project Information file.
			my $SoluteFileName = "Solubility_Test.list";	# DEVELOPMENT DEFAULT. # Solute List.

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
				# The following is a temporary solution.
				$COSMO_DB[0] = "/apps/cosmologic/COSMOthermX16/COSMOtherm/DATABASE-COSMO/BP-TZVPD-FINE"; # Points to the COSMOlogic database (AUTOMATE THIS)
				$COSMO_DB[1] = "/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE"; # Points to the AZ database.
			
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
			my $TExpt_C;	# The temperature of the solubility measurement.
			my $RefSolFileName = "refsolvsolub.dat";	# Holds the filename that contains the solubility information.
			my @RefSolub; 	# 2D Array that holds the reference solubility data.  This data will be in mg/mL.
			my $RefSolNum;	# Holds the number of reference solvent solubilities.
			my $CalcsDir = "Calcs";
			my $Solute; # Holds the name of the solute.
			
			my $Curr_Ref_Solub;
		

### MAIN ROUTINE STARTS HERE ###
	## INITIALISATION ##
		# This section of code:
			# Welcomes the User,
			# Starts a LogFile running,
			# Checks COSMOtherm is loaded,
			# Loads the Control parameters (setting appropriate paths),
			# Loads the Project information and
			# Reads in Solvent Properties.
	{
		$scriptdur[0] = time(); # Note start time.
		User(); # Determine who's running the script (for reports and personalisation).
		Hello(); # Welcome User.
		print "\tStarting Log file: $LogFileName\n";
		# Start log file.
			open (FH_LOG, ">$LogFileName") or die "Can't open the Log File $!"; # Open the log file.
			LogFileHeader(); # Write general details of the script to the log file.
			LogMessage("STARTING SCRIPT", 1);
			LogMessage("Initialiation", 1);
		print "\tConfirm COSMOtherm installed...";
		COSMOthermInstalled(); # Check that COSMOtherm is installed if not exit.
		@Years = YearVersions(); # Determine the Year codes of the available COSMOtherm versions.
		print "DONE.\n";
		print "\tRead Control Parameters '$CTRLFileName'...";
		CTRL_Read(); # Read in CONTROL Parameters (Application Year, Parameterisation, and Temperature).
		print "DONE.\n";
		print "\tCOSMOtherm Directory Locations...";
		CTD_Path(); # Formally set Application Year (numerical) and Parametermisation.  Defines Parameter and License files locations.
		print "DONE.\n";
		print "\tRead Master Solvent Data '$SolvData'...";
		Read_Solv_Data(); # Read in Master Solvent Data.
		print "DONE.\n";
		print "\tRead Project Information '$ProjectFileName'...";
		Read_Project(); # Read in Project Information.
		print "DONE.\n";
		print "\tRead Solute File '$SoluteFileName'...";
		$Solute = (Read_Solutes($SoluteFileName))[0]; # An array is returned (future codes).  Only the first element is required.
		print "DONE.\n";
	} # END ## INITIALISATION ##
	## REFERENCE SOLUBILITY DATA ##
		# This section of code:
			# Reads in the experimental reference solubility information.
	{
		print "\tRead Experimental Reference Solvent Solubility Data '$RefSolFileName'...";
		$RefSolNum = Read_RefSol_Data();
		print "DONE.\n";
	}## END REFERENCE SOLUBILITY DATA ##
	## PERFORM THE REFERENCE SOLUBILITY CALCULATIONS IN COSMOTHERM ##
		# This section of code...
			# Creates the Calculation Directory and Reference Subdirectory.
	{
	LogMessage("Starting Gfus Calculations.", 1);
		print "";
		# Make a directory to store all of the calculations.
			mkdir "$CalcsDir", 0777;
		# Make a subdirectory for the references calculations.
			mkdir "$CalcsDir/Ref", 0777;
		# For each of the solvents for which there is a reference solubility measurement, set up calculations...
		
		# Get the solvent numbers.
			my @RefSolvsID;
			for(my $i=0; $i< $RefSolNum; $i++) {$RefSolvsID[$i] = $RefSolub[$i][1]} # Pull back the reference solvent IDs.
		# Loop through the list of solvents and deterine the DGfus values.
		print "\tFree-Energy of Fusion Calculations.\n";
		foreach my $CurrSolv (@RefSolvsID) {
			$CurrFile = sprintf("Gfus%.3d", $CurrSolv);
			$CurrSolvName = ${$Solvents{$CurrSolv}}[0];
			print "\t\tFile: $CurrFile\tReference Solvent: '$CurrSolvName'.\n";
			open (FH_OUTPUT, ">$CalcsDir/Ref/$CurrFile.inp") or die "Can't open Reference Calculation File. $!\n";
			# Write ctd line.
			COSMO_Files ($ctd, $cdir, $ldir); # Add ctd parameters, directory and license locations.
			COSMO_Print(1); # Gfus Print options.
			COSMO_Comment(1, $CurrSolv);
			COSMO_Solute(1,$Solute);
			COSMO_Solv($CurrSolv);
			
			$Curr_Ref_Solub = 0.10000001;
			
			COSMO_Route(1);
			close FH_OUTPUT; # Close the Current Reference Solvent COSMOtherm .INP file.
		
		
		
		
		
		
		
		
		
		
		} # END foreach loop for @RefSolvsID.
		
	LogMessage("Ending Gfus Calculations.", 1);
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
		                         \\_)     ) /
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
	# (c) David Hose, Feb 2017.
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
	# (c) David Hose. Feb 2017.
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
	# (c) David Hose. March, 2017.
	# Variables:
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
	# (c) David Hose. March, 2017.
	# Variables:
		my $Message = $_[0];
		my $LogFlag = $_[1];
	print FH_LOG "", TimeNow(2), " : $Message\n" if ($LogFlag <= $LogLevel);
} # END LogMessage()

## TIME RELATED FUNCTIONS ##

sub LogTime {
	# Generates a current date and time message ["YYYY/MM/DD at HH:MM:SS"].
		# Pass: NONE
		# Return: Date / Time.
		# Dependences: NONE
		# Global Variables: NONE
	# (c) David Hose. March, 2017.
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
	# (c) David Hose. March, 2017.
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
	# (c) David Hose. March, 2017.
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
	# Work out the peroid of the day.
		if($hour >= 7 && $hour < 8) {$TimeMsg = "A very early morning $usr[2]."}
		elsif($hour >= 8 && $hour < 12) {$TimeMsg = "Good morning $usr[2]."}
		elsif($hour >= 12 && $hour < 18) {$TimeMsg = "Good afternoon $usr[2]."}
		elsif($hour >= 18 && $hour < 20) {$TimeMsg = "Good evening $usr[2]."}
		else {$TimeMsg = "Weird time of day $usr[2]!"}
	# Add any special messages.
		if($wday >= 6) {$TimeMsg = $TimeMsg . " Why are you working at the weekend? Do I need to email your manager?!"}
		if($wday == 1 && $hour >= 7 && $hour < 12) {$TimeMsg = $TimeMsg . " Don't you just hate Monday mornings!"}
		if($wday == 5 && $hour >= 12 && $hour < 16) {$TimeMsg = $TimeMsg . " It's POETS day!"}
		if($wday == 5 && $hour >= 16) {$TimeMsg = $TimeMsg . " It's Friday night! GO HOME!"}
	# Output the message.
		print "$TimeMsg";
} # END TimeSalute()

## COSMOtherm RELATED ##

sub COSMOthermInstalled {
	# Check that the cosmologic directory is present in APPS directory. If not, prompt user to load the COSMOtherm module.
		# Pass: NONE.
		# Return: NONE.
		# Dependances: LogMessage(), Usage().
		# Global Variables: $appsdir
	# (c) David Hose. March, 2017.
	# Variables:
		my $Flag = 0; # A flag.
		my $msg; # An error message.
	LogMessage("Enter: COSMOthermInstalled()", 2);
	opendir(DIR, $appsdir) or $msg = "Can't open the APPS directory '$appsdir'. $!. LINE:". __LINE__;
	if($msg ne "") {
		LogMessage("ERROR: $msg", 1);
		print "$msg\n";
		exit;
	}
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
	LogMessage("Leave: COSMOthermInstalled()", 2);
} # END COSMOthermInstalled()

sub YearVersions {
	# Determines the year versions of COSMOtherm that are available.
	# Scan the directories in the cosmologic directory and determine the version years from the names.
		# Pass: NONE.
		# Return: @YearList
		# Dependences: LogMessage()
		# Global Variables: $cosmologicdir
	# (c) David Hose. March, 2017.
	# Variables:
		my $msg; # An error message.
		my @YearList; # Holds the list of years found (reverse chronological order).
		my $Flag = 0;
	# Sub:
		LogMessage("Enter: YearVersions()",2);
		opendir(DIR, $cosmologicdir) or $msg = "Can't open directory '$cosmologicdir'. $!. LINE:". __LINE__;
		if($msg ne "") {
			LogMessage("ERROR: $msg\n", 1);
			print "$msg";
			exit;
		}
		while (my $file = readdir(DIR)) {
			next unless (-d "$cosmologicdir/$file"); # Only check for directories.
			next unless ($file =~ m/COSMOthermX/); # Only check for 'COSMOthermX## directories.
			$file =~ s/COSMOthermX//g; # Remove the 'COSMOthermX' portion of the filename to leave the year.
			push @YearList, $file; # Populate the YearList with the years found.
		}
		closedir (DIR);
		@YearList = reverse(sort @YearList); # Place the years into reverse chronological order.
		LogMessage("PARAM: Available COSMOtherm years: @YearList", 2);
		LogMessage("Leave: YearVersions()",2);
		return(@YearList); # Returns all years available in reverse chronological order.
} # END YearVersions()

sub CTD_Path {
	# Formally sets AppYear and ParamYear, as well as the Parametermisation file location.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: $AppYear, cdir, $ldir, $ctd, $cosmodbpath
	# (c) David Hose. March, 2017.
	LogMessage("Enter: CTD_Path()", 2);
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
				LogMessage("Leave: CTD_Path() via Usage().", 1);
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
						LogMessage("Leave: CTD_Path() via Usage()", 1);
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
					LogMessage("Leave: CTD_Path() via Usage()", 1);
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
	LogMessage("Leave: CTD_Path()", 2);
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
		LogMessage("Enter: COSMO_Files()", 3);
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
		LogMessage("Leave: COSMO_Files()", 3);
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
		LogMessage("Enter: COSMO_Print()", 3);
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
		if($Options ~~ [1]) {print FH_OUTPUT " unit"}
		if($Options ~~ [1]) {print FH_OUTPUT " notempty"}
		if($Options ~~ [1]) {print FH_OUTPUT " wtln"}
		if($Options ~~ [1]) {print FH_OUTPUT " ndgf"}
		if($Options ~~ [1]) {print FH_OUTPUT " EHfile"}
		if($Options ~~ [1]) {print FH_OUTPUT " long"}
		if($Options ~~ [2]) {print FH_OUTPUT " Boogie"}
		# Expansion of options: List the option numbers within the [] brackets.
			if($Options ~~ [1,2,3]) {}
		print FH_OUTPUT " \n"; # EoL.
		LogMessage("Leave: COSMO_Print()", 3);
} # END COSMO_Print()

sub COSMO_Comment {
	# Writes the appropriate Comment line to the current filehandle FH_OUTPUT.
		# Pass: Option number, Solvent number.
		# Options: 1: Gfus Calculations. 2: 3: NOT DEFINED (intended for future versions).
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: FH_OUTPUT
	# (c) David Hose, March 2017.
	# Sub:
		LogMessage("Enter: COSMO_Comment()", 3);
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
		# Option 2 (Partition Calculation of Solute between Solvent-Water).
			if($_[0] == 2) {
				LogMessage("MESSG: COSMO_Comment Option 2 (Partition Calcs) selected.", 3);
				if(scalar(@_) < 2) {
					my $ErrMes = "ERROR: COSMO_Comment(). Not enough parameters passed for Option 2.";
					LogMessage($ErrMes, 1);
					print "$ErrMes\n";
					exit;
				}
				print FH_OUTPUT "!! Partition Coefficient Calculations of SOLUTE(S) between $_[1] and water. !!\n";
			} # END of Option 2.
		LogMessage("Leave: COSMO_Comment()", 3);
} # END COSMO_Comment()

sub COSMO_Solute {
	# Writes the solute path/filename information to the current COSMOtherm INP file.
		# Pass: Option, Solute path/name, [Gfus, Hfus, Tmelt] (latter 3 are optional dpending upon option).
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variable: NONE.
	# (c) David Hose. March 2017.
	LogMessage("Enter: COSMO_Solute()", 1);
	my ($Opt, $Solute, $DGfus, $DHfus, $Tmelt) = @_;
	if($Opt == 1) {
		# Option 1: Write solute line 'as-is'.
			print FH_OUTPUT "$Solute";
			LogMessage("Leave: COSMO_Solute()", 1);
			return;	
	} # END Option 1.
	elsif($Opt == 2) {
		# Option 2: Write solute with DGfus etc values.
			my @Temp = split(/\[/, $str); # Split the solute.
			my $Props = "[ ";
			if($DGfus eq "") {
				my $msg = "ERROR: No Gfus Value available. LINE:" . __LINE__;
				print "$msg\n";
				LogMessage("$msg", 1);
				exit;
			} else {
				$Props = $Props . " DGfus = $DGfus ";
				LogMessage("PARAM: Gfus = $DGfus", 3);
			}
		if($DHfus ne "" && $Tmelt ne "") {
			$Props = $Props . " DHfus = $DHfus TMELT_K = $Tmelt ";
			LogMessage("PARAM: Hfus = $DHfus", 3);
			LogMessage("PARAM: TMelt = $Tmelt", 3);
		}
		my $Temp = join("", $Temp[0], $Props, $Temp[1]);
		print FH_OUTPUT "$Temp";
		LogMessage("Leave: COSMO_Solute()", 1);
		return;
	} # END Option 2.
	elsif($Opt == 3) {
		LogMessage("Leave: COSMO_Solute()", 1);
		return;
	} # END Option 3.
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
		LogMessage("Enter: Read_Solv()", 1); # Log file message.
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
		LogMessage("Enter: Read_Solv()", 1);
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
	LogMessage("Enter: COSMO_Route()", 3);
	my $Opt = $_[0];
	if($Opt == 1) {
		# Option 1: Gfus calculation.
		LogMessage("MESSG: Routecard 1: Gfus Calculation.", 3);
		LogMessage("PARAM: Temperature: $TExpt_C C. Ref_Sol: $Curr_Ref_Solub g/g.", 3);
		print FH_OUTPUT "solub=2 WSOL2 solute=1 tc=$TExpt_C ref_sol_g=$Curr_Ref_Solub \n";
	}
	elsif($Opt == 2) {
		# Option 2:
		LogMessage("MESSG: Routecard 2 selected.", 3);
	}
	elsif($Opt == 3) {
		# Option 3:
		LogMessage("MESSG: Routecard 3 selected.", 3);
	}
	else {
		LogMessage("ERROR: No valid Route option selected.", 1);
		exit;
	}
	LogMessage("Leave: COSMO_Route()", 3);
	return;
} # END COSMO_Route()










## READ AND SET UP DATA TABLES ##

sub CTRL_Read {
	# Reads in data from the Control File (Application Year, Paramaterisations and Temperature).
		# Pass: NONE
		# Return: NONE
		# Dependences: LogMessage()
		# Global Variables: $CTRLFileName, $AppYear., $ParamYear, $Temperature
	# (c) David Hose. March, 2017.
		LogMessage("Enter: CTRL_Read()", 2);
		my $msg; # An error message.
		# Open Control File.
			open (FH_CTRL, "<", $CTRLFileName) or $msg = "Can't open Control File '$CTRLFileName'. $!. LINE:". __LINE__;
			if($msg ne "") {
				LogMessage("ERROR: $msg\n", 1);
				print "$msg";
				exit;
			}
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
											LogMessage("Leave: CTRL_Read() via Usage().", 1);
											Usage(); # Controlled exit.
										}		
								$TExpt_C = $temp[1];
								} else {
									$msg = "ERROR: No numerical value entered for the temperature!";
											LogMessage("$msg", 1);
											print "$msg\n";
											LogMessage("Leave: CTRL_Read() via Usage().", 1);
											Usage(); # Controlled exit.
								}
				} # END 'Temperature' if.
			} # END while loop over FH_CTRL.
	close FH_CTRL; # Close the Control File.
	LogMessage("PARAM: COSMOtherm Year $AppYear.", 3);
	LogMessage("PARAM: Parameterisation $ParamYear", 3);
	LogMessage("PARAM: Temperature $Temperature degC.", 3);
	LogMessage("Leave: CTRL_Read()", 2);
} # END CTRL_Read().

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

sub Read_Project {
	# Reads in the Project information and sets appropriate variables.
		# Pass: NONE.
		# Return: NONE.
		# Dependences: LogMessage()
		# Global Variables: $ProjectFileName, $ProjectName, $Compound, $AltName and $Client.
	# (c) David Hose. Feb 2017.
	my $msg; # An error message.
		LogMessage("Enter: Read_Project()", 2);
		open (FH_PROJ, "<", $ProjectFileName) or $msg = "Can't open Project File '$ProjectFileName'. $!. LINE:". __LINE__; # Open Project File.
			if($msg ne "") {
				LogMessage("ERROR: $msg\n", 1);
				print "$msg";
				exit;
			}
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
			LogMessage("Leave: Read_Project()", 2);
} # END Read_Project()

sub Read_RefSol_Data {
	# Reads in the Reference solubilities.
		# Pass: NONE.
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
								$RefSolub[$RefSolNum][7] = StDev(@Sol) / Mean(@Sol); # Relative standard deviation.
								$RefSolub[$RefSolNum][8] = ConvmgmL2gg($temp[1], $RefSolub[$RefSolNum][5], $DenOpt, $Temperature);;
							$RefSolNum++; # Increment row counter.
		} # END while loop over FH_REFSOL.
		close FH_REFSOL; # Close Reference Solubility File.
		return $RefSolNum; # Returns the number of reference solvents solubilities.
} # END Read_RefSol_Data()

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
	my $msg; # An error message.
	# Comments for LogFile.
		LogMessage("Enter: Read_Solutes.", 1);
		LogMessage("Opening Solute File '$File'",3);
	open (FH_SOLUTE, "<$File") or die "Can't open the Solute list file '$File', $! LINE:" . __LINE__ . "\n"; # Open the solute list file.
	if($msg ne "") {
		LogMessage("ERROR: $msg", 1);
		print "$msg\n";
		exit;
	}
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

## STATISTICAL CALCULATIONS ##

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

### END OF SCRIPT ###