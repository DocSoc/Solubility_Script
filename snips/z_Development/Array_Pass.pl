#! /usr/bin/perl

my @Big = (0,1,2,3,4,5,6,7,8,9,10);

my @BackEnd = ($Big[0], @Big[6..10]);
my @FrontEnd = ($Big[0], @Big[0..5]);

print "@BackEnd\n";

my @User = ((getpwuid($<))[0], (getpwuid($<))[6]);
print "@User\n";
