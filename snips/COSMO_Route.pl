#! /usr/bin/perl

# COSMO route cards.

my $TExpt_C = 125.0;
#$TExpt_C = sprintf("%.2f", $TExpt_C);

my $Curr_Ref_Solub = 0.10000001;


COSMO_Route(1);

exit;

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
		print "solub=2 WSOL2 solute=1 tc=$TExpt_C ref_sol_g=$Curr_Ref_Solub \n";
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
		LogMessage("ERROR: No Route valid option selected.", 1);
		exit;
	}
	
	
	LogMessage("Leave: COSMO_Route()", 3);
	return;
} # END COSMO_Route()








sub LogMessage {
	my $msg = $_[0];
	print "$msg\n";
}


