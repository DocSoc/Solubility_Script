#! /usr/bin/perl

########################
# CLUSTER CALCULATIONS #
########################

sub ClusterComplete {
	# This subroutine monitors the cluster queue for the user's COSMOtherm calculations.
	# When all of the calculations have been completed, the subroutine exits.
		# Pass:
			# $Submitted This is the number of calculation that have been submitted to the cluster.
			# $CalcName The starting substring for the name of the calculations to monitor (e.g. "Wetting" to find "Wetting001, Wetting002,...).
			# $TypTime The 'typical' time that a single calculation will take (minutes). Passed through to WaitTime() calculation.
	# Variables:
		my $Submitted = $_[0]; # The number of calculations that have been submitted to the cluster (counted from the submission phase).
		my $CalcName = $_[1];
		my $TypTime = $_[2]; # The typical time required for this type of calculation.
		my $StartTime = time; # Start time of this subroutine.
		my $CurrentTime; # Current Time in seconds.
		my $ElapsedTime; # Elapsed time in minutes.
		my $WaitingTime; # The amount of time (mins) to wait before rescanning the cluster queue.
		my @WaitingTimes;
		my $Completed = 0; # Number of Completed calculations.
		my $Cycle = 0; # Counter.
		my @QSTATArgs = ("qstat", "-u", $uid, "-xml"); # Arguments for QSTAT (pulls the entries for the current User [uid]).
		my @XML; # Hold the XML output from QSTAT for processing.
	# Sub:
		LogMessage("Enter: ClusterComplete()", 2);
		print "Cluster Monitoring\n";
		while() {
			$CurrentTime = time;
			$ElapsedTime = ($CurrentTime - $StartTime); # Calculate Elapsed time in minutes.
			@WaitingTimes = WaitTime($Submitted, $Completed, $ElapsedTime, $TypTime); # Determine the waiting time to be used.
			$Cycle = sprintf("%3s", $Cycle);
			print "  [", TimeNow(1), "] Cycle $Cycle: Wait $WaitingTimes[0] mins: ";
			sleep($WaitingTimes[0] * 60);
			chomp(@XML = `@QSTATArgs`); # Get the QSTAT for the current user.
			($JobRunCnt, $JobWaitCnt) = Queue_Reader($CalcName, @XML);
			$StatusMessage = QueueStatusReport($Submitted, $JobRunCnt, $JobWaitCnt, 0, 0, 1); # Generate a status report.
			print "$StatusMessage\n"; # Report Status.
			last if(($JobRunCnt + $JobWaitCnt) == 0); # Exit while loop if there are no more calculations running or waiting in the queue.
			$Completed = $Submitted - ($JobRunCnt + $JobWaitCnt);
			$Cycle++; # Increment the Cycle counter.
		} # END WHILE LOOP.
		### CAREFULLY CHECK THIS SECTION OF CODE ### Especially the duration function.
		my $LogMsg = join('', "MESSG: Cluster Calculations completed. Duration:", Duration($ElapsedTime, 1));
		LogMessage($LogMsg, 2);
		print "Cluster calculations have been completed.\n";
		LogMessage("Leave: ClusterComplete()", 2);
} # END ClusterComplete()

sub WaitTime {
	# Determines the waiting time, in minutes, between between QSTAT checks.
	# From the total number of calculations submitted, the number of completed calculation and
	# the elapsed time, the time to completion is estimated.  This value is used to determine an
	# appropriate waiting time before rechecking the queue.
		# Pass:
			# $Total Number of Calculations submitted.
			# $Complete Number of calculations that have completed.
			# $Elapsed Elapsed calculation time (seconds).
			# $TypTime Typical Time to complete a calculation (minutes) OPTIONAL.
	# Variables:
		my ($Total, $Completed, $Elapsed, $TypTime) = @_; # Passed variables.
		my @WaitingTimes = (30, 15, 10, 5, 2, 1, 0.5, 0.25); # Possible waiting times intervals in minutes.
		my $WaitEst;
		my $Slots = 366; # Number of slots available on the cluster (modify for cluster configuration).
		my $Fraction = 0.1; # Estimate of fraction of slots available (experience from cluster).
		$TypTime ||= 0.5; # DEFAULT for OPTIONAL argument. Typical time for a COSMOtherm Wetting Calculation (mins).
	# Sub:
		# Estimate time to completion.
			if($Elapsed < 5 || $Completed == 0) {
				# If elapsed time is < 5 seconds or no calculations have been completed (latter prevents a DIV ZERO error).
				$WaitEst = ($Total / ($Fraction * $Slots)) * $TypTime; # First cycle (Guestimate wait time [mins]).
					# Might want to consider a different default wait time!
			} else {
				$WaitEst = ($Total - $Completed) * ($Elapsed / $Completed); # Subsequent cycles.
			}
		# Determine an appropriate waiting time [mins] from the list of potential wait times.
			my ($min_idx) = map{$_->[0]}
			sort{ $a->[1] <=> $b->[1]}
			map{[$_, abs($WaitingTimes[$_]-$WaitEst)]} 0..$#WaitingTimes;
		# Round the estimated completion time for output.
			if($WaitEst < 1) {$WaitEst = sprintf("%.2f", $WaitEst)} else {$WaitEst = sprintf("%0d", $WaitEst)}
		return($WaitingTimes[$min_idx], $WaitEst);
} # END WaitTime()

