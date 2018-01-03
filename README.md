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

## Documenting a makefile

The real utility of picnic comes from having makefiles that are documented in the proper format. The basic format of a picnic comment is as follows:

    #<symbol> A comment about this thing
    [A make line]

In other words, a comment on a variable would look something like this:

    #! Use only one CPU to prevent parallelization issues
    OMP_NUM_THREADS=1

Picnic comments need to be directly above the line they refer to. Picnic ignores completely empty lines but for readabilty I suggest that they are directly above (as in the examples above.)

Multiple-line comments are possible; however linebreaks are lost.

Note that picnic does do some minor editing of comments to ensure that they aren't gobbled later on, for example semicolons are replaced with commas in all comments. 

Below is a table of the four commenting choices, which can be used to document **targets** (that is, anything that is a "dependency" to .PHONY and would be called on the command line); **variables**; intermediate files (real files that may or may not be deleted make finishes executing); and **functions** which are defined by `define func = ... enddef`.

Finally, you can also add a paragraph-length introduction to the makefile, usually at the beginning of the file, like so:

    #* This Makefile takes the Fisher Z-transformed single-subject correlation maps
    #* for PD and control subjects and runs AFNI 3dttest++ on them to get group
    #* differences and the mean and z-stats for the two groups.
    #* It uses 3dAFNItoNIFTI to separate the difference and within-group images from
    #* their HEAD/BRIK files.

    #! Project root directory
    PROJECT_DIR=/mnt/praxic/pdnetworksr01

    ...


### Quick Commenting Reference

| **Makefile Element**              | **Picnic Comment Code** |
|-----------------------------------|-------------------------|
| Target (in .PHONY)                | `#?`                    |
| Variable                          | `#!`                    |
| Intermediate file (not in .PHONY) | `#>`                    |
| Functions                         | `#@`                    |
| Header                            | `#*`                    |
| **Directives**                    |                         |
| *Skip whole file*                 | `#*NODOC`               |
| *Skip this element*               | `#*SKIP`                |

As noted in the above table, there are two "directives," which direct picnic to either ignore the file entirely (if it's passed in as part of a file glob, for example), or to skip the immediately following element. 

### Other notes

One major undeveloped feature is dealing with elements that appear twice in a makefile due to logic blocks.

For example:

    ifeq ($(wildcard mcvsa/mcvsa_e001.nii.gz),)
    mcvsa-AFNI:

    else
    mcvsa-AFNI: mcvsa.results/stats.mcvsa+orig.BRIK mcvsa-stats

    endif

The goal of this code is to change what `make mcvsa-AFNI` does depending on whether the file `mcvsa/mcvsa_e001.nii.gz`. Whether or not this works well, it has the side effect of picnic picking up both of the `mcvsa-AFNI` targets, duplicating them in the output PDF.

I haven't decided on a solution to this yet; one option is to ignore the second target, or there could be functionality for documenting `ifeq` blocks to identify what their purpose is.

As it stands, you can use `#*SKIP` to ignore the second target (or variable) if having both bothers you. 