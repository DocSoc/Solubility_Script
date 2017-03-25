#! /usr/bin/perl

# Create a list of solvents to read prediction upon.
my $SolventFile = "solventlist.dat";
my @List = Read_Solvents($SolventFile);
foreach my $i (@List) {print"<$i>\n"}
exit;

sub Read_Solvents {
	# Reads in a list of Solvent ID's for which the solubility of the solute is to be predicted in.
		# Pass: Filename.
		# Return: Solvent List.
		# Dependences:
		# Global Variables:
	# (c) David Hose. March 2017.
		my $FN = $_[0]; # The filename of the list of solvents that solubility predictions have to be made.
		my $msg; # Holds error messages.
		my $str; # Holds the string of Solvent IDs. (form 1,2,5-10,115,...).
		my @tmp; # Temp array to process the string.
		my @Solvents; # This will hold the list of Solvent IDs to be returned.
		LogMessage("Enter: Read_Pred_Solv()", 1);
		open (FH_SOLLIST, "<$SolventFile") or $msg = "Can't open Solvent List '$FN'. $! LINE:" . __LINE__;
		if($msg ne "") {
			# Handle the file error.
			print "$msg\n";
			LogMessage("ERROR: $msg", 1);
			exit;
		}
		while (<FH_SOLLIST>) {
			# Create a single line string of the Solvent ID numbers separated by commas (the solvents could be listed over multiple lines).
			chomp;
			$str = "$str,$_";
		}
		close FH_SOLLIST;
	# Case 1 - "ALL" available Solvents are to be run.
		if($str =~ /^,all/i) {$str = "1-9,11-91,93-272"} # This should exclude those solvents that don't have TZVPD-Fine cosmo files.

	# Case 2 - Immiscible Solvents.
		if($str =~ /^,immisc/i) {
			$str = "1, 3, 4, 6, 7, 11, 14, 15, 18-26, 31-48, 50-55, 59, 60, 62-64, 66-68, 73, 74, 75, 81-84, 88-90, 92-96, 100-102, 104-106, 109-113, 117, 118, 122, 124, 125, 128-130, 132-137, 140-146, 154, 156, 158-161, 163, 165-170, 177-188, 190, 192-216, 218-221, 223, 224, 226, 230-232, 234, 236-243, 246, 264-269, 270, 272";
		} # CHECK for compounds that don't have TZVPD-Fine cosmo files.
	# Case 3 - Miscible Solvents.
		if($str =~ /^,misc/i) {
			$str = "2, 5, 8, 9, 12, 13, 16, 27-30, 49, 56, 58, 61, 65, 69, 70-72, 76-80, 85-87, 97-99, 103, 107, 108, 114-116, 119-121, 123, 126, 127, 131, 138, 147-150, 155, 157, 162, 164, 171, 172, 176, 189, 191, 217, 227-229, 233, 235, 244, 254, 260";
		} # CHECK for compounds that don't have TZVPD-Fine cosmo files.
	# Case 4 - General case & process the strings created by Cases 1 - 3..
		$str =~ s/\s//g; # Remove spaces ', '.
		@tmp = split(/,/, $str); # Split string by commas.
		# Loop through each element of @Temp looking for 'digit(s)-digit(s)' format that indicates a range. (9-14 means {9, 10, 11, 12, 13, 14}).
			foreach $i (@tmp) {
				if ($i =~ /\d+\-\d+/) {
					my $seq = "";
					$i =~ m/(\d+)\-(\d+)/;
					for ($j = $1; $j <= $2; $j++) {$seq = "$seq,$j"}
					$i = $seq; # Overwrite the current element with the required sequence.
				}	
			} # END foreach loop.
		$str = join(",", @tmp); # Rejoin the elements together (to integrate the new sequence(s)).
		@Solvents = split(/,/, $str); # Split string by commas.
		@Solvents = grep { $_ ne '' } @Solvents; # Remove any blank elements which might be present.
		@Solvents = sort { $a <=> $b } (@Solvents); # Sort the solvent IDs numerically.
		LogMessage("Leave: Read_Pred_Solv()", 1);
		return (@Solvents);
} # END Read_Pred_Solv()

sub LogMessage {
	print "";
}

