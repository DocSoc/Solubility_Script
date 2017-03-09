#! /usr/bin/perl

# Determine the correct path and name of the CTD files based upon the application year and the parameterisation year requested.

# Variables:
	my $AppYear; # Holds the Application Year.
	my $ParamYear; # Holds the Parameterisation Year.
	my @Years; # Holds the available COSMOtherm application versions.
	my $paramfile; # Holds the path and name of the required CTD file.
	
	$AppYear = 17;
	$AppYear = "default";
	$ParamYear = 16;
	$ParamYear = "default";
	#$ParamYear = "BP_TZVPD_FINE_C30_1701_AZ.ctd";
	@Years = (14,16,15,17);
	@Years = reverse (sort @Years); # Reverse sort the years.

# Based upon the choices what CTD path/filename is set?
	print "Application Year = $AppYear.\t Parameter Year = $ParamYear.\n";
	CTD_Path();
	print "Parameter Files root: $paramfile\n";
	exit;

sub CTD_Path {
	# Determine if the chosen COSMOtherm application year is available.
		# If choice year is 'default' use the most recent application year that has been loaded.
			$AppYear = $Years[0] if ($AppYear =~ /^Default/i);
		# Is the selected application year available?
			if($AppYear ~~ @Years) {
				print "The desired application year is available (20$AppYear).\n";
				# Set up the application call variable. e.g. "COSMOthermX17".
			} else {
				print "The desired application year is NOT available (20$AppYear).\n";
				exit; # Gracefully terminate via Usage and add comment to the log.
			} # END if($AppYear ~~ @Years).
		# Set the Application Year directory.
			$paramfile = "apps/cosmologic/COSMOthermX$AppYear/COSMOtherm/CTDATA-FILES";
	# Determine if the parameterisation year is appropriate and set up the correct path and name of the parameterisation file.
		# If the choice year is 'default' set Parameterisation year.
			$ParamYear = $AppYear if($ParamYear =~ /^Default/i);
		# Set Path and Filename depending upon Application and Parameterisation years.
		# If the parameter year starts with a non-digit, assume that this defines the name of a special parameterisation file.
			if($ParamYear =~ /^\D/) {
				$paramfile = "apps/cosmologic/COSMOthermX$AppYear/COSMOtherm/CTDATA-FILES/$ParamYear"
			} else {
				# Catch an inappropriate Application/Parameterisation year combination.
					if($AppYear < $ParamYear) {
						print "Can't run parameters (20$ParamYear) that are newer than the Application (20$AppYear)\n";
						exit;	# Gracefully terminate via Usage and add comment to the log.
				}
				# Add OLDPARAM directory sub-level.
					$paramfile = $paramfile . "/OLDPARAM" if($AppYear > $ParamYear);
				if($ParamYear <= $Years[0] && $ParamYear >= 12) {	
					# Known special cases (2012 and 2013 have the 2012 HB terms added).
						if($ParamYear == 12 || $ParamYear == 13) {$paramfile = $paramfile . "/BP_TZVPD_FINE_HB2012_C30_". $ParamYear ."01.ctd"}
					# General cases.
						if($ParamYear <= $Years[0] && $ParamYear >= 14) {$paramfile = $paramfile . "/BP_TZVPD_FINE_C30_" . $ParamYear . "01.ctd"}
				} else {
					print "Sorry there are no parameterisation files available for the year 20$ParamYear (2012 - 20$Years[0]).\n";
					exit; # Gracefully terminate via Usage and add comment to the log.
				}
			}
} # END CTD_Path().
