#  ADRC PreprocessSubject.mk
#

FDTHRESH=3.5 # one voxel
TR=2.5

.PHONY: PreprocessSubject TSNR_fMRI BH_TSNR MotionGraphs outliers bh_outliers registrations meica epireg MeicaMovies RawMovies BH_Movies BH_RawMovies

.SECONDARY: rest/rest_e00213_medn.nii.gz rest/rest_e00213_medn_reoriented.nii.gz rest/rest_e00213_mefc_reoriented.nii.gz rest/rest_e00213_tsoc_reoriented.nii.gz breathhold/breathhold_e00213_medn.nii.gz breathhold/breathhold_e00213_medn_reoriented.nii.gz breathhold/breathhold_e00213_tsoc_reoriented.nii.gz breathhold/breathhold_e00213_mefc_reoriented.nii.gz 


PreprocessSubject: TSNR_fMRI BH_TSNR MotionGraphs BH_MotionGraphs meica bh_meica registrations bh_registrations epireg bh_epireg mcflirt outliers bh_outliers

PreprocessSubject_restOnly: TSNR_fMRI MotionGraphs meica outliers registrations epireg mcflirt
PreprocessSubject_BHOnly: BH_TSNR BH_MotionGraphs bh_meica bh_outliers bh_registrations bh_epireg
QA: TSNR_fMRI MotionGraphs


###############
# TSNR - fMRI #
###############

# threshold signal-to-noise ratio for functional scans

TSNR_fMRI: QA/images/rest/rest_e001_tsdiffana.gif QA/images/rest/rest_e002_tsdiffana.gif QA/images/rest/rest_e003_tsdiffana.gif QA/images/rest/rest_e001_tsnr_z.gif QA/images/rest/rest_e002_tsnr_z.gif QA/images/rest/rest_e003_tsnr_z.gif

# Convert png images to gif
%.gif: %.png
	convert $< $@

# compress .nii images
%.nii.gz: %.nii
	gzip $<

QA/images/rest/rest_%_tsdiffana.png: rest/rest_%.nii.gz
	mkdir -p QA/images/rest ;\
	nipy_tsdiffana --out-file $@ $< 

QA/images/rest/rest_%_tsnr_z.gif: rest/rest_%.nii.gz
	mkdir -p QA/images/rest ;\
	python $(BIN)/TSNR_Images.py -i $< ;\
	name=`basename $< .nii.gz` ;\
	$(BIN)/make_xyz $${name}_tsnr.nii.gz QA/images/rest 2 50 ;\
	$(BIN)/make_xyz $${name}_tsnr_mean.nii.gz QA/images/rest 2 50 ;\
	$(BIN)/make_xyz $${name}_tsnr_stddev.nii.gz QA/images/rest 2 50 ;\
	rm $${name}_tsnr.nii.gz $${name}_tsnr_mean.nii.gz $${name}_tsnr_stddev.nii.gz


#####################
# TSNR - Breathhold #
#####################

# TSNR for breathhold scans

BH_TSNR: QA/images/breathhold/breathhold_e001_tsdiffana.gif QA/images/breathhold/breathhold_e002_tsdiffana.gif QA/images/breathhold/breathhold_e003_tsdiffana.gif QA/images/breathhold/breathhold_e001_tsnr_z.gif QA/images/breathhold/breathhold_e002_tsnr_z.gif QA/images/breathhold/breathhold_e003_tsnr_z.gif

# make the tsdiffana breathhold images specified in BH_TSNR target
QA/images/breathhold/breathhold_%_tsdiffana.png: breathhold/breathhold_%.nii.gz
	mkdir -p QA/images/breathhold/ ;\
	nipy_tsdiffana --out-file $@ $<

