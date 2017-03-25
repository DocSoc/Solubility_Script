#! /usr/bin/perl

my @a1 = (4.3,0.2,7,2.2,0.2,2.4);
my @a2 = (2.2,0.6,5,2.1,1.3,3.2);
my @out = map { $a1[$_] - $a2[$_] } 0 .. $#a1;

print "Out: @out\n";
