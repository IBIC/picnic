#!/usr/bin/python

import re
import itertools as it

lh=re.compile("^#([^?>*!]|\s|$)")

with open("file", 'r') as file_read:
    contents=file_read.read()

linewise = filter(None, contents.splitlines())
clines = filter(lh.match, linewise)

linewise = [x for x in linewise if x not in clines]

print(linewise)

exit()

def get_ml_comments( lines, startat ):
    """Get all the comment lines preceding a target"""
    comment_list=[]
    inc=1
    while "#>" in lines[startat - inc]:
        comment_list.append(re.sub("#> *", "", lines[startat - inc]))
        inc += 1
    comment_list.reverse()
    return(' '.join(comment_list))

for i in range(0, len(linewise)):
    line=linewise[i]

    comment_list=[]
    if ':' in line:
        print(get_ml_comments(linewise, i))
