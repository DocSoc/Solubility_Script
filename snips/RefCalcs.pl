#! /usr/bin/perl


		# Get the solvent numbers.
			my @RefSolvsID;
			for(my $i = 0; $i < $RefSolNum; $i++) {$RefSolvsID[$i] = $RefSolub[$i][1]} # Pull back the reference solvent IDs.
		# Loop through the list of solvents and deterine the DGfus values.
		print "\tFree-Energy of Fusion Calculations.\n";
		$LocalSolv = 1;
		foreach my $CurrSolv (@RefSolvsID) {
			$CurrFile = sprintf("Gfus%.3d", $CurrSolv);
			$CurrSolvName = ${$Solvents{$CurrSolv}}[0];
			print "\t\tFile: $CurrFile\tReference Solvent: '$CurrSolvName'.\n";
			open (FH_OUTPUT, ">$CalcsDir/Ref/$CurrFile.inp") or die "Can't open Reference Calculation File. $!\n";
			# Write ctd line.
			COSMO_Files ($ctd, $cdir, $ldir); # Add ctd parameters, directory and license locations.
			COSMO_Print(1); # Gfus Print options.
			COSMO_Comment(1, $CurrSolv);
			COSMO_Solute(1,$Solute);
			COSMO_Solv($CurrSolv);
			
			$Curr_Ref_Solub = $RefSolub[$$LocalSolv][8]; # Pull back the correct solubility for the current solvent.
			print "Solubility = $Curr_Ref_Solub\n";
			COSMO_Route(1); # Add Option 1 (Gfus) Routecard.
			close FH_OUTPUT; # Close the Current Reference Solvent COSMOtherm .INP file.
			# Run/Submit Calculation.
				if($Cluster == 0) {
					COSMO_Submit(1); # COSMOtherm calculation run locally. (Will wait until calculation returns).
				}
				elsif($Cluster == 1) {
					COSMO_Submit(2); # COSMOtherm calculation submitted to cluster. (Moves on before calculations are complete).
				}
				else {
					# No calculations are run.  DEVELOPMENT.
				}
		
		
		
		
		
		
		
		$LocalSolv++;
		} # END foreach loop for @RefSolvsID.
