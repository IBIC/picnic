# IBIC picnic

### Self-documenting makefiles!

#### July 19, 2016 v 1.1

Moved files from version 1.0 to directory /old. 

Fixed some bugs (all updated scripts, namely: *picnic*, *makemakedoc.py* and *tables.tex*, are now in the main directory)
+ picnic can now parse semicolons in comments
+ default name of output file changed to 'makedocumentation.pdf' instead of 'tables.pdf'
+ picnic should now be able to properly discriminate between higher-level targets (such as those listed in .PHONY) and intermediary targets.

New documentation coming up. More testing to be done. 

#### June 7, 2016 v 1.0

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