sub QueueStatusReport {
	# Reports the status of queue calculations.
		# Pass:
			# $QTotal Total number of calculations submitted to the queue.
			# $QRun Number of running calculations.
			# $QWait Number of calculations waiting in the queue (including transfers).
			# $QErrs Number of calculations that have produced error files (optional).
			# $Format Specifies the format of the report 1 = Long, 0 = Short (optional).
			# $Percentages Specifies if the percentages are displayed 1 = Yes, 0 = No (optional).
	# Define variables:
		my ($QTotal, $QRun, $QWait, $QErrs, $Format, $Percentages) = @_;
		my $QComp = $QTotal - ($QRun + $QWait); # Calculates the number of complete calculations.
		my $QRun_age = 100 * $QRun / $QTotal; # Calculates the percentage of running calculations.
		my $QWait_age = 100 * $QWait / $QTotal; # Calculates the percentage of waiting calculations.
		my $QComp_age = 100 * $QComp / $QTotal; # Calculates the percentage of completed calculations.
		my $QErrs_age =  100 * $QErrs / $QTotal; # Calculates the percentage of errored calculations.
		my $Result; # Holds the result that is passed back.
		$QErrs ||= 0; # Default value.
		$Format ||= 0; # Default.
		$Percentages ||= 0; # Default.
	# Basic reporting:
	if($Percentages == 1) {
		# Include the percentages.
		if($Format == 1) {
			# Long format:
			$Result = sprintf("Complete %d [%.1f\%], Running %d [%.1f\%], Waiting %d [%.1f\%], Total %d.", $QComp, $QComp_age, $QRun, $QRun_age, $QWait, $QWait_age, $QTotal);
		} else {
			# Short format:
			$Result = sprintf("C %d [%.1f\%], R %d [%.1f\%], W %d [%.1f\%], T %d.", $QComp, $QComp_age, $QRun, $QRun_age, $QWait, $QWait_age, $QTotal);
		}
	} else {
		# Exclude the percentages.
		if($Format == 1) {
			# Long format:
			$Result = sprintf("Complete %d, Running %d, Waiting %d, Total %d.", $QComp, $QRun, $QWait, $QTotal);
		} else {
			# Short format:
			$Result = sprintf("C %d, R %d, W %d, T %d.", $QComp, $QRun, $QWait, $QTotal);
		}
	}
	# Errors:
	if($QErrs != 0) {
		# Add error numbers.
		if($Percentages == 1) {
			# Include the percentages.
			if($Format == 1) {
				# Long format:
				$Result = join(' ', $Result, sprintf("ERRORS %d [%.1f\%]!", $QErrs, $QErrs_age));
			} else {
				# Short format:
				$Result = join(' ', $Result, sprintf("E %d [%.1f\%]!", $QErrs, $QErrs_age));
			}
		} else {
			# Exclude the percentages.
			if($Format == 1) {
				# Long format:
				$Result = join(' ', $Result, sprintf("ERRORS %d!", $QErrs));
			} else {
				# Short format:
				$Result = join(' ', $Result, sprintf("E %d!", $QErrs));
			}
		}
	}
	return($Result);
} # END QueueStatusReport()

