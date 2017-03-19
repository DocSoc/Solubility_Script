#! /usr/bin/perl

# Create a message based upon the time of day.
$usr[2] = "Dick";
TimeSalute();
exit;

sub TimeSalute {
	# Create a message based upon the time of day.
		# Pass: NONE
		# Return: Greeting.
		# Dependences: NONE.
		# Global Variables: $usr[2].
	# (c) David Hose. March 2017.
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $TimeMsg;
	# Work out the peroid of the day.
		if($hour >= 7 && $hour < 8) {$TimeMsg = "A very early morning $usr[2]."}
		elsif($hour >= 8 && $hour < 12) {$TimeMsg = "Good morning $usr[2]."}
		elsif($hour >= 12 && $hour < 18) {$TimeMsg = "Good afternoon $usr[2]."}
		elsif($hour >= 18 && $hour < 20) {$TimeMsg = "Good evening $usr[2]."}
		else {$TimeMsg = "Weird time of day $usr[2]!"}
	# Add any special messages.
		if($wday >= 6) {$TimeMsg = $TimeMsg . " Why are you working at the weekend? Do I need to email your manager?!"}
		if($wday == 1 && $hour >= 7 && $hour < 12) {$TimeMsg = $TimeMsg . " Don't you just hate Monday mornings!"}
		if($wday == 5 && $hour >= 12 && $hour < 16) {$TimeMsg = $TimeMsg . " It's POETS day!"}
		if($wday == 5 && $hour >= 16) {$TimeMsg = $TimeMsg . " It's Friday night! GO HOME!"}
	# Output the message.
		print "$TimeMsg\n";
} # END TimeSalute()

