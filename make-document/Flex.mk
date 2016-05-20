## Does the flex stuff
## copied from act-plus PrepSubject.mk

FLEXPATH=$(BIN)/wmprogram/sb/cross_platform/scripts
SBBINDIR=$(BIN)/wmprogram/sb/linux

Flex: flair/Flair.nii.gz flair/Flair_scaled.nii.gz flair/Flair_RO.nii.gz flair/Flair_brain.hdr flair/Flair_brain_flwmt_lesions.hdr flair/Flair_wmh_mask.nii.gz QA/images/checkflex.gif

# The default Flair image has crazy-high intensities that flex doesn't like,
# so we lower the intensities
flair/Flair_scaled.nii.gz: flair/Flair.nii.gz
	cp $< $@ ;\
	fslmaths $@ -mul 0.00266 $@ -odt float

# reorient to standard
flair/Flair_RO.nii.gz: flair/Flair_scaled.nii.gz
	fslreorient2std $< $@

# produce bias-field corrected image that is segmented 
flair/Flair_restore.nii.gz: flair/Flair_RO.nii.gz 
	fast -B -o flair/Flair -t 2 $<

# skull-strip and export as ANALYZE filetype for the sb_flex script
flair/Flair_brain.hdr: flair/Flair_restore.nii.gz
	bet $< `basename $@ .hdr`.nii.gz -R ;\
	fslchfiletype ANALYZE `basename $@ .hdr`.nii.gz $@ ;\
	rm `basename $@ .hdr`.nii.gz

# identify wm lesions
flair/Flair_brain_flwmt_lesions.hdr: flair/Flair_brain.hdr
	@echo "Flex processing " $(word 1,$^) ;\
	export PATH=$(FLEXPATH):$(SBBINDIR):$$PATH ;\
	export SBBINDIR=$(SBBINDIR) ;\
	$(FLEXPATH)/sb_flex -fl $(word 1,$^) 

# create mask of wm lesions
flair/Flair_wmh_mask.nii.gz: flair/Flair_brain_flwmt_lesions.hdr
	fslmaths $< -uthr 1 $@

# check flex output - this is a quickie image for checking skull stripping
# and whether the hyperintensities seem at least to be in the right places
QA/images/checkflex.gif: flair/Flair_brain.hdr flair/Flair_wmh_mask.nii.gz
	mkdir -p QA/images ;\
	slicer flair/Flair_brain.hdr flair/Flair_wmh_mask.nii.gz -l "orange" -a `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png $@ ;\
	rm `dirname $@`/`basename $@ .gif`.png 

# ??
flair/wmhstats.csv: flair/Flair_brain_flwmt_lesions.hdr flair/Flair_brain.hdr
	@echo Writing wmhstats.csv 
	tot=`fslstats $(word 2,$^) -V | awk '{print $$2}'`; \
	wmh=`fslstats $(word 1,$^) -u 2 -V | awk '{print $$2}'` ; \
	per=`echo $$wmh $$tot | awk '{print ($$1/$$2)*100}'` ; \
	echo $(subject)","  $$wmh", " $$per > $@ 
