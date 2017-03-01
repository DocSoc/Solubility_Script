#! /usr/bin/perl

use Cwd;
use File::Path;

my ($author, $version, $date, $scriptname) = ("David Hose", 0.1, "May 2016", "PartitioningV2.pl");

# Log File Set Up:
	# Level of reporting.
		$LogLevel = 3; # 1 = Sparse, 2 = Normal and 3 = Verbose. Parser Linkage.
		$LogFileName = join('', "Partitioning-", time(), ".log"); # Log file name (only use a limited number of digits). (Consider TimeCode variable to match up with the wetting directory).
		$LogFileName = join('', "Partitioning-", "000001" , ".log"); # DEVELOPMENT. REMOVE IN PRODUCTION.
	# Open the log file.
		open (FH_LOG, ">$LogFileName") or die "Can't open the Log File $!";
		LogFileHeader(); # Write general details of the script to the log file.
		
		
		
	# List key locations in the Log File:
		LogMessage("PARAM: Location: $PartitionNetworkPath", 2);
		LogMessage("PARAM: Wetting DB: $WettingPath", 2);
		LogMessage("PARAM: Master Solvents: $MasterSolvents", 2);
		LogMessage("PARAM: Wetting Calculations: $WettingCalcPath", 2);
		LogMessage("PARAM: Apps directory: $appsdir", 2);
		LogMessage("PARAM: COSMOlogic directory: $cosmologicdir", 2);
		# Consider adding key COSMOtherm directories and Parameters.


# End log file.
	LogMessage("SCRIPT COMPLETE", 1);
	close FH_LOG; # Close the log file.
exit;


sub Dummy {
	# Write the full Hello message here.
	LogMessage("Enter: Dummy()", 2);
	LogMessage("MESSG: This is a minor message", 3);
	LogMessage("PARAM: Current Year.", 3);
	LogMessage("ERROR: Can't generate an appropriate year code.", 1);
	LogMessage("Leave: Dummy()", 2);
} # END Hello()


sub LogFileHeader {
	# Creates the header information in the log file.
		# Pass:
			# NONE (Data is pulled from Global Level or Environment).
		# Variables:
			chomp(my $hostname = `hostname -s`);
			my $dir = getcwd();
			my $username = getpwuid($<);
		# Sub:
			# Header section:
				print FH_LOG "GENERAL INFORMATION\n\n";
				print FH_LOG "Executed on ", LogTime(), "\n\n";
			# Script information:
				printf FH_LOG ("%-14s: %s\n", "Log File Name", $LogFileName);
				printf FH_LOG ("%-14s: %s\n", "Perl Script", $scriptname);
				printf FH_LOG ("%-14s: %s\n", "Version", $version);
				printf FH_LOG ("%-14s: %s\n", "Date", $date);
				printf FH_LOG ("%-14s: %s\n", "Author", $author);
			# User and machine information:
				printf FH_LOG ("%-14s: %s\n", "Hostname", $hostname);
				printf FH_LOG ("%-14s: %s\n", "Path", $dir);
				printf FH_LOG ("%-14s: %s\n", "User ID", $username);
				print FH_LOG "\nSTARTING SCRIPT\n\n";
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

############################
# VARIOUS TIME SUBROUTINES #
############################

sub LogTime {
	# Generates a current date and time message ["YYYY/MM/DD at HH:MM:SS"].
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

sub UserTimePrefix {
	# Constructs the UserID - Time Prefix for use when running wetting calculations in PUBLIC network directory.
	# Using last 5 time digits (seconds) means the same number will come around every 27.77 hours.
	# Wetting calculations will have easily been completed in that time.
		# Pass:
			# NONE
		# Sub:
			my $uid = getpwuid($<); # Get User ID.
			my $time = substr time, 5, 5; # Get current time (10 digits) and truncate to last 5 digits.
			my $Prefix = join('', $uid, "_", $time); # Construct prefix.
			return($Prefix);
} # END UserTimePrefix()