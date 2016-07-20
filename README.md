# IBIC picnic

## Self-documenting makefiles!
--------------------------------------------
### How to use picnic

1. For picnic to work, you only need 3 scripts:
    + picnic
    + makemakedoc.py
    + tables.tex
2. You can either clone this Github repository into your home directory or simply copy the above 3 scripts into a new directory under your home directory
3. Once you have a directory containing these scripts on your local machine, add this directory to your path. The best way to do this is via your .bashrc file. Remember to source .bashrc before you start calling picnic.
4. To use picnic, type:

    ``` 
    picnic -o 'name_of_output' name_of_makefile(s)
    ```

5. For details, see documentation sdmf.pdf 
--------------------------------------------
#### July 19, 2016 v 1.1

Moved files from version 1.0 to directory /old. 

Fixed some bugs (all updated scripts, namely: *picnic*, *makemakedoc.py* and *tables.tex*, are now in the main directory)
+ picnic can now parse semicolons in comments
+ default name of output file changed to 'makedocumentation.pdf' instead of 'tables.pdf'
+ picnic should now be able to properly discriminate between higher-level targets (such as those listed in .PHONY) and intermediary targets.

New documentation coming up. More testing to be done. 
--------------------------------------------
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
