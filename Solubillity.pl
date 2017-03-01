#! /usr/bin/perl

# Perl script to process measured solubilities, determine the best reference solvent and then run a series of predictions.

# (c) David Hose Feb. 2107.

BEGIN { $| = 1 }	# Turn on autoflush for STDOUT.

# Variables:
	# Key file locations:
		# Network files (Key master files).
			my $NetPath = "/projects/PharmDev/COSMOtherm/Solubility_Screening/"; # Provisional location.
			
			
			
		# Applications Directory.
			my $apps = "/apps/cosmologic"; # Points to where the COSMOtherm application sits.

	my @usr = ((getpwuid($<))[0], (getpwuid($<))[6]); # Store user's login ID and Real Name.
	$usr[1] =~ s/\./ /g; # Replace peroids in name.
	print "User: @usr\n";