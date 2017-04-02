#! /usr/bin/perl

@Files = <*.vap>; # Find a list of .vap files to test.
push @Files, "water.vap";
foreach $i (@Files) {
	@RES = Read_VPfile_TMelt($i);
	print "File: $i\tTMelt = $RES[0] degC or $RES[1] K.\n";
} # END foreach

sub Read_VPfile_TMelt {
	# Reads the value of TMelt of the Solute from the corresponding COSMOtherm VAP file.
		# Pass: Filename of the vap file.
		# Return: TMelt as an array [degC, K].
		# Dependences: NONE.
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
	LogMessage("Enter: Read_VPfile_TMelt()",2);
	my $vapfile = $_[0]; # Pass the name of the COSMOtherm VAP file.
	my $Temp = ""; # Holds the melting point temperature (degC or K).
	my @TEMPS;	# Holds the melting point temperatures [degC, K].
	my $str; # Holds the vapfile line for processing.
	open (FH_VAP, "<$vapfile") or my $msg = "Can't open file '$vapfile'. $!. LINE:" . __LINE__;
		if($msg ne "") {
			print "$msg\n";
			LogMessage("ERROR: $msg", 1);
			exit;		
		}
	while(<FH_VAP>) {
		$str = $_;
	} # END while loop.
	close FH_VAP;
	$str =~ m/(tmelt_[c|k]=\S+)/i;
	$Temp = (split(/=/, $1))[1];
	if($1 =~ /c/i && $Temp ne"") {
		$TEMPS[0] = $Temp;
		$TEMPS[1] = $Temp + 273.15;
	} else {
		$TEMPS[0] = $Temp - 273.15;
		$TEMPS[1] = $Temp;
	}
	if($Temp eq "") {$TEMPS[0] = $TEMPS[1] = "NA"}
	LogMessage("PARAM: VPfile TMelt = $TEMPS[0] degC ($TEMPS[1] K)", 3);
	LogMessage("Leave: Read_VPfile_TMelt()", 2);
	return(@TEMPS);
} # END Read_VPfile_TMelt()

sub LogMessage {
	print ""
}
