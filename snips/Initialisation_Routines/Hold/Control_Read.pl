#! /usr/bin/perl

print ("\nControl File Read.\n\n");

# Read in Control file and set up key variables.

	my $CTRLFileName = "control.dat";
	
	my $AppYear; # Holds the Application Year (COSMOtherm version).
	my $ParamYear; # Holds the Parameterisation Year (COSMOtherm parameterisation).
	
	$AppYear = "default";
	$ParamYear = "default";
	my $Temperature;

CTRL_Read();

print "Version: $AppYear\n";
print "Parameterisation: $ParamYear\n";
print "Temperature: $Temperature\n";

sub CTRL_Read {
	# Reads in data from the Control File (Application Year, Paramaterisations and Temperature).
	# Pass: NONE.
	# Return: NONE.
	# Dependences: NONE.
		# Open Control File.
			open (FH_CTRL, "<", $CTRLFileName) or die "Can't open Control File.\n";
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
											print "Error! Temperature entered is greater than 100.  Expecting temperature in degC\n";
											exit; # A more control exit is required.
										}		
								$Temperature = $temp[1];
								} else {
									print "Error! Number not entered for the temperature!\n";
									exit; # A more control exit is required.
								}
				} # END 'Temperature' if.
			} # END while loop over FH_CTRL.
	close FH_CTRL; # Close the Control File.
} # END CTRL_Read().







