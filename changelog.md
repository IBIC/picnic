IBIC picnic changelog

# Updates

## January 2, 2018 v 2.3

+ Fixed crash when supplying absolute path to makefiles (7/13/17)
+ Fixed bug in reading lines with tabs as indent (12/20/17)
+ Add function documentation (12/20/17)
+ Output automatically named after input if there is only one input file (1/2/18). Bug fixed 1/3/18.
+ Cleaned up old files (1/3/18)


## May 15, 2017 v 2.2

* Picnic would fail if the document so happened to be organized in such a way that the external hyperlink to the GNU Make manual was split across multiple elements. I added two workarounds to fix that: A `-n` flag that disables links across the whole document, as well as changing the link from the full text "5.7.2 Communicating Variabes to a Sub-make" to a small, Wikipedia-like external link icon.

## December 20, 2016 v 2.1

+ `picnic` filters "`export`" out of global variable declaration, and notes them in the pdf.
Also added explanatory notes to the "Variables" section header.

## December 19, 2016 v. 2.0

+ `picnic` now more intelligently identifies targets/intermediaries by looking at the dependencies of `.PHONY`. This means you have to be more careful about identifying your targets as phony, but they should all be anyway.
+ Trailing whitespace is stripped from variables/targets/intermediaries. 
+ `makemakedoc.py`, `picnic` conformed to 80 chars wide. `tables.tex` already was.
+ Information about verboseness is passed to Python. It will display the file list and identify targets/intermediaries. More functionality can be added. 

## July 19, 2016 v 1.1
Moved files from version 1.0 to directory /old. 

Fixed some bugs (all updated scripts, namely: *picnic*, *makemakedoc.py* and *tables.tex*, are now in the main directory of the Github  repository)
+ picnic can now parse semicolons in comments
+ default name of output file changed to 'makedocumentation.pdf' instead of 'tables.pdf'
+ picnic should now be able to properly discriminate between higher-level targets (such as those listed in .PHONY) and intermediary targets.

## June 7, 2016 v 1.0
**Formerly known as SDMF**

* `make-document/` 
    
    Contains the scripts and files needed for documenting makefiles, and also a few test makefiles.

* `sdmf-scripts/` 
    
    Scripts needed for document-makefile

* `sdmf-output/`

    Output of document-makefile

* `testing/` 
    
    Testing python outside of `production' environment   
 
* `tex/` 
 
 Manual for documenting makefiles. 
