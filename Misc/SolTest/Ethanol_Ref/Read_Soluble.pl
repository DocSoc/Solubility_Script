#! /usr/bin/perl

# Read Soluble tab file.

@Files = ("Ethanol_Ref/Solubility0.tab",
		  "Ethanol_Ref/Solubility1.tab");

foreach $File (@Files) {
	$Result = Read_Soluble($File);
	print "Solubility = $Result\n";
}
exit;

sub Read_Soluble {
	# Extracts the Solubility value from file.
	# Pass: Filename to be opened.
	# Return: w_solub value.
	# Dependences: None.
	# (c) David Hose Feb. 2017.
	my $FN = $_[0];
	my $Soluble; # Holds the Solubility value.
	open (FH_SOLUB_READ, "<$FN") or die "Can't open $!\n"; # Open the Solubility calculation file.
	REF_READ: while(<FH_SOLUB_READ>) {
		# Find the line containing the solute (Compound Number 1).
		if($_ =~ /^\s{3}1\s\S/i) {
				@temp = split(/\s+/, $_);
				$Soluble = $temp[12];
				last; # Skip rest of file.
			}
	} # END FH_SOLUB_READ while loop.
	close FH_SOLUB_READ; # Close the solubility file.
	return $Soluble;
} # END Read_Soluble()