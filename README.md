# IBIC picnic

## Self-documenting makefiles!

### How to use picnic
--------------------------------------------
1. For picnic to work, you only need 3 scripts:
    + *picnic*
    + *makemakedoc.py*
    + *tables.tex*
2. You can either clone this Github repository into your home directory or simply copy the above 3 scripts into a new directory under your home directory
3. Once you have a directory containing these scripts on your local machine, add this directory to your path. The best way to do this is via your .bashrc file. Remember to source .bashrc before you start calling picnic.
4. To use picnic, type:

    ``` 
    picnic -o 'name_of_output' name_of_makefile(s)
    ```

5. For details, see documentation *sdmf.pdf*

## Updates

### December 20, 2016 v 2.1
----------------------------

*Change Log:*

+ `picnic` filters "`export`" out of global variable declaration, and notes them in the pdf.
Also added explanatory notes to the "Variables" section header.

### December 19, 2016 v. 2.0
-----------------------------

*Change Log:*

+ `picnic` now more intelligently identifies targets/intermediaries by looking at the dependencies of `.PHONY`. This means you have to be more careful about identifying your targets as phony, but they should all be anyway.
+ Trailing whitespace is stripped from variables/targets/intermediaries. 
+ `makemakedoc.py`, `picnic` conformed to 80 chars wide. `tables.tex` already was.
+ Information about verboseness is passed to Python. It will display the file list and identify targets/intermediaries. More functionality can be added. 

-Trevor 

### July 19, 2016 v 1.1
--------------------------------------------
Moved files from version 1.0 to directory /old. 

Fixed some bugs (all updated scripts, namely: *picnic*, *makemakedoc.py* and *tables.tex*, are now in the main directory of the Github  repository)
+ picnic can now parse semicolons in comments
+ default name of output file changed to 'makedocumentation.pdf' instead of 'tables.pdf'
+ picnic should now be able to properly discriminate between higher-level targets (such as those listed in .PHONY) and intermediary targets.

### June 7, 2016 v 1.0
--------------------------------------------
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