QA/images/breathhold/breathhold_%_tsnr_z.gif: breathhold/breathhold_%.nii.gz
	mkdir -p QA/images/breathhold/ ;\
	python $(BIN)/TSNR_Images.py -i $< ;\
	name=`basename $< .nii.gz` ;\
	$(BIN)/make_xyz $${name}_tsnr.nii.gz QA/images/breathhold 2 50 ;\
	$(BIN)/make_xyz $${name}_tsnr_mean.nii.gz QA/images/breathhold 2 50 ;\
	$(BIN)/make_xyz $${name}_tsnr_stddev.nii.gz QA/images/breathhold 2 50 ;\
	rm $${name}_tsnr.nii.gz $${name}_tsnr_mean.nii.gz $${name}_tsnr_stddev.nii.gz


################
# MotionGraphs #
################

# These make the summary graphs for rotations, translations, fd, and dvars

MotionGraphs: QA/images/rest/rest_e002_MotionGraphRotations.gif

# This makes rotations, translations, fd, and both dvars files
# If you have to remake any of those, rm QA/images/*Motion* and rerun
QA/images/rest/rest_e002_MotionGraphRotations.gif: rest/rest_e002.nii.gz rest/rest_dvars_vals rest/rest_fd_vals
	mkdir -p QA/images/rest ;\
	Rscript $(RScripts)/MakingGraphs.R e002 ;\
	for i in QA/images/rest/*.png; do convert $$i `dirname $@`/`basename $$i .png`.gif; done ;\
	rm QA/images/rest/rest*.png

BH_MotionGraphs: QA/images/breathhold/breathhold_e002_MotionGraphRotations.gif

# This makes rotations, translations, fd, and both dvars files
# If you have to remake, rm QA/images/breathhold/*Motion*
QA/images/breathhold/breathhold_e002_MotionGraphRotations.gif: breathhold/meica.rest_e00213/rest_e002.nii.gz breathhold/breathhold_dvars_vals breathhold/breathhold_fd_vals
	mkdir -p QA/images/breathhold ;\
	Rscript $(RScripts)/MakingGraphsBH.R e002 
	for i in QA/images/breathhold/*.png; do convert $$i `dirname $@`/`basename $$i .png`.gif; done ;\
	rm QA/images/breathhold/*.png


#################
# fMRI Outliers #
#################

# This creates the motion outliers for everything necessary.
# It is in lower case because it should naturally be called from MotionGraphs
# unless you're doing something debuggy


outliers: rest/rest_dvars_vals rest/rest_fd_vals rest/rest_e002_SN_outliers.txt rest/rest_e002_all_outliers.txt rest/meica.rest_e00213/motion.1D.rad 


# fslMotionOutliers using dvars metric
rest/rest_e00213_tsoc_dvars_vals: rest/rest_e00213_tsoc.nii.gz
	$(BIN)/motion_outliers -i $< -o rest/rest_e00213_tsoc_dvars_regressors --dvars -s rest/rest_e00213_tsoc_dvars_vals --nomoco -x rest_e00213_tsoc

# Calculate motion outliers using dvars metric on motion-corrected denoised
# resting state data
rest/rest_e00213_medn_dvars_vals: rest/rest_e00213_medn.nii.gz rest/rest_e00213_tsoc_reoriented_vol0.nii.gz
	$(BIN)/motion_outliers -i $(word 1,$^) -o rest/rest_e00213_medn_dvars_regressors -m $(word 2,$^) --dvars -s rest/rest_e00213_medn_dvars_vals --nomoco --abs -v -x rest_e00213_medn

rest/rest_e002_dvars_vals: rest/rest_e002.nii.gz
	$(BIN)/motion_outliers -i $< -o rest/rest_e002_dvars_regressors --dvars -s rest/rest_e002_dvars_vals -x rest_e002 

rest/rest_dvars_vals: rest/rest_e002_dvars_vals rest/rest_e00213_medn_dvars_vals rest/rest_e00213_tsoc_dvars_vals
	paste rest/*dvars_vals  > $@ ;\
	paste rest/*dvars_thresh  > rest/rest_dvars_thresh ;\
	touch $@

rest/rest_e00213_tsoc_fd_vals: rest/rest_e00213_tsoc.nii.gz
	$(BIN)/motion_outliers -i $< -o rest/rest_e00213_tsoc_fd_regressors_mcflirt --fd -s rest/rest_e00213_tsoc_fd_vals --thresh=$(FDTHRESH) -x rest_e00213_tsoc

rest/rest_e002_fd_vals: rest/rest_e002.nii.gz
	$(BIN)/motion_outliers -i $< -o rest/rest_e002_fd_regressors_mcflirt --fd -s rest/rest_e002_fd_vals --thresh=$(FDTHRESH) -x rest_e002

rest/rest_e00213_medn_fd_vals: rest/rest_e00213_medn.nii.gz rest/meica.rest_e00213/motion.1D.rad
	$(BIN)/motion_outliers -i $(word 1,$^) -o `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_fd_regressors_mcflirt --fd -s `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_fd_vals --thresh=$(FDTHRESH) --nomoco -c $(word 2,$^) -x rest_e00213_medn

# this is where we pass in all the fd files we need to make
rest/rest_fd_vals: rest/rest_e002_fd_vals rest/rest_e00213_medn_fd_vals rest/rest_e00213_tsoc_fd_vals 
	paste rest/rest_e002_fd_vals rest/rest_e00213_medn_fd_vals > $@

# ERSN
rest/rest_e002_SN_outliers.txt: rest/rest_e002.nii.gz
	$(BIN)/ibicIDSN $(word 1,$^) $(TR) ;\
	touch $@

rest/meica.rest_e00213/motion.1D.rad: rest/meica.rest_e00213/motion.1D
	Rscript $(BIN)/R/motion2rad.R $< $@

# Find outliers and remove duplicates

rest/rest_e002_all_outliers.txt: rest/rest_e002_dvars_spike_vols rest/rest_e002_fd_spike_vols rest/rest_e002_SN_outliers.txt
	cat $(word 1,$^) | $(BIN)/transpose > alloutliers.txt ;\
	cat $(word 2,$^) | $(BIN)/transpose >> alloutliers.txt ;\
	cat $(word 3,$^) >> alloutliers.txt ;\
	sort -nu alloutliers.txt > $@ ;\
	rm alloutliers.txt ;\
	$(BIN)/binarize_outliers $(subject) $@ rest


#######################
# Breathhold Outliers #
#######################

bh_outliers: breathhold/breathhold_dvars_vals breathhold/breathhold_fd_vals breathhold/breathhold_e002_SN_outliers.txt breathhold/breathhold_e002_all_outliers.txt breathhold/meica.rest_e00213/motion.1D.rad $(BIN)/motion_outliers

# fslMotionOutliers using dvars metric
breathhold/breathhold_e00213_tsoc_dvars_vals: breathhold/breathhold_e00213_tsoc.nii.gz
	name=`dirname $<`/`basename $< .nii.gz` ;\
	$(BIN)/motion_outliers -i $< -o $${name}_dvars_regressors --dvars -s $${name}_dvars_vals --nomoco -x breathhold_e00213_tsoc


breathhold/breathhold_e00213_medn_dvars_vals: breathhold/breathhold_e00213_medn.nii.gz breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz
	$(BIN)/motion_outliers -i $(word 1,$^) -o `dirname $(word 1,$^)`/`basename $(word 1,$^) .nii.gz`_dvars_regressors -m breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz --dvars -s breathhold/`basename $(word 1,$^) .nii.gz`_dvars_vals --nomoco --abs -v -x breathhold_e00213_medn

breathhold/breathhold_e002_dvars_vals: breathhold/breathhold_e002.nii.gz
	$(BIN)/motion_outliers -i $^ -o breathhold/breathhold_e002_dvars_regressors --dvars -s breathhold/breathhold_e002_dvars_vals  -x breathhold_e002

# Spike vols is created when breathhold_e002_dvars_vals is created
breathhold/breathhold_e002_dvars_spike_vols: breathhold/breathhold_e002_dvars_vals

breathhold/breathhold_dvars_vals: breathhold/breathhold_e002_dvars_vals breathhold/breathhold_e00213_medn_dvars_vals breathhold/breathhold_e00213_tsoc_dvars_vals
	paste $^ > $@ ;\
	paste breathhold/*dvars_thresh  > breathhold/dvars_thresh

breathhold/breathhold_e00213_tsoc_fd_vals: breathhold/breathhold_e00213_tsoc.nii.gz
	name=`dirname $<`/`basename $< .nii.gz` ;\
	$(BIN)/motion_outliers -i $< -o $${name}_fd_regressors --fd -s $${name}_fd_vals --thresh=$(FDTHRESH) -x breathhold_e00213_tsoc

breathhold/breathhold_e002_fd_vals: breathhold/breathhold_e002.nii.gz
	$(BIN)/motion_outliers -i $< -o breathhold/breathhold_e002_fd_regressors --fd -s breathhold/breathhold_e002_fd_vals --thresh=$(FDTHRESH) -x breathhold_e002 

breathhold/breathhold_e00213_medn_fd_vals: breathhold/breathhold_e00213_medn.nii.gz breathhold/meica.rest_e00213/motion.1D.rad
	$(BIN)/motion_outliers -i $(word 1,$^) -o breathhold/`basename $(word 1,$^) .nii.gz`_fd_regressors --fd -s breathhold/`basename $(word 1,$^) .nii.gz`_fd_vals --thresh=$(FDTHRESH) --nomoco -c $(word 2,$^) -x breathhold_e00213_medn

# This tells make that the 
breathhold/breathhold_e002_fd_spike_vols: breathhold/breathhold_e002_fd_vals


# this is where we pass in all the files we need to make
breathhold/breathhold_fd_vals: breathhold/breathhold_e002_fd_vals breathhold/breathhold_e00213_medn_fd_vals breathhold/breathhold_e00213_tsoc_fd_vals 
	paste breathhold/breathhold_e002_fd_vals breathhold/breathhold_e00213_medn_fd_vals > $@

# ERSN
breathhold/breathhold_e002_SN_outliers.txt: breathhold/breathhold_e002.nii.gz
	$(BIN)/ibicIDSN $(word 1,$^) $(TR) ;\
	touch $@

breathhold/meica.rest_e00213/motion.1D.rad: breathhold/meica.rest_e00213/motion.1D
	Rscript $(BIN)/R/motion2rad.R $< $@

breathhold/breathhold_e002_all_outliers.txt: breathhold/breathhold_e002_dvars_spike_vols breathhold/breathhold_e002_fd_spike_vols breathhold/breathhold_e002_SN_outliers.txt
	cat $(word 1,$^) | $(BIN)/transpose > alloutliers.txt ;\
	cat $(word 2,$^) | $(BIN)/transpose >> alloutliers.txt ;\
	cat $(word 3,$^) >> alloutliers.txt ;\
	sort -nu alloutliers.txt > $@ ;\
	rm alloutliers.txt ;\
	$(BIN)/binarize_outliers $(subject) $@ breathhold

###############################################################################
# Functional denoising with ME-ICA
##############################################################################

# Create the meica files for each subject/scan: medn, tsoc, and mefc

meica: rest/rest_e00213_medn.nii.gz rest/rest_e00213_medn_reoriented.nii.gz rest/rest_e00213_mefc_reoriented.nii.gz rest/rest_e00213_tsoc_reoriented.nii.gz

 #rest/meica.rest_e00213/rest_e002_vrA_maxdisp_mm.1D.max 

bh_meica: breathhold/breathhold_e00213_medn.nii.gz breathhold/breathhold_e00213_medn_reoriented.nii.gz # breathhold/meica.rest_e00213/rest_e002_vrA_maxdisp_mm.1D.max

# Meica does not smooth data

# This makes medn, tsoc, and mefc.
# If you have to remake one, rm medn
rest/rest_e00213_medn.nii.gz: rest/rest_e001.nii.gz
	rm -rf rest/meica.rest_e00213 ;\
	cp mprage/T1_brain.nii.gz rest ;\
	cd rest && $(AFNIpath)/meica.py -d "rest_e00[2,1,3].nii.gz" --no_skullstrip -a T1_brain.nii.gz -e 9.5,27.5,45.5 --keep_int

# This just means that tsoc and mefc will be created if medn is
rest/rest_e00213_tsoc.nii.gz: rest/rest_e00213_medn.nii.gz

rest/rest_e00213_mefc.nii.gz: rest/rest_e00213_medn.nii.gz

rest/meica.rest_e00213/motion.1D: rest/rest_e00213_medn.nii.gz


rest/meica.rest_e00213/rest_e002.nii.gz: rest/rest_e00213_medn.nii.gz

# Reorient files created by meica as necessary
rest/rest_e00213_%_reoriented.nii.gz:  rest/rest_e00213_%.nii.gz
	fslreorient2std $< $@

# Obtain the first volume of the optimally combined, reoriented resting state
# image for speeding up epireg registration. Be very careful to use this exact
# file as the reference image for ANTs calls to WarpImageMultiTransform
rest/rest_e00213_tsoc_reoriented_vol0.nii.gz: rest/rest_e00213_tsoc_reoriented.nii.gz
	fslroi $< $@ 0 1


# Run Meica on breathold data. We need to use the bias corrected skull stripped
# image here, or bad things happen.
breathhold/breathhold_e00213_medn.nii.gz: breathhold/breathhold_e001.nii.gz
	rm -rf breathhold/meica.rest_e00213 ;\
	cp breathhold/breathhold_e001.nii.gz breathhold/rest_e001.nii.gz ;\
	cp breathhold/breathhold_e002.nii.gz breathhold/rest_e002.nii.gz ;\
	cp breathhold/breathhold_e003.nii.gz breathhold/rest_e003.nii.gz ;\
	cp mprage/T1_brain.nii.gz breathhold ;\
	cd breathhold && $(AFNIpath)/meica.py -d "rest_e00[2,1,3].nii.gz" -a T1_brain.nii.gz --no_skullstrip -e 9.5,27.5,45.5 ;\
	mv rest_e00213_medn.nii.gz breathhold_e00213_medn.nii.gz ;\
	mv rest_e00213_mefc.nii.gz breathhold_e00213_mefc.nii.gz ;\
	mv rest_e00213_tsoc.nii.gz breathhold_e00213_tsoc.nii.gz

# This is needed to know how to create the breathhold tsoc in Make's eyes,
# even though it is really created above, if we need it before medn
breathhold/breathhold_e00213_tsoc.nii.gz: breathhold/breathhold_e00213_medn.nii.gz

# same as above - for the mefc file
breathhold/breathhold_e00213_mefc.nii.gz: breathhold/breathhold_e00213_medn.nii.gz

# Same as above - know how to generate the motion.1D file
breathhold/meica.rest_e00213/motion.1D: breathhold/breathhold_e00213_medn.nii.gz

breathhold/meica.rest_e00213/rest_e002.nii.gz: breathhold/breathhold_e00213_medn.nii.gz

# Reorient the breathhold images as needed
breathhold/breathhold_%_reoriented.nii.gz:  breathhold/breathhold_%.nii.gz
	fslreorient2std $< $@

# Extract the first volume for epireg registration
breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz: breathhold/breathhold_e00213_tsoc_reoriented.nii.gz
	fslroi $< $@ 0 1


# Summary motion files
# NEED TO GET THESE WORKING AGAIN - hack meica
#rest/meica.rest_e00213/rest_e002_vrA_maxdisp_mm.1D.max: rest/rest_e00213_medn.nii.gz
#	python $(BIN)/IndividualMotionSummary.py --input rest/meica.rest_e00213/rest_e002_vrA_maxdisp_mm.1D

#breathhold/meica.rest_e00213/rest_e002_vrA_maxdisp_mm.1D.max: breathhold/breathhold_e00213_medn.nii.gz
#	python $(BIN)/IndividualMotionSummary.py --input breathhold/meica.rest_e00213/rest_e002_vrA_maxdisp_mm.1D

###############################################################################
## Movies! Movies! Movies! We're makin movies!
#
#  Resting state meica movies
MeicaMovies: QA/images/rest/rest_e00213_medn_x_animation.gif QA/images/rest/rest_e00213_tsoc_x_animation.gif QA/images/rest/rest_e00213_mefc_x_animation.gif

# Movies of the original data
RawMovies: QA/images/rest/rest_e001_x_animation.gif QA/images/rest/rest_e002_x_animation.gif QA/images/rest/rest_e003_x_animation.gif

# these are individual to avoid conflict with similarily named files
QA/images/rest/rest_e00213_%_x_animation.gif: rest/rest_e00213_%.nii.gz
	$(BIN)/functional_movies_meica $< QA/images/rest 1

QA/images/rest/rest_e00%_x_animation.gif: rest/rest_e00%.nii.gz
	$(BIN)/functional_movies_meica $< QA/images/rest 1



###############################################################################
# Breathhold movies
BH_Movies: QA/images/breathhold/breathhold_e00213_medn_x_animation.gif QA/images/breathhold/breathhold_e00213_tsoc_x_animation.gif QA/images/breathhold/breathhold_e00213_mefc_x_animation.gif

# Movies of the original data
BH_RawMovies: QA/images/breathhold/breathhold_e001_x_animation.gif QA/images/breathhold/breathhold_e002_x_animation.gif QA/images/breathhold/breathhold_e003_x_animation.gif


# these are individual to avoid conflict with similarily named files
QA/images/breathhold/breathhold_e00213_%_x_animation.gif: breathhold/breathhold_e00213_%.nii.gz
	$(BIN)/functional_movies_breathhold $< QA/images/breathhold 1

QA/images/breathhold/breathhold_e00%_x_animation.gif: breathhold/breathhold_e00%.nii.gz
	$(BIN)/functional_movies_breathhold $< QA/images/breathhold 1

###############################################################################
# Registrations 
#

# Write transformation matrices
registrations: xfm_dir/rest_e00213_tsoc_reoriented_to_T1.mat xfm_dir/T1_to_rest_e00213_tsoc_reoriented.mat xfm_dir/fs_to_rest_e00213_tsoc_reoriented.mat xfm_dir/rest_e00213_tsoc_reoriented_to_fs.mat QA/images/rest/rest_e00213_tsoc_reoriented_to_T1.gif

bh_registrations: xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1.mat xfm_dir/breathhold_e00213_tsoc_reoriented_to_fs.mat QA/images/breathhold/breathhold_e00213_tsoc_reoriented_to_T1.gif xfm_dir/T1_to_breathhold_e00213_tsoc_reoriented.mat xfm_dir/fs_to_breathhold_e00213_tsoc_reoriented.mat

mprage/T1_in_fs.nii.gz: $(SUBJECTS_DIR)/$(subject)/mri/T1.mgz
	source $(FREESURFER_SETUP) ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	mri_convert $(word 1, $^) $@

# Breathhold optimally combined to T1 matrix with epi-reg
xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1.mat: breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz mprage/T1.nii.gz mprage/T1_brain.nii.gz 
	mkdir -p xfm_dir ;\
	epi_reg --epi=breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz --t1=mprage/T1.nii.gz --t1brain=mprage/T1_brain.nii.gz --out=xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1 


# Resting state optimally combined to T1 matrix with epi-reg
# 
xfm_dir/rest_e00213_tsoc_reoriented_to_T1.mat: rest/rest_e00213_tsoc_reoriented_vol0.nii.gz mprage/T1.nii.gz mprage/T1_brain.nii.gz 
	mkdir -p xfm_dir ;\
	epi_reg --epi=rest/rest_e00213_tsoc_reoriented_vol0.nii.gz --t1=mprage/T1.nii.gz --t1brain=mprage/T1_brain.nii.gz --out=xfm_dir/rest_e00213_tsoc_reoriented_to_T1 


#Create T1 to task matrices
xfm_dir/T1_to_breathhold_e00213_tsoc_reoriented.mat: xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1.mat
	convert_xfm -omat $@ -inverse $<

xfm_dir/T1_to_rest_e00213_tsoc_reoriented.mat: xfm_dir/rest_e00213_tsoc_reoriented_to_T1.mat
	convert_xfm -omat $@ -inverse $<


# Overlay of optimally combined resting state to T1 registration 
QA/images/rest/rest_e00213_tsoc_reoriented_to_T1.gif: xfm_dir/rest_e00213_tsoc_reoriented_to_T1.mat mprage/T1_brain.nii.gz
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1 `dirname $(word 1,$^)`/`basename $(word 1,$^) .mat`.nii.gz -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ 

# Overlay of optimally combined breathhold to T1 registration 
QA/images/breathhold/breathhold_e00213_tsoc_reoriented_to_T1.gif: xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1.mat mprage/T1_brain.nii.gz
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1 `dirname $(word 1,$^)`/`basename $(word 1,$^) .mat`.nii.gz -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ 


# Create freesurfer to Task registration matrices & Task to freesurfer matrices
xfm_dir/fs_to_breathhold_e00213_tsoc_reoriented.mat: xfm_dir/T1_to_breathhold_e00213_tsoc_reoriented.mat xfm_dir/fs_to_T1.mat 
	convert_xfm -omat $@ -concat $(word 1,$^) $(word 2, $^)

xfm_dir/fs_to_rest_e00213_tsoc_reoriented.mat: xfm_dir/T1_to_rest_e00213_tsoc_reoriented.mat xfm_dir/fs_to_T1.mat 
	convert_xfm -omat $@ -concat $(word 1,$^) $(word 2, $^)

xfm_dir/rest_e00213_tsoc_reoriented_to_fs.mat: xfm_dir/fs_to_rest_e00213_tsoc_reoriented.mat
	convert_xfm -omat $@ -inverse $<

xfm_dir/breathhold_e00213_tsoc_reoriented_to_fs.mat: xfm_dir/fs_to_breathhold_e00213_tsoc_reoriented.mat
	convert_xfm -omat $@ -inverse $<

############################
# epireg ANTs registration #
############################

epireg: xfm_dir/rest_e00213_tsoc_to_CT_epireg_ants.nii.gz QA/images/rest/rest_e00213_tsoc_to_CT_epireg_ants.gif xfm_dir/rest_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz QA/images/rest/rest_e00213_tsoc_reoriented_to_mni_epireg_ants.gif 
bh_epireg: xfm_dir/breathhold_e00213_tsoc_to_CT_epireg_ants.nii.gz QA/images/breathhold/breathhold_e00213_tsoc_to_CT_epireg_ants.gif xfm_dir/breathhold_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz QA/images/breathhold/breathhold_e00213_tsoc_reoriented_to_mni_epireg_ants.gif

###############################################################################
## rest to custom template using epireg & ants

# Convert resting optimally combined to T1 FSL matrix to ITK format
xfm_dir/rest_e00213_tsoc_reoriented_to_T1_ras.txt: xfm_dir/rest_e00213_tsoc_reoriented_to_T1.mat 
	c3d_affine_tool -ref mprage/T1_brain.nii.gz -src rest/rest_e00213_tsoc_reoriented_vol0.nii.gz $< -fsl2ras -oitk $@

# Transform resting optimally combined to CT by concatenating epireg
# rest->T1 transform and ANTs T1->CT nonlinear transform
xfm_dir/rest_e00213_tsoc_to_CT_epireg_ants.nii.gz: rest/rest_e00213_tsoc_reoriented_vol0.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz mprage/T1_brain.nii.gz xfm_dir/rest_e00213_tsoc_reoriented_to_T1_ras.txt xfm_dir/T1_to_CT_deformed.nii.gz
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 rest/rest_e00213_tsoc_reoriented_vol0.nii.gz $@ $(STANDARD_DIR)/Subject-specific_template.nii.gz  xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt  xfm_dir/rest_e00213_tsoc_reoriented_to_T1_ras.txt

# Overlay image of rest to CT image and CT template (subject-specific_template)
QA/images/rest/rest_e00213_tsoc_to_CT_epireg_ants.gif: xfm_dir/rest_e00213_tsoc_to_CT_epireg_ants.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1  $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ 

###############################################################################
## rest to MNI using epireg & ants

# Transform resting optimally combined to MNI by concatenating epireg
# rest->T1 transform, ANTs T1->CT nonlinear transform, and CT to MNI nonlinear
# transform
xfm_dir/rest_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz: rest/rest_e00213_tsoc_reoriented_vol0.nii.gz $(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz $(STANDARD_DIR)/CT_to_mni_Warp.nii.gz $(STANDARD_DIR)/CT_to_mni_Affine.txt xfm_dir/T1_to_CT_deformed.nii.gz xfm_dir/rest_e00213_tsoc_reoriented_to_T1_ras.txt
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt xfm_dir/rest_e00213_tsoc_reoriented_to_T1_ras.txt


# Overlay of optimally combined image with MNI, registered with ANTs
QA/images/rest/rest_e00213_tsoc_reoriented_to_mni_epireg_ants.gif: xfm_dir/rest_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz $(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1  $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ 

#############################################################################
########### Breathhold to custom template registration using epi-reg and ANTs


# Convert the optimally combined breathhold to T1 FSL affine transform to ITK
# format
xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1_ras.txt: xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1.mat 
	c3d_affine_tool -ref mprage/T1_brain.nii.gz -src breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz $< -fsl2ras -oitk $@

# Transform breathhold optimally combined to CT by concatenating epireg
# rest->T1 transform and ANTs T1->CT nonlinear transform
xfm_dir/breathhold_e00213_tsoc_to_CT_epireg_ants.nii.gz: breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz mprage/T1_brain.nii.gz xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1.mat xfm_dir/T1_to_CT_deformed.nii.gz xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1_ras.txt
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1_ras.txt

# Overlay image of Breathhold to CT image and Subject specific template
QA/images/breathhold/breathhold_e00213_tsoc_to_CT_epireg_ants.gif: xfm_dir/breathhold_e00213_tsoc_to_CT_epireg_ants.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1  $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ 


#breathhold to mni using epireg & ants
xfm_dir/breathhold_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz: breathhold/breathhold_e00213_tsoc_reoriented_vol0.nii.gz $(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz $(STANDARD_DIR)/CT_to_mni_Warp.nii.gz $(STANDARD_DIR)/CT_to_mni_Affine.txt xfm_dir/T1_to_CT_deformed.nii.gz xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1_ras.txt
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt xfm_dir/breathhold_e00213_tsoc_reoriented_to_T1_ras.txt



# Overlay of Breathhold optimally combined to MNI, registered with epireg to
# structural and ANTs from structural to MNI
QA/images/breathhold/breathhold_e00213_tsoc_reoriented_to_mni_epireg_ants.gif: xfm_dir/breathhold_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz $(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1  $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ 

###############################################################################
# Make mflirt motion parameters, using the second echo, to compare
# with meica parameters. Mcflirt numbers are systematically a little different
# than those from meica.

mcflirt: mcflirt_data/data.par mcflirt_data/breathhold_data.par


# Run mcflirt on resting state data, second echo
mcflirt_data/data.par:  rest/rest_e002.nii.gz
	mkdir -p mcflirt_data ;\
	mcflirt -plots mcflirt_data/mcflirt_data.par -in rest/rest_e002.nii.gz -out mcflirt_data/data -rmsrel -rmsabs

# Run mcflirt on breathhold data, second echo
mcflirt_data/breathhold_data.par: breathhold/breathhold_e002.nii.gz
	mkdir -p mcflirt_data ;\
	mcflirt -plots mcflirt_data/mcflirt_breathhold_data.par -in breathhold/breathhold_e002.nii.gz -out mcflirt_data/breathhold_data -rmsrel -rmsabs 


