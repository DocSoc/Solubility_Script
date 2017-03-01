#! /usr/bin/perl

@a = (1.23, "NA", 14.0, 3.0, "");
print "@a\n";
foreach my $i (@a) {print "<$i>\t"}
print "\n";

@b = sort @a;

print "@b\n";
foreach my $i (@b) {print "<$i>\t"}
print "\n";

@c = sort @a;
@c = grep /\S/, @c;

print "@c\n";
foreach my $i (@c) {print "<$i>\t"}
print "\n";


