#!/usr/bin/python

import sys
import re
import numpy as np
import csv
import os

variables = []
targets = []
targets_arr = []
intermediaries = []

varmatch = re.compile("^[A-Z a-z 0-9]+=") # pattern - looking for ^VARIABLE=

targetmatch = re.compile("^.*:")          # pattern - looking for ^target: - this will be used to locate comments for targets AND intermediary files

leadingdot = re.compile("^\.")            # pattern - looking for ^. (.PHONY, .SECONDARY)

leadinghash = re.compile("^#([^?>\*!]|\s|$)")          
# looking for comment lines that do not begin with [#*, #?, #! or #>], i.e. ^# _followed by a space!_ or just ^#

alpharegex = re.compile("[^a-zA-Z]")    # used to strip non-alphabetic characters

def save_array(array, filen):
    """Save the array to the file, or save a placeholder if it is empty."""

    if len(array) > 0:
        if len(array) > 1:
            # can only sort arrays with more than one row
		# argsort sorts array by indices 
		# sort array vertically (across rows) 
		array = array[np.argsort(array[:, 0])]

        with open(filen, "wb") as F:
            writer = csv.writer(F, delimiter=";", lineterminator='\n')
            writer.writerows(array)
    else:
        with open(filen, "wb") as F:
            writer = csv.writer(F, delimiter=";", lineterminator='\n')
            writer.writerow("-;None found;-;-".split(';'))

def check_and_get_comment(startat, spliton):
    """Get all the comment lines, or return a filler message."""
    
    if "#*SKIP" not in linewise[startat - 1]: # comments are 1 line above the target/variable/etc
        if spliton in linewise[startat - 1]:   
            comment_list = []
            inc = 1
        
            while spliton in linewise[startat - inc]:
                comment_list.append(linewise[startat - inc][3:]) # remove the hashtag-symbol from the comment line and just append comment to the list
                inc += 1

            comment_list.reverse() # reverse because we are reading comments from the line right above target/variable, upwards
            comment = ' '.join(comment_list) # this takes the list and joins all lines in the comment together
            return comment
        else:
            return "No comment supplied"
    else:
        return None

def add_to_array(array, new):
    if array is not None:
        if len(array) == 0:
            array = new
        else:
            array = np.concatenate([np.array(array), np.array(new)])
        
        return array
    else:
        sys.exit("Array not initialized.")

files = sys.argv
del files[0] # the first element is 'makemakedoc.py'

for f in files:
    print("Python: Reading " + f)

    with open(f, 'r') as file_read:
        contents = file_read.read()

    # remove blank lines and lines starting with '# ' only
    linewise = filter(None, contents.splitlines()) # break contents of file into lines
    clines = filter(leadinghash.match, linewise) # return lines which do not start with '#'
    linewise = [x for x in linewise if x not in clines] # find lines that DO NOT start with [#*, #?, #! or #>]

    fbn = os.path.basename(f)
    fbn_safe = alpharegex.sub('', fbn)

    for i in range(0, len(linewise)):
        line = linewise[i]

        ## GET VARIABLES
        if varmatch.match(line):
		variable = line.rsplit('=')[0]
		if check_and_get_comment(i, "#!"):
			comment = check_and_get_comment(i, "#!")
                
                # rsplit works R2L so to get what follows the first '=',
                # we have to reverse, split, then take the first element of that
                # array, then reverse it so we have the result the right way 
                # round.
                	definition = line[::-1].rsplit('=', 1)[0][::-1]
                	variables = add_to_array(variables, [[variable, definition, 
                	comment, fbn, fbn_safe]])

	## GET TARGETS & INTERMEDIATES
	if ":" in line and "\t" not in line and "#*" not in line and targetmatch.match(line) and "export" not in line and "@echo" not in line:
		tmptarget = line.rsplit(':', 1)[0] # grab the name of the target/intermediary
		if ("/" in tmptarget and "#?" not in tmptarget) or ("%" in tmptarget and "#?" not in tmptarget):
			intermediary = tmptarget
			if check_and_get_comment(i, "#>"):
				intermediaries = add_to_array(intermediaries, [[intermediary, comment, fbn, fbn_safe]])
		if "/" not in tmptarget and "#>" not in tmptarget and "#?" not in tmptarget and "%" not in tmptarget:
			target = tmptarget
			if not leadingdot.match(line) and check_and_get_comment(i, "#?"):
				comment = check_and_get_comment(i, "#?")
				if "#>" not in comment: 
					targets_arr = add_to_array(targets_arr, [[target, comment, fbn, fbn_safe]])
			
save_array(variables, "variables.txt")
save_array(targets_arr, "targets.txt")
save_array(intermediaries, "intermediates.txt")