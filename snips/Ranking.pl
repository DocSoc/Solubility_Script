#! /usr/bin/perl

#my %data = (
#      'slashdot.org' => 180,
#      'cpan.org'     => 150,
#      'perl.com'     => 150,
#      'apache.org'   => 120,
#  );
#my @keys = keys %data;
#
## invert the %data hash, creating arrayrefs each with list
## of elements with the same ranking
#my %ranks;
#push @{$ranks{$data{$_}}}, $_ for @keys;
#
## count/sort the rankings
#my @ranks = reverse sort {$a<=>$b} keys %ranks;
#
#for my $rank ( 0 .. $#ranks ) {  # print them
#  my @tied = @{$ranks{ $ranks[$rank] }};
#  if (@tied > 1) {  # more than one with this ranking
#    local $"=', ';
#    my $last = pop @tied;
#    print "@tied and $last all have rank ". 1+$ranks[$rank] ."\n";
#  } else {
#    print "@tied has rank ". 1+$ranks[$rank] ."\n";
#  }
#}
#
#my %data = ( 
#      'slashdot.org' => 180, 
#      'cpan.org' => 150, 
#      'perl.com' => 150, 
#      'apache.org' => 120, 
#  );
#my @ranks; my @keys = keys %data;
#@ranks[ sort { $data{$keys[$b]} cmp $data{$keys[$a]} } 0..$#keys ] = 1..@keys;
#print "key $keys[$_] has rank $ranks[$_]\n" for 0..$#ranks;

my @unsorted = ( ["Harry", 10.021], ["Joe", 2.1], ["Bob", 3.56] , ["Mary", 3.23] ); # Simple 2D array.
#my @unsorted = ( [1, 10.021], [2, 2.1], [3, 3.56] , [4, 3.23] ); # Simple 2D array.

my @sorted = sort { $a->[1] <=> $b->[1] } @unsorted; # Sort he data based upon the number in index 1.

for ($i=0; $i<4; $i++) {
print "$unsorted[$i][0]\t$unsorted[$i][1]\n";
}
print "\n";
for ($i=0; $i<4; $i++) {
print "$sorted[$i][0]\t$sorted[$i][1]\n";
}












