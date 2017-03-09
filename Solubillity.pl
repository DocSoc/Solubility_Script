#! /usr/bin/perl

# Perl script to process measured solubilities, determine the best reference solvent and then run a series of predictions.

BEGIN { $| = 1 }	# Turn on autoflush for STDOUT.
my $debug = 1; # Development only.

# Load any required packages:
	if($debug == 1) {use Data::Dumper qw(Dumper)} # Load the Data Dumper for checking data structures of complex variables.
	use Cwd;
	use File::Path;

### Variables: ###
	## Script Information.
			$author = "David Hose";
			$version = "0.1a";
			$versiondate = "Mar 2017";
			$scriptname = $0; # Pulls the name of the script from perl's special variables. 
			$scriptname =~ s/.\///; # Cleans up the name by removing './'.
	## Key file locations:
		## Network files (Key master files).
			my $netpath = "/projects/PharmDev/COSMOtherm/Ref_Solubility/Master_Data"; # Provisional location.
			$netpath = "Master_Data"; # DEVELOPMENT LOCATION.
			my $SolvData = "Solvents.txt";
			
		## Data files for the script to work with.
			# Control file. (Application and Parameter years, and temperature.
				my $CTRLFileName = "control.dat"; # DEVELOPMENT DEFAULT.
			# Project Information file.
				my $ProjectFileName = "project.dat";
		
			
		## Applications Directory.
			my $appsdir = "/apps"; # Points to applications directory (UNIX environment).
			$appsdir = "apps"; # DEVELOPMENT LOCATION.
			my $cosmologicdir = "$appsdir/cosmologic"; # Points to the cosmologic directory within the application directory (UNIX environment).
			
	
	## Log file settings.
		my $LogFileName = join('', "SolLog-", time(), ".log"); # Log file name (only use a limited number of digits).
		$LogFileName = join('', "SolLog-", "000001" , ".log"); # DEVELOPMENT. REMOVE IN PRODUCTION.
		$LogLevel = 3; # 1 = Sparse, 2 = Normal and 3 = Verbose. (Allow this to be set by the Parser!!!)
		

	## General variables:
		# Misc:
			my @usr; # Holds ID information about the user
			my @scriptdur; # Holds the start, end and duration times of the script.
		# COSMOtherm related variables:
			# General:
				my $AppYear; # Holds the Application Year (COSMOtherm version).
				my $ParamYear; # Holds the Parameterisation Year (COSMOtherm parameterisation).
				my @Years; # Holds the available COSMOtherm application versions.
				my $cdir; # Holds the path and name of the required CTD file (Used by COSMOtherm).
				my $ctd; # Holds the name of the required CTD file (Used by COSMOtherm).
				my $ldir; # Holds the path of the license file (Used by COSMOtherm).
			# COSMOtherm Database location Variables.
			
		# Project related variables:
			my $ProjectName; # Project Name (AZDxxxx or pre-nomination name).
			my $Compound; # AZxxxxxxxx name.
			my $AltName; # Alternative compound name (trivial name).
			my $Client; # Name of the client who requested the work.
		
		# Solvent Properties 'Database' variables:
			my %Solvents; # This hash holds all of the solvent cosmo file locations (key = Solvent ID).
			my %Densities; # This hash holds all of the solvent density information (key = Solvent ID).
			my %SolventProps; # This hash holds all of the solvent properties information (key = Solvent ID).

		

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
		# Start log file.
			open (FH_LOG, ">$LogFileName") or die "Can't open the Log File $!"; # Open the log file.
			LogFileHeader(); # Write general details of the script to the log file.
			LogMessage("STARTING SCRIPT", 1);
			LogMessage("Initialiation", 1);
		COSMOthermInstalled(); # Check that COSMOtherm is installed if not exit.
		@Years = YearVersions(); # Determine the Year codes of the available COSMOtherm versions.
		CTRL_Read(); # Read in CONTROL Parameters (Application Year, Parameterisation, and Temperature).
		CTD_Path(); # Formally set Application Year (numerical) and Parametermisation.  Defines Parameter and License files locations.
		Read_Solv_Data(); # Read in Master Solvent Data.
		Read_Project(); # Read in Project Information.
	} # END ## INITIALISATION ##
	## REFERENCE SOLUBILITY DATA ##
		# This section of code:
			#
	{
		
		print "";
		
		
		
	}## END REFERENCE SOLUBILITY DATA ##



	## NORMAL TERMINATION ##
		$scriptdur[1] = time();
		Goodbye();
		LogMessage("SCRIPT COMPLETE", 1);
		close FH_LOG; # Close the log file.
		exit;

### MAIN ROUTINE FINISHES HERE ###
	
### SUBROUTINES ###

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

			Hello $usr[2].  Welcome back.
			
ENDHELLO
} # END Hello()

sub Goodbye {
	# Say Goodbye.
	$scriptdur[2] = $scriptdur[1] - $scriptdur[0];
	print <<ENDGOODBYE;
	Script completed. Goodbye $usr[2].
	Duration: $scriptdur[2] seconds.
	

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
exit;
}

sub User() {
	# Determines how the script user is.
		@usr = ((getpwuid($<))[0], (getpwuid($<))[6]); # Store user's login ID and Real Name.
		$usr[1] =~ s/\./ /g; # Replace peroids in the real name if present.
		$usr[2] = (split(/\s/, $usr[1]))[0]; # Separate out the first name of the user.
} # END User()

## LOG FILE RELATED ##

