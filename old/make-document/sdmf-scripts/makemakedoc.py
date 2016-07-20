#!/usr/bin/python

import sys
import re
import numpy as np
import csv
import os

variables = []
phonies = []
phonies_arr = []
targets = []

varmatch=re.compile("^[A-Z a-z 0-9]+=") # looking for ^VARIABLE=

targetmatch=re.compile("^.*:")          # looking for ^target:

leadingdot=re.compile("^\.")            # looking for ^. (.PHONY, .SECONDARY)

leadinghash=re.compile("^#([^?>\*!]|\s|$)")          
# looking for comment lines, ^# _followed by a space!_

alpharegex=re.compile("[^a-zA-Z]")    # used to strip non-alphabetic characters


def save_array(array, filen):
    """Save the array to the file, or save a placeholder if it is empty."""

    if len(array) > 0:
        if len(array) > 1:
            # can only sort arrays with more than one row
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
    
    if "#*SKIP" not in linewise[startat - 1]:
        if spliton in linewise[startat - 1]:   
            comment_list=[]
            inc=1
        
            while spliton in linewise[startat - inc]:
                comment_list.append(linewise[startat - inc][3::])
                inc += 1

            comment_list.reverse()
            comment=' '.join(comment_list)

            comment=comment.replace(';', ',')

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
            array = np.concatenate([array, np.array(new)])
        
        return array
    else:
        sys.exit("Array not initialized.")


files=sys.argv
del files[0] # the first element is 'makemakedoc.py'

# print("Python: Files: " + '\t'.join(files))

for f in files:
    print("Python: Reading " + f)

    with open(f, 'r') as file_read:
        contents = file_read.read()

    # remove blank lines and lines starting with '# ' only
    linewise = filter(None, contents.splitlines())
    clines = filter(leadinghash.match, linewise)
    linewise = [x for x in linewise if x not in clines]

    fbn = os.path.basename(f)
    fbn_safe = alpharegex.sub('', fbn)

    for i in range(0, len(linewise)):
        line=linewise[i]

        ## GET VARIABLES
        if varmatch.match(line):
            variable=line.rsplit('=')[0]

            if check_and_get_comment(i, "#!"):
                comment = check_and_get_comment(i, "#!")
                
                # rsplit works R2L so to get what follows the first '=',
                # we have to reverse, split, then take the first element of that
                # array, then reverse it so we have the result the right way 
                # round.
                definition=line[::-1].rsplit('=', 1)[0][::-1]

                variables = add_to_array(variables, [[variable, definition, 
                	comment, fbn, fbn_safe]])

        # GET (INTERACTIVE) TARGETS
        if ".PHONY:" in line:
            if len(phonies) == 0:
                phonies = line.split()
                del phonies[0]
            else:
                phonies_temp = line.split()
                del phonies_temp[0]
                phonies = phonies + phonies_temp
        
        # GET (INTERMEDIATE) TARGETS
        if ':' in line and '\t' not in line and not leadinghash.match(line) \
        and "#*" not in line: 
            target=line.rsplit(':', 1)[0]
            
            # if this isn't the .PHONY line and we're not exporting a variable
            if not leadingdot.match(target) and not "export" in target and \
            not "@echo" in target:
                if target in phonies:
                    # if this is a phony target, add to phonies
                    if check_and_get_comment(i, "#?"):
                        comment = check_and_get_comment(i, "#?")
                        phonies_arr = add_to_array(phonies_arr, [[target, 
                        	comment, fbn, fbn_safe]])
                else:
                    # if it's not phony, add to secondary targets
                    if check_and_get_comment(i, "#>") is not None:
                        comment = check_and_get_comment(i, "#>")
                        targets = add_to_array(targets, [[target, comment, fbn, 
                        	fbn_safe]])

save_array(variables, "variables.txt")
save_array(phonies_arr, "targets.txt")
save_array(targets, "intermediates.txt")