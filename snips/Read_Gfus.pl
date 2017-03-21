#! /usr/bin/perl

# Read Reference solubility tab file.




$CurrCalcPath = "Calcs/Ref/";
@Files = <$CurrCalcPath*.tab>;
foreach $File (@Files) {
	$Result = Read_Gfus($File);
	#$RefSolub[$RefSolNum][9];  # Use position 9 to hold the value of Gfus.
	print "Gfus = $Result\n";

}
exit;

sub Read_Gfus {
	# Extracts the Gfus value from file.
		# Pass: Filename to be opened.
		# Return: Gfus value.
		# Dependences: NONE.
		# Global Varaibles: NONE.
	# (c) David Hose. Feb. 2017.
	my $FN = $_[0];
	my $Gfus; # Holds the free energy of fusion value.
	open (FH_GFUS_READ, "<$FN") or die "Can't open $!. LINE:" . __LINE__ ."\n"; # Open the Gfus calculation file.
	# LogMessage upon error required here.
	while(<FH_GFUS_READ>) {
	# Find the line containing the solute (Compound Number 1).
		if($_ =~ /^\s{3}1\s\S/i) {
			my @temp = split(/\s+/, $_);
			$Gfus = $temp[6];
			last; # Skip rest of file.
		}
	} # END FH_GFUS_READ while loop.
	close FH_GFUS_READ; # Close the input file.
	return $Gfus;
} # END Read_Gfus()
