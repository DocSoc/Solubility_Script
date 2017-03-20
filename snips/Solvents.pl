


# Read the SOLVENTS file and create the COSMOtherm INP file.

	# Insert file/path/conformer information of the SOLVENT that is to be used in the Partitioning Calculations.
		$First = lc(substr($TEMP[$File_Pos], 0, 1));	# Grab the first character of the name (of sub-folder) and ensures that it's in lower case.
		# Determine how many conformers that the Solvent has and process appropriately.
		# For a single conformer.
			if ($TEMP[$Conf_Pos[$Level]] == 1) {
				print FH_OUTPUT "f = $TEMP[$File_Pos]_c0.$TEMP[$Ext_Pos[$Level]] fdir=\"$fdir[$TEMP[$DB_Pos[$Level]]][1]$First\" Comp = $TEMP[$File_Pos] \n"
			}
		# For multiple conformers (COSMOconf produces a maximum of 10 conformers _c0 to _c9).
			if ($TEMP[$Conf_Pos[$Level]] > 1) {
				print FH_OUTPUT "f = $TEMP[$File_Pos]_c0.$TEMP[$Ext_Pos[$Level]] fdir=\"$fdir[$TEMP[$DB_Pos[$Level]]][1]$First\" Comp = $TEMP[$File_Pos] [\n";
				for ($conf = 1; $conf < ($TEMP[$Conf_Pos[$Level]] - 1); $conf++) {
					print FH_OUTPUT "f = $TEMP[$File_Pos]_c$conf.$TEMP[$Ext_Pos[$Level]] fdir=\"$fdir[$TEMP[$DB_Pos[$Level]]][1]$First\"\n"
				}
				$lastconf = $conf;
				print FH_OUTPUT "f = $TEMP[$File_Pos]_c$lastconf.$TEMP[$Ext_Pos[$Level]] fdir=\"$fdir[$TEMP[$DB_Pos[$Level]]][1]$First\" ]\n";
			} 


# Run the newly created COSMOtherm INPUT file.
#@Args = ("cosmotherm", "COSMOthermData/$Fileinput.inp"); # The arguments for the system call.
#print " ... Running.\n"; # Inform the user that the calculations are being run.
#system(@Args); # Run the calculation as a system call.


	
