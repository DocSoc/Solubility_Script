#! /usr/bin/perl

@Solubs = (0.2, 0.9999, 1, 1.1, 9.5, 10, 10.1, 25, 30, 31, 99, 100, 101, 999.9, 1000, 1000.1, 9999, 10000, 10001, 12300);

foreach my $SolRV (@Solubs) {
	my ($ClassType, $ClassRef) = SolubClass($SolRV);
	print "For $SolRV:\tClass is: $ClassType ($ClassRef).\n";
	$test = Convgg2RV($SolRV);
	print "$test\n";
}


exit;

sub SolubClass {
	# Determines the USP solubility class.
		# Pass: Solubility in mL per g.
		# Return: ClassText and ClassNum.
		# Dependences: NONE.
		# Global Variables: NONE.
	# (c) David Hose. March 2017.
	my @Class;
	if($_[0] < 1) 												{@Class = ("Very Soluble", 1)}
	elsif($_[0] >=    1	&& $_[0] <    10) {@Class = ("Free Soluble", 2)}
	elsif($_[0] >=   10	&& $_[0] <    30) {@Class = ("Soluble", 3)}
	elsif($_[0] >=   30	&& $_[0] <   100) {@Class = ("Sparingly Soluble", 4)}
	elsif($_[0] >=  100 && $_[0] <  1000) {@Class = ("Slightly Soluble", 5)}
	elsif($_[0] >= 1000 && $_[0] < 10000)	{@Class = ("Very Slightly Soluble", 6)}
	else 																	{@Class = ("Insoluble", 7)}
	return(@Class);
} # END SolubClass()

sub Convgg2RV {
	# Convert solubility from g per g to relative volumes.
		# Pass: Solubility in g/g.
		# Return: Solubility in RV.
		# Dependences:
		# Global Variables:
	# (c) David Hose. March 2017.


	return($_[0]**-1);
} # END Convgg2RV()
