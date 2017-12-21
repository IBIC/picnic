#!/usr/bin/python

# Read in the makefiles, parse them, write out information to intermediate
# files, which are manipulated into LaTeX. Clean up when done.

import sys
import re
import numpy as np
import csv
import os
import argparse as ap

parser = ap.ArgumentParser(description="Parse makefile(s).")
parser.add_argument("file", nargs="*")
parser.add_argument("-v", "--verbose", action="store_true")

args = parser.parse_args()

# print(args)

variables = []
targets = []
targets_arr = []
intermediaries = []
functions_arr = []

# pattern - looking for ^VARIABLE=
## skips lines with leading hashes and spaces (comments)
## stop at first equals sign
varmatch = re.compile("^[^#=\s]+={1}")

# pattern - looking for ^target:
## this will be used to locate comments for targets AND intermediary files
## skips lines with a leading literal dot (.PHONY/.SECONDARY)
targetmatch = re.compile("^[^\.].*:")

# pattern - looking for ^. (.PHONY, .SECONDARY)
leadingdot = re.compile("^\.")

# function match - look for define
functionmatch = re.compile("^define \S+ =")

# pattern - identify list of phony targets
phony = re.compile("^\.PHONY:")

# looking for comment lines that do not begin with [#*, #?, #! or #>],
## i.e. ^# _followed by a space!_ or just ^#
leadinghash = re.compile("^#([^?>\*!@]|\s|$)")

# used to strip non-alphabetic characters
alpharegex = re.compile("[^a-zA-Z]")

# skip anything that looks like a comment, picnic or not
commenthash = re.compile("^#")

def save_array(array, filen):
    """Save the array to the file, or save a placeholder if it is empty."""

    if len(array) > 0:
        if len(array) > 1: # (can only sort arrays with more than one row)
            # Sort vertically by indices:
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

    # comments are 1 line above the target/variable/etc
    if "#*SKIP" not in linewise[startat - 1]:
        if spliton in linewise[startat - 1]:
            comment_list = []
            inc = 1

            while spliton in linewise[startat - inc]:
                # remove the hashtag-symbol from the comment line and just
                ## append comment to the list
                comment_list.append(linewise[startat - inc][3:])
                inc += 1

            # reverse because we are reading comments from the line right above
            ## target/variable, upwards
            comment_list.reverse()

            # this takes the list and joins all lines in the comment together
            comment = ' '.join(comment_list)

            # replace semicolons with commas because they cause problems in the
            ## csv export
            comment = comment.replace(';', ',')

            return comment
        else:
            return "No comment supplied."
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

if (args.verbose):
    print(args.file)

for f in args.file:
    print("Python: Reading " + f)

    with open(f, 'r') as file_read:
        contents_breaks = file_read.read()
        # Remove \-terminated lines and make them one line
        contents = re.sub(r"\\\n", '', contents_breaks)

    # remove blank lines and lines starting with '# ' only
    # break contents of file into lines
    linewise = filter(None, contents.splitlines())

    # return lines which do not start with '#'
    clines = filter(leadinghash.match, linewise)

    # find lines that DO NOT start with [#*, #?, #! or #>]
    linewise = [x for x in linewise if x not in clines]

    phony_i = [i for i, val in enumerate(linewise) if phony.match(val)]

    if len(phony_i) == 0:
        print("Python: No targets identified in file " + f + ". Skipping.")
        break
    elif len(phony_i) > 1:
        # this hasn't been tested
        print("Python: Picnic has identified multiple .PHONY declarations" + \
            "in your makefile. Please fix this. Printing offending lines" + \
            "and skipping.")
        for i in phony_i:
            print(linewise[i])
        break
    else:
        # get the actual line from the textfile, remove '.PHONY:'
        phony_l = re.sub("^\.PHONY:", "", linewise[phony_i[0]])
        # turn the string into a list of targets
        targets = phony_l.split()

    fbn = os.path.basename(f)
    fbn_safe = alpharegex.sub('', fbn)

    for i in range(0, len(linewise)):
        line = linewise[i]

        ## GET VARIABLES
        if varmatch.match(line):
            # Get everything left of the `=' and strip trailing whitespace
            variable = line.split('=')[0].strip()


            # Remove leading ``export '' if present
            if re.match("^export ", variable):
                # add leading `*' to global variables
                variable = "* " + re.sub("^export ", "", variable)
                is_global = " (available to sub-makes)"
            else:
                is_global = ""

            if check_and_get_comment(i, "#!"):
                comment = check_and_get_comment(i, "#!") + is_global

                # rsplit works r2l, so to get what follows the first '=', we
                ## have to reverse, split, then take the first element of that
                ## array, then reverse it so we have the result the right way
                ## round.
                definition = line[::-1].rsplit('=', 1)[0][::-1]
                variables = add_to_array(variables, [[variable, definition,
                    comment, fbn, fbn_safe]])

            # If it's a variable, don't also check whether it's a target.
            continue

        ## GET TARGETS & INTERMEDIATES
        if (":" in line and
            "^\t" not in line and
            "#*" not in line and
            not commenthash.match(line) and
            targetmatch.match(line) and
            "export" not in line and
            "@echo" not in line):

            # grab the name of the target/intermediary
            tmptarget = line.rsplit(':', 1)[0]
            tmptarget = line.split(':')[0]

            # is the target/intermediary in question in the targets list?
            if any(tmptarget in s for s in targets):
                target = tmptarget.strip()
                if (args.verbose):
                    print(target + " is a target.")
                if (not leadingdot.match(line) and
                    check_and_get_comment(i, "#?")):

                    comment = check_and_get_comment(i, "#?")
                    if "#>" not in comment:
                        targets_arr = add_to_array(targets_arr,
                            [[target, comment, fbn, fbn_safe]])

            # if it's not, it must be an intermediary
            else:
                intermediary = tmptarget.strip()
                if (args.verbose):
                    print(intermediary + " is an intermediate file.")
                if check_and_get_comment(i, "#>"):
                    comment = check_and_get_comment(i, "#>")
                    # This loop accounts for targets that specify multiple
                    ## files.
                    for i in intermediary.split():
                        intermediaries = add_to_array(intermediaries,
                            [[i, comment, fbn, fbn_safe]])

        ## GET FUNCTIONS
        if functionmatch.match(line):
            functionname = line.split(' ')[1]

            if (args.verbose):
                print(functionname + " is a function.")

            if check_and_get_comment(i, "#@"):
            	comment = check_and_get_comment(i, "#@")

            	functions_arr = add_to_array(functions_arr,
            		[[functionname, comment, fbn, fbn_safe]])


save_array(variables, "variables.txt")
save_array(targets_arr, "targets.txt")
save_array(intermediaries, "intermediates.txt")
save_array(functions_arr, "functions.txt")
