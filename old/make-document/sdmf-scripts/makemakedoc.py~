#!/usr/bin/python

import sys
import re
import numpy as np
import csv

variables = []
phonies = []
phonies_arr = []
targets = []

varmatch=re.compile("^[A-Z a-z 0-9]+=")
targetmatch=re.compile("^.*:")
leadinghash=re.compile("^#\s*.*")

files=sys.argv
del files[0]

for f in files:
    print f
    with open(f, 'r') as file_read:
        contents = file_read.read()

    linewise=filter(None, contents.splitlines())

    print linewise[0]

    for i in range(0, len(linewise)):
        line=linewise[i]
        comment=''

        ## GET VARIABLES
        if varmatch.match(line):
            # get the names of the variables
            variable=line.rsplit('=', 1)[0]
            
            # get the comment if there is any
            if '#!' in line:
                definition=line.rsplit(' #! ', 1)[0]
                comment=line.rsplit(' #! ', 1)[1]
                comment = re.sub(";", ",", comment)
            else:
                definition=line.rsplit('=', 1)[1]
                comment="No comment supplied."
        
            arr = np.array([[variable, definition, comment, f]])

            if len(variables) is 0:
                variables = arr
            else:
                variables = np.concatenate((variables, arr))
        
        # GET (INTERACTIVE) TARGETS
        if len(phonies) is 0:
            if ".PHONY:" in (line):
                phonies=line.split()
                del phonies[0]
        
        # GET (INTERMDIATE) TARGETS
        if ':' in line and '\t' not in line and '#' not in line:
            target=line.rsplit(':', 1)[0]

            if target in phonies and target is not ".PHONY" and target is not ".SECONDARY":
                if "#?" in linewise[i-1]:
                    comment = re.sub("#\\? *", "", linewise[i-1])
                    comment = re.sub(";", ",", comment)
                else:
                    comment="No comment supplied."
                temp_arr = np.array([[target, comment, f]])
                if len(phonies_arr) is 0:
                    phonies_arr = temp_arr
                else:
                    phonies_arr = np.concatenate([phonies_arr, temp_arr])
            else:
                if "#>" in linewise[i-1]:
                    comment=re.sub("#> *", "", linewise[i-1])
                    comment = re.sub(";", ",", comment)
                else:
                    comment="No comment supplied."
                if len(targets) is  0:
                    targets = np.array([[target, comment, f]])
                else:
                    targets = np.concatenate([targets, np.array([[target, comment, f]])])


with open("variables.txt", "wb") as v:
    writer = csv.writer(v, delimiter=";", lineterminator='\n')
    writer.writerows(variables)

with open("targets.txt", "wb") as t:
    writer = csv.writer(t, delimiter=";", lineterminator='\n')
    writer.writerows(phonies_arr)

with open("intermediates.txt", "wb") as i:
    writer = csv.writer(i, delimiter=";", lineterminator='\n')
    writer.writerows(targets)
