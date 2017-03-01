#! /usr/bin/perl

# Variables: (Place into MAIN)
	my $ProjectFileName = "project.dat";
	my ($ProjectName, $Compound, $AltName, $Client); # Variables containing Project Information.
	Read_Project(); # Reads data and populates the required variables.

# Test that data has been extracted and processed correctly.
	print "Project: $ProjectName\n";
	print "Compound: $Compound\n";
	print "Alternative Name: $AltName\n";
	print "Client: $Client\n";

exit;

sub Read_Project {
	# Reads in the Project information and sets appropriate variables.
	# Pass: None.
	# Return: None.
	# Dependences: None.
	# Global Variables: $ProjectFileName, $ProjectName, $Compound, $AltName and $Client.
	# (c) David Hose. Feb 2017.
		open (FH_PROJ, "<", $ProjectFileName) or die "Can't open Project File.\n"; # Open Project File.
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
							print "Invalid AZ number entered (\"$temp[1]\") Using default name of NULL.\n";
							$Compound = NULL;
						}
				} # END 'Compound' if.
				if($_ =~ /^Alternative/) {
					# What is the alterative name of the compound?  Especially important if there is no valid AZ number.
						$AltName = $temp[1];
				} # END 'Alternative' if.
				if($_ =~ /^Client/) {
					# What is the Client's name?
						if($temp[1] eq "") {
							# No name has been entered.
								print "No client name entered.  Using a default name of 'Test'\n";
								$Client = "Test";
						} else {
							$temp[1] =~ s/(\w+)/\u\L$1/g; # Ensure that the client's name is appropriately capitalised.
							$Client = $temp[1];
						}
				} # END 'Client' if.
		} # END FH_PROJ while loop.
		close FH_PROJ; # Close Project File.
} # END Read_Project()
