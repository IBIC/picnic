# This makefile makes pretty pictures that don't play nicely with the grid engine because it needs to own your display


.PHONY: TSNR 

display: TSNR 

## TSNR
TSNR: QA/images/MEMPRAGE_tsnr.nii.gz QA/images/rest_tsnr.nii.gz QA/images/breathhold_tsnr.nii.gz QA/images/MEMPRAGE_tsnr.gif QA/images/rest_tsnr.gif QA/images/breathhold_tsnr.gif 

# MEMPRAGE image
QA/images/MEMPRAGE_tsnr.nii.gz: memprage/MEMPRAGE.nii.gz
	python $(BIN)/TSNR_Images.py -i "$(word 1,$^)" ;\
	mv *tsnr* QA/images

# rest image
QA/images/rest_tsnr.nii.gz: rest/rest_e001.nii.gz
	python $(BIN)/TSNR_Images.py -i "$(word 1,$^)" ;\
	python $(BIN)/TSNR_Images.py -i "rest/rest_e002.nii.gz" ;\
	python $(BIN)/TSNR_Images.py -i "rest/rest_e003.nii.gz" ;\
	mv *tsnr* QA/images

# breathhold image
QA/images/breathhold_tsnr.nii.gz: breathhold/BREATHHOLD-e001.nii.gz
	python $(BIN)/TSNR_Images.py -i "$(word 1,$^)" ;\
	python $(BIN)/TSNR_Images.py -i "breathhold/BREATHHOLD-e002.nii.gz" ;\
	python $(BIN)/TSNR_Images.py -i "breathhold/BREATHHOLD-e003.nii.gz" ;\
	mv *tsnr* QA/images

# MEMPRAGE GIF
QA/images/MEMPRAGE_tsnr.gif: QA/images/MEMPRAGE_tsnr.nii.gz
	$(FSLpath)/bin/slices $(word 1,$^) -s 3 -o $@ ;\
	$(FSLpath)/bin/slices `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_mean.nii.gz -s 3 -o `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_mean.gif ;\
	$(FSLpath)/bin/slices `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_stddev.nii.gz -s 3 -o `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_stddev.gif ;\

# rest GIF
QA/images/rest_tsnr.gif: QA/images/rest_tsnr.nii.gz
	$(FSLpath)/bin/slices $(word 1,$^) -s 3 -o $@ ;\
	$(FSLpath)/bin/slices QA/images/rest_e001_tsnr_mean.nii.gz -s 3 -o QA/images/rest_e001_mean.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e001_tsnr_stddev.nii.gz -s 3 -o QA/images/rest_e001_stddev.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e002_tsnr.nii.gz -s 3 -o QA/images/rest_e002_tsnr.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e002_tsnr_mean.nii.gz -s 3 -o QA/images/rest_e002_tsnr_mean.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e002_tsnr_stddev.nii.gz -s 3 -o QA/images/rest_e002_tsnr_stddev.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e003_tsnr.nii.gz -s 3 -o QA/images/rest_e003_tsnr.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e003_tsnr_mean.nii.gz -s 3 -o QA/images/rest_e003_tsnr_mean.gif ;\
	$(FSLpath)/bin/slices QA/images/rest_e003_tsnr_stddev.nii.gz -s 3 -o QA/images/rest_e003_tsnr_stddev.gif 

# breathhold GIF
QA/images/breathhold_tsnr.gif: QA/images/breathhold_tsnr.nii.gz
	$(FSLpath)/bin/slices $(word 1,$^) -s 3 -o $@ ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e001_tsnr_mean.nii.gz -s 3 -o QA/images/BREATHHOLD-e001_tsnr_mean.gif ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e001_tsnr_stddev.nii.gz -s 3 -o QA/images/BREATHHOLD-e001_tsnr_stddev.gif ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e002_tsnr.nii.gz -s 3 -o QA/images/BREATHHOLD-e002_tsnr.gif ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e002_tsnr_mean.nii.gz -s 3 -o QA/images/BREATHHOLD-e002_tsnr_mean.gif ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e002_tsnr_stddev.nii.gz -s 3 -o QA/images/BREATHHOLD-e002_tsnr_stddev.gif
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e003_tsnr.nii.gz -s 3 -o QA/images/BREATHHOLD-e003_tsnr.gif ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e003_tsnr_mean.nii.gz -s 3 -o QA/images/BREATHHOLD-e003_tsnr_mean.gif ;\
	$(FSLpath)/bin/slices QA/images/BREATHHOLD-e003_tsnr_stddev.nii.gz -s 3 -o QA/images/BREATHHOLD-e003_tsnr_stddev.gif

## Freesurfer QA
# is done in the freesurfer main directory
