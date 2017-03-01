#! /usr/bin/perl

@Data = (1,2,32.1,33.1,"na");


@Sol = undef;

foreach $i (@Data[2..4]) {
	if($i =~ /\d+|\d+.\d+/) {push @Sol, $i}
}
print "@Data[2..4]\n";
print "@Sol\n";
shift @Sol; # Discard blank.

my @Big = (0,1,2,3,4,5,6,7,8,9,10);
my @FrontEnd = @Big[0..5];
my @BackEnd = ($Big[0], @Big[6..10]);

print "BackEnd is @BackEnd\n";

