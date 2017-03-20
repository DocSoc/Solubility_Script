#! /usr/bin/perl

$str = "f = AZ13530968_c0.cosmo fdir=\"/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE/a\"  Comp = AZ13530968 [ \nf = AZ13530968_c1.cosmo fdir=\"/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE/a\"  \nf = AZ13530968_c2.cosmo fdir=\"/dbs/AZcosmotherm/AZ_BP_TZVPD-FINE/a\"  ] Comp = AZ13530968";

@Temp = split(/\[/, $str);
$str2 = join("", $Temp[0], "[ CONNECTION", $Temp[1]);
#print "$str\n$str2\n";

COSMO_Solute(1, $str, 8.2345, 4.536235, 454.2);
exit;

sub COSMO_Solute {
	# Writes the solute path/filename information to the current COSMOtherm INP file.
		# Pass:
		# Return:
		# Dependences:
		# Global Variable:
	# (c) David Hose. March 2017.
	LogMessage("Enter: COSMO_Solute()", 1);
	my ($Opt, $Solute, $DGfus, $DHfus, $Tmelt) = @_;
	if($Opt == 1) {
		# Option 1: Write solute line 'as-is'.
			print "$Solute\n";
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
		print "$Temp\n";
		LogMessage("Leave: COSMO_Solute()", 1);
		return;
	} # END Option 2.
	elsif($Opt == 3) {
		# Option 3: NA
		#my @Temp = split(/\[/, $str); # Split the solute.
		#my $Props = "[ ";
		#if($DGfus eq "") {
		#	my $msg = "ERROR: No Gfus Value available. LINE:" . __LINE__;
		#		print "$msg\n";
		#		LogMessage("$msg", 1);
		#		exit;
		#} else {
		#	$Props = $Props . " DGfus = $DGfus ";
		#}
		#if($DHfus ne "" && $Tmelt ne "") {
		#	$Props = $Props . " DHfus = $DHfus TMELT_K = $Tmelt ";
		#}
		#my $Temp = join("", $Temp[0], $Props, $Temp[1]);
		#print "$Temp\n";
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

sub LogMessage {
	print "";
}



