#! /usr/bin/perl

@A = (6,5,4,3,2,1,10);
@B = (1,2,3,4,5,6,7,8,9);
@seen{@A} = ();
@merged = (@A, grep{!exists $seen{$_}} @B);
@merged = sort { $a <=> $b } @merged;
foreach $i (@merged) {print "$i\n"}
print @merged;