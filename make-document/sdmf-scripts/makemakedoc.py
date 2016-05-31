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

varmatch=re.compile("^[A-Z a-z 0-9]+=")
targetmatch=re.compile("^.*:")
leadingdot=re.compile("^\.")
leadinghash=re.compile("^#")

def savestring( array, filen ):
    if len(array) is not 0:
        array = array[array[:,0].argsort()]
        with open(filen, "wb") as F:
            writer = csv.writer(F, delimiter=";", lineterminator='\n')
            writer.writerows(array)
    else:
        with open(filen, "wb") as F:
            writer = csv.writer(F, delimiter=";", lineterminator='\n')
            writer.writerow("-;None found;-".split(';'))


files=sys.argv
del files[0] # the first element is 'makemakedoc.py'

print "Python: Files: " + '\t'.join(files)

for f in files:
    print "Python: Reading " + f
    with open(f, 'r') as file_read:
        contents = file_read.read()

    linewise=filter(None, contents.splitlines()) # remove blank lines

    fbn = os.path.basename(f)

    for i in range(0, len(linewise)):
        line=linewise[i]
        comment=''

        ## GET VARIABLES
        if varmatch.match(line):
            # get the names of the variables
            variable=line.rsplit('=', 1)[0]
            
            # get the comment if there is any
            if '#!' in line:
                comment = line.split('#!', 1)[1]
                definition = line.split('#!', 1)[0].rsplit('=', 1)[1]
                comment = re.sub(";", ",", comment)
            else:
                if '#!' in linewise[i-1]:
                    comment=line.rsplit('#! ', 1)[1]
                else:
                    comment="No comment supplied."
                definition=line.rsplit('=', 1)[1]
        
            arr = np.array([[variable, definition, comment, fbn]])

            if len(variables) is 0:
                variables = arr
            else:
                variables = np.concatenate((variables, arr))
                    
        # GET (INTERACTIVE) TARGETS
        if ".PHONY:" in line:
            if len(phonies) is 0:
                phonies = line.split()
                del phonies[0]
                print phonies
            else:
                phonies_temp = line.split()
                del phonies_temp[0]
                phonies = phonies + phonies_temp
        
        # GET (INTERMEDIATE) TARGETS
        if ':' in line and '\t' not in line and not leadinghash.match(line):
            target=line.rsplit(':', 1)[0]
            
            if not leadingdot.match(target):
                if target in phonies:
                    if "#?" in linewise[i-1]:
                        comment = re.sub("#\\? *", "", linewise[i-1])
                        comment = re.sub(";", ",", comment)
                    else:
                        comment="No comment supplied."
                    
                    temp_arr = np.array([[target, comment, fbn]])
                    if len(phonies_arr) is 0:
                        phonies_arr = temp_arr
                    else:
                        phonies_arr = np.concatenate([phonies_arr, temp_arr])
                else:
                    if "#>" in linewise[i-1]:
                        comment = re.sub("#> *", "", linewise[i-1])
                        comment = re.sub(";", ",", comment)
                    else:
                        comment = "No comment supplied."

                    if len(targets) is 0:
                        targets = np.array([[target, comment, fbn]])
                    else:
                        targets = np.concatenate([targets, np.array([[target, comment, fbn]])])

savestring(variables, "variables.txt")
savestring(phonies_arr, "targets.txt")
savestring(targets, "intermediates.txt")
