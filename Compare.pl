#! /usr/bin/perl

@INPFiles = ("Pred001.inp", "Pred002.inp", "Pred003.inp", "Pred004.inp", "Pred005.inp", Pred020.inp);
@TABFiles = ("Pred001.tab", "Pred002.tab", "Pred003.tab", "Pred004.tab", "Pred005.tab");
@TABFiles = ("Pred001.tab", "Pred002.tab", "Pred003.tab", "Pred005.tab");
@TABFiles = ("Pred001.tab", "Pred003.tab", "Pred005.tab");
@OUTFiles = ("Pred001.out", "Pred003.out", "Pred005.out");


#CheckFileLists(\@INPFiles, \@TABFiles); # passing two references
#print "No missing files.\n";
$Path = "Calcs/Cluster";
$Res = CheckClustErr($Path);
CheckCOSMOErr($Path);

exit;
 
sub CheckFileLists {
	# Determine which files are missing from two filename arrays.
		# Pass: INPUT Filename array and OUTPUT filename array.
		# Return: NONE. If files are missing, report and exit.
		# Dependences: NONE.
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
	my ($inp_ref, $out_ref) = @_; # Extract references.
	# Dereferencing and copying each array.
		my @INPS = @{ $inp_ref }; # Holds the list of Input files.
		my @OUTS = @{ $out_ref }; # Holds the list of Output files.
	my @union = (); # The union of the two arrays.
	my @intersection = (); # The intersection of the two arrays.
	my @difference = (); # The difference of the two arrays.
	my %count = (); # A counter.
	my $INPStype = (split(/\./, @INPS[0]))[-1]; # Holds the file extension of the Input file list.
	my $OUTStype = (split(/\./, @OUTS[0]))[-1]; # Holds the file extension of the Input file list.
	# Extract the numbers from the filenames.
		foreach $i (@INPS) {
			# For the INPS files.
			$i =~ m/(\d{3})/; # Extract the 3 digit numeric from the filename...
			$i = $1 + 0; # ...and convert to a number.
		}
		foreach $i (@OUTS) {
			# For the OUTS files.
			$i =~ m/(\d{3})/; # Extract the 3 digit numeric from the filename...
			$i = $1 + 0; # ...and convert to a number.
		}
		foreach my $element (@INPS, @OUTS) { $count{$element}++ }
		foreach my $element (keys %count) {
			push @union, $element;
			push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
		}
	# Sort numerical ascending.
		@union = sort {$a<=>$b} @union;
		@intersect = sort {$a<=>$b} @intersect;
		@difference = sort {$a<=>$b} @difference ;
	# Actions based upon the content of difference array.
		if(scalar(@difference) == 1) {
			print "The following ". uc($OUTStype) ." file is missing: ";
			my $File = "Pred". sprintf("%.3d", $difference[0]) . ".$OUTStype\n";
			print "$File";
		}
		elsif(scalar(@difference) > 1) {
			print "The following ". uc($OUTStype) ." files are missing:\n";
			foreach my $i (@difference) {
				my $File = "Pred". sprintf("%.3d", $i) . ".$OUTStype\n";
				print "$File";
			}
		}
		if(scalar(@difference) != 0) {
			print "ERROR: Terminating.\n";
			exit;
		}
	return;
} # END CheckFileLists()

sub CheckCOSMOErr {
	# Check the cluster error files (.cerr) for errors.
		# Pass: Path.
		# Return: NONE. Terminates on discovering valid SGE error files.
		# Dependences: LogMessage() and LogErrMessg().
		# Global Variables: NONE.
	# (c) David Hose. April 2017.
	my $Path = $_[0];
	my @Files = <$Path/*.err>;
	if(scalar(@Files != 0)) {
		my $msg = "The following COSMOtherm error files were created in $Path/:";
		print "$msg\n";
		LogMessage("MESSG: $msg", 2);
		foreach my $i (@Files) {
			$i =~ /(\w+)(\.\w{3}$)/;
			print "\t$1\n";
			LogMessage("", 1);
		}
		$msg = "Check the COSMOtherm error files.";
		print "$msg\n";
		LogMessage("MESSG: $msg", 2);
	}
	return;
} # END CheckCOSMOErr()

sub CheckClustErr {
	# Check the cluster error files (.cerr) for errors.
		# Pass: Path.
		# Return: NONE. Terminates on discovering valid SGE error files.
		# Dependences: LogMessage() and LogErrMessg().
		# Global Variables: NONE.
	# (c) David Hose. April 2017.
	my $Path = $_[0];
	my @Files = <$Path/*.cerr>;
	my @ClusterErrors = ();
	foreach my $i (@Files) {if (-s $i) {push @ClusterErrors, $i}} # Found an cluster error that's non-zero in size.
	if(scalar(@ClusterErrors) != 0) {
		my $msg = "Cluster Errors detected in $Path/:";
		print "$msg\n";
		LogMessage("MESSG: $msg", 2);
		foreach my $i (@ClusterErrors) {
			$i =~ /(\w+)(\.\w{4}$)/;
			$msg = "\t$1";
			print "$msg\n";
			LogMessage("MESSG: $msg", 1);
		}
		print "ERROR: Terminating script.";
		# LogErrMessg("Non-zero error files produced from SGE.")
		exit;
	}
	return;
} # END CheckClustErr()

sub LogMessage {}
sub LogErrMssg {}


