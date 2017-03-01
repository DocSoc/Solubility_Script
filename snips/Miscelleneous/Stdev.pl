#! /usr/bin/perl

# Calculation of; Mean, Standard Deviation, RMSE and Number of Observations.

# Test data:
	my @dat = (32.95, 32.83, 33.52);
	#my @dat = (32.83, 33.52);
	#my @dat = (33.52);
	my @dat = (32.95, 32.83, 33.52, , 33);

# Test routines:
	# Mean:
		$mean = Mean(@dat);
		print "Mean is $mean\n";
	# Number of Observations:
		$obs = NObs(@dat);
		print "Observations is $obs\n";
	# Standard Deviation.
		$dev = StDev(@dat);
		print "Stdev is $dev\n";

exit;

### STATISTICAL SUBROUTINES ###

sub NObs {
	# Determine the number of values in the array.
	# Pass: Array of numbers.
	# Return: Number of entries in the array.
	# Dependences: None.
	# (c) David Hose Feb. 2017.
		my $nobs = scalar(@_);
		return $nobs;
} # END NObs()

sub Mean {
	# Calculate the mean.
	# Pass: Array of numbers.
	# Return: Calculate the mean of the entries in the array.
	# Dependences: NObs().
	# (c) David Hose Feb. 2017.
		my $m = 0;
		foreach $i (@_) {$m = $m + $i}
		$m = $m / NObs(@_);
		return (sprintf("%.2f", $m)); # Return value to 2 dp.
} # END Mean()

sub StDev {
	# Calculate the sample standard deviation.
	# Pass: Array of numbers.
	# Return: Calculate the sample standard deviation of the entries in the array.
	# Dependences: NObs() and Mean().
	# (c) David Hose Feb. 2017.
	if(NObs(@_) == 1) {
		# If the number of observations are 1, this leads to a div-by-zero error.
		# To prevent runtime errors return a StDev value of 0.
			return(0);
	} else {
		# Calculate the 'Sample' standard deviation.
		my $m = Mean(@_); # Calculate the mean.
		my $t = 0;
		foreach $i (@_) {$t = $t + ($i - $m)**2}
		my $stdev = sqrt($t / (NObs(@_) - 1));
		return (sprintf("%.2f", $stdev)); # Return value to 2 dp.
	}
} # END StDev()

sub RMSE {
	# Calculate the relative mean squared error.
	# Pass: Array of numbers.
	# Return: Calculate the Root Mean Square Error (aka population standard deviation) of the entries in the array.
	# Dependences: NObs() and Mean().
	# (c) David Hose Feb. 2017.
	my $m = Mean(@_); # Calculate the mean.
	my $t = 0;
	foreach $i (@_) {$t = $t + ($i - $m)**2}
	my $rmse = sqrt($t / NObs(@_));
	return (sprintf("%.2f", $rmse)); # Return value to 2 dp.
}
