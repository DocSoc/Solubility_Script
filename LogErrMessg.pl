#! /usr/bin/perl

my $msg = "Balls!";


LogErrMessg($msg) if ($msg ne "");

sub LogErrMessg {
	# Reports an error message to both screen and LogFile.
		# Pass: Error Message.
		# Return: NONE.
		# Dependences: LogMessage().
		# Global Variables: NONE.
	# (c) David Hose. March, 2017.
	my $msg = $_[0];
	LogMessage("ERROR: $msg", 1); # Print error to the LogFile.
	print "ERROR: $msg\nTerminating script.\n\n";
	exit; # Hard exit.
}

sub LogMessage {
	print "";
}