#use strict;
#use warnings;
#use 5.010;
 
my $filename = "Filenaming.txt";
my $size = -s $filename;
print "The size of '$filename' is $size bytes.";