sub Queue_Reader {
	# Reads the QSTAT XML output and searches for jobs that bears the correct name (regex) and counts running and waiting jobs.
		# Pass:
			# $Jobname The substring of the job name to search for,
			# @XML The XML STDOUT data.
	# Variables:
		my $JobName = shift; # Holds the (partial) name of the Job to search for.
		my @XML = @_; # The QSTAT STDOUT XML data.
		my $line; # Holds the contents of the current line.
		my $JobFlag = 0; # Indicates if the correct job have been found.
		my $JobRunCnt = 0; # Counter for running jobs that matches the desired job name.
		my $JobWaitCnt = 0; # Counter for waiting jobs that matches the desired job name.
		my $i = 0; # Line counter.
	# Sub:
		while($i <= $#XML) {
			$line = $XML[$i];
			if($line =~ /<JB_name>/) {
				# Find Job Name.
					$line =~ s/^\s+<JB_name>|<\/JB_name>$//g; # Strip XML tags.
					$JobFlag = 1 if($line =~ /^$JobName/); # Is this the correct job?  Set the JobFlag.
			}
			if($line =~ /<state>/) {
				# Find the status of the calculation.
					$line =~ s/^\s+<state>|<\/state>$//g; # Strip XML tags.
				# Increment Run and Wait counters as appropiate.
					$JobRunCnt++ if($line eq "r" && $JobFlag == 1); # Running Calculations for the required job.
					$JobWaitCnt++ if(($line eq "qw" || $line eq "t") && $JobFlag == 1); # Waiting and Transferring (rare event) Calculations for the required job.
			}
		$JobFlag = 0 if($line =~ /<\/job_list>$/); # Find the END of a job record and reset JobFlag.
		$i++;
		} # END while.
	return($JobRunCnt, $JobWaitCnt); # Return the results.
} # END Queue_Reader()

sub ClusterScript {
	# This generates the body for QSUB submission script for COSMOtherm Calculations.
	# See http://gridscheduler.sourceforge.net/htmlman/manuals.html for QSUB commands/options.
		# Variables:
			my $File = $_[0]; # The Path/Filename of the COSMOtherm INP file to be submitted.
			my $a; # Holds all of the commands/arguments of the submission script.
		# Submission script body:
			$a = 		"#! /bin/tcsh\n"; # The hash bang.
			$a = $a .	"#\$ -cwd\n"; # The current working directory.
			$a = $a .	"#\$ -N $File\n"; # Name of the calculation.
			$a = $a .	"#\$ -o $File.out\n"; # -o The name and extension of the output file.
			$a = $a .	"#\$ -e $File.cerr\n"; # -e The name and extension of the cluster error file.
			$a = $a .	"module load cosmotherm\n"; # Load COSMOtherm module on to the node.
			$a = $a .	"cosmotherm $File.inp\n"; # Run the specfied file with COSMOtherm.
		# Return generated script:
			return($a)
} # END ClusterScript()

sub SubmitCalc {
	# For the inputted path/filename, this subroutine does:
	# 	Creates the required submission script for the current file.
	#		Sets the required permissions.
	#		Submits the calculation to the cluster.
	#		Removes the redundant submission script.
		# Pass:
			# $File The Path/Filename of the COSMOtherm INP file to be submitted to the cluster.
	# Variables:	
		my $File = $_[0]; # The Path/Filename of the COSMOtherm INP file to be submitted.
		my $SubmissionBody; # Holds the text for the body of the submission script.
		my $ErrMsg; # Holds any error messages.
	# Sub:
		$File = substr $Text, 0, -4; # Strip off the extension.
		$SubmissionBody = ClusterScript($File); # Generate the submission script body.
		#open (FH_SUBMISSION, ">Submission.sc") or die "Can't create the submission script $!"; # Opens the submission file.

		open (FH_SUBMISSION, ">Submission.sc") or $ErrMsg = "Can't open the 'Submission.sc' file. Line " . __LINE__ . ". $!"; # Opens the submission file.
		if($ErrMsg ne "") {
			# Catch the error.
			LogMessage("ERROR: $ErrMsg", 1);
			print "$ErrMsg\n";
			exit;
		}
		print FH_SUBMISSION "$SubmissionBody";
		close FH_SUBMISSION;
		chmod 0777, "Submission.sc"; # Make file executable.
		@SubArgs = ("qsub", "-l", "mem_total=12G", "Submission.sc");
		LogMessage("MESSG: Submitting $File to Cluster.", 2);
		# DEVELOPMENT OPTION.  REMOVE FROM PRODUCTION.
#		if(1 == 1) {
#			print "@SubArgs\n";
#		} else {
#			system(@SubArgs) == 0 or die "ERROR: \'system> @Args\' failed: $?"; # Run the calculation as a system call. 
#		}
		
		system(@SubArgs) == 0 or $ErrMsg = "ERROR: Submission $File failed: $?. Line " . __LINE__; # Run the calculation as a system call. 
		if($ErrMsg ne "") {
			# Catch the error.
			LogMessage($ErrMsg, 1);
			print "$ErrMsg\n";
			exit;
		}
		
		unlink "Submission.sc" or $ErrMsg = "ERROR: Couldn't delete 'Submission.sc'. $!. Line " . __LINE__; # Tidy up by removing the redundant submission script.
		if($ErrMsg ne "") {
			# Catch the error.
			LogMessage($ErrMsg, 1);
			print "$ErrMsg\n";
			exit;
		}
} # END SubmitCalc()
