#! /usr/bin/perl

@List = (19,22,23,41,55,67,72,85,99);
#@CurrList;

#for (my $i = 0; $i < scalar(@List); $i++) {
#	@CurrList = @List;
#	$Element = splice @CurrList, ($i), 1;
#	print "New List is: @CurrList\t The Element is <$Element>\n";
#}

my %hash =	(
							19 => [1, "A"],
							22 => [2, "B"],
							23 => [3, "C"],
							41 => [4, "D"],
							55 => [5, "E"],
							67 => [6, "F"],
							72 => [7, "G"],
							85 => [8, "H"],
							99 => [9, "I"]
						);

@Array = @{$hash{19}}[1];
#print  "@Array\n";
@Array = undef;
foreach $i (@List) {
	print "@{$hash{$i}}[1]\n";
	push (@Array, @{$hash{$i}}[1]);
}
shift @Array;
print  "@Array\n";


