#! /usr/bin/perl


$String = "Glyme [DME or 1,2-Dimethoxyethane]";


$String =~ s/\s\[.+\]//g; # Removes the [....] section of the string.
print "$String\n";
