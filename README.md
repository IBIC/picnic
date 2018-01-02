# IBIC picnic

**Self-documenting makefiles!**

## Getting started
1. For picnic to work, you need 3 scripts:
    + *picnic*
    + *picnic-makedoc.py*
    + *picnic-tables.tex*
1. picnic is installed on IBIC machines by default in `/mnt/home/ibic/bin/picnic`, which should be a part of your path.
1. If it isn't, you can either clone this GitHub repository into your home directory or simply copy the above 3 scripts into a new directory under your home directory and add that directory to your path.

To quickly use use picnic on one or more Makefile, type:

    picnic makefile(s)

## Advanced Options

There are two ways to invoke picnic, with explicit list of makefiles (file globs are acceptable) and by giving it a path to a directoroy full of makefiles (this option is less tested).

    picnic <options> path/to/makefile another/path/makefile ...
    picnic <options> -D path/to/makefiles

Furthermore, picnic accepts a number of command line arguments, listed below and discussed further after the list.

    -o  Provide an output name for the .pdf.
    -d  Provide a filename with documentation for the project.
    -e  Exclude files matching given regex (for use with `-D').
    -n  Disable links in the PDF.
    -v  Verbose: Don't silence pdfLaTeX output, also keep intermediate files.
    -h  Show this screen.

**Set a filename** Give picnic a one-word filename. If none is given, picnic will name the output after your file if there is only one, or will name it "makedocumentation.pdf" if there is more than one input file. ".pdf" is automatically added to the output, but picnic will accept inputs with ".pdf" without naming the output ".pdf.pdf."

**Documentation** Documentation files contain a text paragraph with information on the makefile, useful for putting together at the end of the project.

**Exclude regex** When using the -D option, exclude files that match a given regex. 

**Disable links** On occasion, LaTeX document links will be problematic. If you don't want to mess around with LaTeX, add this option to get a barebones, but funtional PDF.

**Verbose** When verbose mode is on, messages from subscripts aren't silenced, and you can see what they're doing. As well, intermediate files aren't deleted. Useful for debugging.

**Help** Shows the help menu.

## Quick Commenting Reference

| **Makefile Element**              | **Picnic Comment Code** |
|-----------------------------------|-------------------------|
| Target (in .PHONY)                | `#!`                    |
| Variable                          | `#?`                    |
| Intermediate file (not in .PHONY) | `#>`                    |
| Functions                         | `$@`                    |
| **Directives**                    |                         |
| *Skip whole file*                 | `#*NODOC`               |
| *Skip this element*               | `#*SKIP`                |
