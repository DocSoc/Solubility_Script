#! /usr/bin/perl

# Say Hello.

sub Hello {
print <<ENDHELLO;

			                       ( ~!~ ~!~ )
			.-----------------oOOo----(_)----oOOo--------------------------.
			|                                                              |
			|                   A Perl Script for:                         |
			|                                                              |
			| ..--**  **--.. |
			| ..--**  **--.. |
			|                                                              |
			| Version 0.1                                                  |
			| Author David Hose                                            |
			| (c) March 2017                                               |
			|                      .oooO                                   |
			|                      (   )   Oooo.                           |
			.-----------------------\\ (----(   )---------------------------.
			                         \\_)     ) /
			                               (_/

ENDHELLO
} # END Hello()

sub Goodbye
{
print <<ENDGOODBYE;
	Script completed. Goodbye.

ENDGOODBYE
} # END Goodbye()

sub Usage {
print <<ENDUSAGE;

		                       ..--** Sobubility.pl **--..

	This script takes lists of Solvent and Solutes and sets up COSMOtherm
	input file for the calculation of infinite dilution partition
	coefficents of the Solutes in the Solvent - Water mixtures.
	The script runs each of the partition calculations and compiles the results.

	Solubility.pl [--help]

	Switches:

		--help : This help page.
		
	See supporting documentation for further details.

	Warning: Only limited error checking has been implimented.

	Version 0.1
	(c) David Hose, March, 2017.

ENDUSAGE
exit;
}