sub LogFileHeader {
	# Creates the header information in the log file.
		# Pass: NONE (Data is pulled from Global Level or Environment).
		# Return: NONE.
		# Dependences: LogTime().
		# Variables:
			chomp(my $hostname = `hostname -s`);
			my $dir = getcwd();
			my $username = getpwuid($<);
		# Sub:
			# Header section:
				print FH_LOG "GENERAL INFORMATION\n\n";
				print FH_LOG "Executed on ", LogTime(), "\n\n";
			# Script information:
				printf FH_LOG ("%-14s: %s\n", "Log File Name", $LogFileName); # The name of the logfile.
				printf FH_LOG ("%-14s: %s\n", "Perl Script", $scriptname); # The name of the script.
				printf FH_LOG ("%-14s: %s\n", "Author", $author); # Script author.
				printf FH_LOG ("%-14s: %s (%s)\n\n", "Version", $version, $versiondate); # Version number and date of the script.
			# User and machine information:
				printf FH_LOG ("%-14s: %s\n", "User ID", $usr[0]); # User login ID.
				printf FH_LOG ("%-14s: %s\n", "User realname", $usr[1]); # User's realname.
				printf FH_LOG ("%-14s: %s\n", "Hostname", $hostname); # Machine's ID.
				printf FH_LOG ("%-14s: %s\n", "Path", $dir); # Working directory.
				print FH_LOG "\nDETAILS\n\n";
} # END LogFileHeader()

sub LogMessage {
	# Print a message to the log file depending upon the level of reporting required.
		# Pass:
			# $Message The message to be displayed in the log file.
			# $LogFlag The Message level [1 = Sparse/Errors, 2 = Normal and 3 = Verbose]
		# $LogLevel is a global variable.
	# Variables:
		my $Message = $_[0];
		my $LogFlag = $_[1];
	print FH_LOG "", TimeNow(2), " : $Message\n" if ($LogFlag <= $LogLevel);
} # END LogMessage()

sub LogTime {
	# Generates a current date and time message ["YYYY/MM/DD at HH:MM:SS"].
		# Pass: NONE.
		# Return: Date / Time.
		# Dependences: NONE
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $LogStartTime =  sprintf("%4d/%02d/%02d at %02d:%02d:%02d", ($year+1900), $mon, $mday, $hour, $min, $sec);
		return ($LogStartTime);
} # END LogTime()

sub TimeNow {
	# Returns the current time in either HH:MM or HH:MM:SS format.
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
			$Time = "less than 1 second.";
	}
	return($Time);
} # END of Duration().

## COSMOtherm Related ##

sub COSMOthermInstalled {
	# Check that the cosmologic directory is present in APPS directory. If not, prompt user to load the COSMOtherm module.
		# Pass: NONE.
		# Return: NONE.
		# Dependances: LogMessage(), Usage().
	# Variables:
		my $Flag = 0; # A flag.
		my $msg; # An error message.
		# The appsdir is define as a global variable.
	# Sub:
		LogMessage("Enter: COSMOthermInstalled()", 2);
		#opendir(DIR, $appsdir) or die "Can't open the APPS directory.";
		
		opendir(DIR, $appsdir) or $msg = "Can't open the APPS directory. line ". __LINE__ . " $!";
		if($msg ne "") {
			LogMessage("ERROR: $msg", 1);
			print "$msg";
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
	# Variables:
		my $msg;
		my @YearList; # Holds the list of years found (reverse chronological order).
		my $Flag = 0;
	# Sub:
		LogMessage("Enter: YearVersions()",2);
		opendir(DIR, $cosmologicdir) or $msg = "Can't open directory. line ". __LINE__ ." $!\n";
		if($msg ne "") {
			LogMessage("ERROR: $msg", 1);
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

sub CTRL_Read {
	# Reads in data from the Control File (Application Year, Paramaterisations and Temperature).
	# Pass: NONE.
	# Return: NONE.
	# Dependences: NONE.
		LogMessage("Enter: CTRL_Read()", 2);
		my $msg;
		# Open Control File.
			open (FH_CTRL, "<", $CTRLFileName) or $msg = "Can't open Control File. line ". __LINE__ ." $!\n";
			if($msg ne "") {
				LogMessage("ERROR: $msg", 1);
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
								$Temperature = $temp[1];
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

sub CTD_Path {
	# Foramlly sets AppYear and ParamYear, as well as the Parametermisation file location.



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
	LogMessage("PARAM: License file path: $ldir", 2);
	LogMessage("PARAM: Parameterisation path: $cdir", 2);
	LogMessage("PARAM: Parameterisation file: $ctd", 2);
	LogMessage("Leave: CTD_Path()", 2);
} # END CTD_Path().

sub Read_Solv_Data {
	# This subroutine open the Master Solvent File, extracts solvent cosmo file locations,
	# solvent density and physical properities.  A set of hash variables are populated.
	# Pass: None.
	# Return: None.
	# Dependences: None.
	# Global Variables: $netpath, $Solvent_Data, %Solvents, %Densities and %SolventProps.
	# (c) David Hose. Feb 2017.
		my $msg;
		LogMessage("Enter: Read_Solv_Data()", 2);
		open (FH_SOLV, "<" . $netpath . "/" . $SolvData) or $msg = "Can't Open Solvent Data. line ". __LINE__ . " $!."; # Open Solvent Master Data File.
			if($msg ne "") {
				LogMessage("ERROR: $msg", 1);
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
	# Pass: None.
	# Return: None.
	# Dependences: None.
	# Global Variables: $ProjectFileName, $ProjectName, $Compound, $AltName and $Client.
	# (c) David Hose. Feb 2017.
	my $msg;
		LogMessage("Enter: Read_Project()", 2);
		open (FH_PROJ, "<", $ProjectFileName) or $msg = "Can't open Project File. line ". __LINE__ . " $!\n"; # Open Project File.
			if($msg ne "") {
				LogMessage("ERROR: $msg", 1);
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

