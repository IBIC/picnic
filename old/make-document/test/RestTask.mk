# UDALL PreprocessSubject.mk

#! one voxel
FDTHRESH=3.5

#! length of a TR
TR=2.5

.PHONY: TARGET-TYPE TARGET-TYPE-meica TARGET-TYPE-outliers TARGET-TYPE-registrations TARGET-TYPE-mcflirt TARGET-TYPE-epireg TARGET-TYPE-motiongraphs TARGET-TYPE-meicamovies TARGET-TYPE-rawmovies TARGET-TYPE-TSNR TARGET-TYPE-QA TARGET-TYPE-all 

#? Do both processing and QA checks
TARGET-TYPE-all: TARGET-TYPE TARGET-TYPE-QA

#? Do everything required for TARGET-TYPE
TARGET-TYPE: TARGET-TYPE-meica TARGET-TYPE-outliers TARGET-TYPE-registrations TARGET-TYPE-mcflirt TARGET-TYPE-epireg TARGET-TYPE-motiongraphs 

#? Do all the QA for TARGET-TYPE
TARGET-TYPE-QA: TARGET-TYPE-meicamovies TARGET-TYPE-rawmovies TARGET-TYPE-TSNR

# Functional denoising with ME-ICA #

#? Create the meica files for each subject/scan: medn, tsoc, and mefc. Note: meica does not smooth data.
TARGET-TYPE-meica: TARGET-TYPE/fMRI_e00213_medn.nii.gz TARGET-TYPE/fMRI_e00213_medn_reoriented.nii.gz TARGET-TYPE/fMRI_e00213_mefc_reoriented.nii.gz TARGET-TYPE/fMRI_e00213_tsoc_reoriented.nii.gz TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz TARGET-TYPE/fMRI_e001.nii.gz TARGET-TYPE/fMRI_e002.nii.gz TARGET-TYPE/fMRI_e003.nii.gz

#> Copy and rename rest_*.nii.gz to fmri_*.nii.gz
TARGET-TYPE/fMRI_%.nii.gz: TARGET-TYPE/rest_%.nii.gz
	cp -f $< $@

#> This makes medn, tsoc, and mefc; If you have to remake one, rm medn
TARGET-TYPE/fMRI_e00213_medn.nii.gz: TARGET-TYPE/fMRI_e001.nii.gz TARGET-TYPE/fMRI_e002.nii.gz TARGET-TYPE/fMRI_e003.nii.gz
	rm -rf TARGET-TYPE/meica.fMRI_e00213 ;\
	ln -s $(SubjDIR)/mprage/T1_brain.nii.gz TARGET-TYPE ;\
	cd TARGET-TYPE &&\
	$(AFNIpath)/meica.py -d "fMRI_e00[2,1,3].nii.gz" --no_skullstrip -a T1_brain.nii.gz -e 9.5,27.5,45.5 --keep_int

#> This just means that tsoc will be created if medn is
TARGET-TYPE/fMRI_e00213_tsoc.nii.gz: TARGET-TYPE/fMRI_e00213_medn.nii.gz

#> This just means that mefc will be created if medn is
TARGET-TYPE/fMRI_e00213_mefc.nii.gz: TARGET-TYPE/fMRI_e00213_medn.nii.gz

#> motion information
TARGET-TYPE/meica.fMRI_e00213/motion.1D: TARGET-TYPE/fMRI_e00213_medn.nii.gz

#> couldn't tell ya'
TARGET-TYPE/meica.fMRI_e00213/fMRI_e002.nii.gz: TARGET-TYPE/est_e00213_medn.nii.gz


# These have to be split up because you can only pattern match one thing at a time

#> Reorient medn files
TARGET-TYPE/fMRI_e00213_medn_reoriented.nii.gz:  TARGET-TYPE/fMRI_e00213_medn.nii.gz
	fslreorient2std $< $@

#> Reorient mefc
TARGET-TYPE/fMRI_e00213_mefc_reoriented.nii.gz:  TARGET-TYPE/fMRI_e00213_mefc.nii.gz
	fslreorient2std $< $@

#> Reorient tsoc
TARGET-TYPE/fMRI_e00213_tsoc_reoriented.nii.gz:  TARGET-TYPE/fMRI_e00213_tsoc.nii.gz
	fslreorient2std $< $@

#> Using the first volume of the optimally combined, reoriented fMRIing state image speeds up epireg registration.
#> Be very careful to use this exact file as the reference image for ANTs calls to WarpImageMultiTransform
TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz: TARGET-TYPE/fMRI_e00213_tsoc_reoriented.nii.gz
	fslroi $< $@ 0 1

#################
# fMRI Outliers #
#################

#? This creates the motion outliers for everything necessary.
TARGET-TYPE-outliers: TARGET-TYPE/$(subject)_all_outliers.txt TARGET-TYPE/fMRI_e002_dvars_vals TARGET-TYPE/fMRI_e002_fd_vals # TARGET-TYPE/fMRI_dvars_vals TARGET-TYPE/fMRI_fd_vals 

#> fslMotionOutliers using dvars metric
TARGET-TYPE/fMRI_e00213_tsoc_dvars_vals: TARGET-TYPE/fMRI_e00213_tsoc.nii.gz
	$(BIN)/motion_outliers -i $< -o TARGET-TYPE/fMRI_e00213_tsoc_dvars_regressors --dvars -s TARGET-TYPE/fMRI_e00213_tsoc_dvars_vals --nomoco -x fMRI_e00213_tsoc

#> Calculate motion outliers using dvars metric on motion-corrected denoised
TARGET-TYPE/fMRI_e00213_medn_dvars_vals: TARGET-TYPE/fMRI_e00213_medn.nii.gz TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz
	$(BIN)/motion_outliers -i $(word 1,$^) -o TARGET-TYPE/fMRI_e00213_medn_dvars_regressors -m $(word 2,$^) --dvars -s TARGET-TYPE/fMRI_e00213_medn_dvars_vals --nomoco --abs -v -x fMRI_e00213_medn

#> basic dvars
TARGET-TYPE/fMRI_e002_dvars_vals: TARGET-TYPE/fMRI_e002.nii.gz
	$(BIN)/motion_outliers -i $< -o TARGET-TYPE/fMRI_e002_dvars_regressors --dvars -s TARGET-TYPE/fMRI_e002_dvars_vals -x fMRI_e002 

#> Collect all dvars files (tsoc, medn, 3002)
TARGET-TYPE/fMRI_dvars_vals: TARGET-TYPE/fMRI_e002_dvars_vals TARGET-TYPE/fMRI_e00213_medn_dvars_vals TARGET-TYPE/fMRI_e00213_tsoc_dvars_vals
	paste TARGET-TYPE/*dvars_vals  > $@ ;\
	paste TARGET-TYPE/*dvars_thresh > TARGET-TYPE/fMRI_dvars_thresh 

#> Calculate motion outliers using fd
TARGET-TYPE/fMRI_e00213_tsoc_fd_vals: TARGET-TYPE/fMRI_e00213_tsoc.nii.gz
	$(BIN)/motion_outliers -i $< -o TARGET-TYPE/fMRI_e00213_tsoc_fd_regressors_mcflirt --fd -s TARGET-TYPE/fMRI_e00213_tsoc_fd_vals --thresh=$(FDTHRESH) -x fMRI_e00213_tsoc

#> FD outliers on motion-corrected denoised
TARGET-TYPE/fMRI_e00213_medn_fd_vals: TARGET-TYPE/fMRI_e00213_medn.nii.gz TARGET-TYPE/meica.fMRI_e00213/motion.1D.rad
	prefix=$(subst .nii.gz,,$(word 1,$^)) ;\
	$(BIN)/motion_outliers -i $(word 1,$^) -o $${prefix}_fd_regressors_mcflirt --fd -s $${prefix}_fd_vals --thresh=$(FDTHRESH) --nomoco -c $(word 2,$^) -x fMRI_e00213_medn

#> basic fd
TARGET-TYPE/fMRI_e002_fd_vals: TARGET-TYPE/fMRI_e002.nii.gz
	$(BIN)/motion_outliers -i $< -o TARGET-TYPE/fMRI_e002_fd_regressors_mcflirt --fd -s TARGET-TYPE/fMRI_e002_fd_vals --thresh=$(FDTHRESH) -x fMRI_e002


#> collect all fd files
TARGET-TYPE/fMRI_fd_vals: TARGET-TYPE/fMRI_e002_fd_vals TARGET-TYPE/fMRI_e00213_medn_fd_vals TARGET-TYPE/fMRI_e00213_tsoc_fd_vals 
	paste TARGET-TYPE/fMRI_e002_fd_vals TARGET-TYPE/fMRI_e00213_medn_fd_vals > $@

#> ERSN
TARGET-TYPE/fMRI_e002_SN_outliers.txt: TARGET-TYPE/fMRI_e002.nii.gz
	$(BIN)/ibicIDSN $(word 1,$^) $(TR)

#> Convert motion displacement to radians
TARGET-TYPE/meica.fMRI_e00213/motion.1D.rad: TARGET-TYPE/meica.fMRI_e00213/motion.1D
	Rscript $(BIN)/R/motion2rad.R $< $@

#> Find outliers and remove duplicates
TARGET-TYPE/$(subject)_all_outliers.txt: TARGET-TYPE/fMRI_e002_dvars_vals TARGET-TYPE/fMRI_e002_fd_vals TARGET-TYPE/fMRI_e002_SN_outliers.txt
	targets="$(subst vals,spike_vols,$^)" ;\
	$(BIN)/binarize_outliers $(subject) TARGET-TYPE/fMRI_e002.nii.gz TARGET-TYPE $${targets}

#################
# Registrations #
#################

#? Write transformation matrices
TARGET-TYPE-registrations: xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.mat xfm_dir/T1_to_TARGET-TYPE_e00213_tsoc_reoriented.mat  xfm_dir/fs_to_TARGET-TYPE_e00213_tsoc_reoriented.mat xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_fs.mat 

#> Resting state optimally combined to T1 matrix with epi-reg
xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.mat: TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz $(T1) $(T1_brain)
	mkdir -p xfm_dir ;\
	epi_reg --epi=$(word 1,$^) --t1=$(word 2,$^) --t1brain=$(word 3,$^) --out=$(basename $@) 

#> inverse target to T1 matrix
xfm_dir/T1_to_TARGET-TYPE_e00213_tsoc_reoriented.mat: xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.mat
	convert_xfm -omat $@ -inverse $<

#> inverse target to freesurfer matrix
xfm_dir/fs_to_TARGET-TYPE_e00213_tsoc_reoriented.mat: xfm_dir/T1_to_TARGET-TYPE_e00213_tsoc_reoriented.mat xfm_dir/fs_to_T1.mat 
	convert_xfm -omat $@ -concat $(word 1,$^) $(word 2, $^)

#> inverse freesurfer to tsoc matrix
xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_fs.mat: xfm_dir/fs_to_TARGET-TYPE_e00213_tsoc_reoriented.mat
	convert_xfm -omat $@ -inverse $<

############################
# epireg ANTs registration #
############################

#? rest to custom template using epireg & ants
TARGET-TYPE-epireg: xfm_dir/TARGET-TYPE_e00213_tsoc_to_CT_epireg_ants.nii.gz  xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz QA/images/TARGET-TYPE_e00213_tsoc_to_CT_epireg_ants.gif QA/images/TARGET-TYPE_e00213_tsoc_reoriented_to_mni_epireg_ants.gif QA/images/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.gif

#> Convert resting optimally combined to T1 FSL matrix to ITK format
xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1_ras.txt: xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.mat 
	c3d_affine_tool -ref $(T1_brain) -src TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz $< -fsl2ras -oitk $@

#> Overlay of optimally combined resting state to T1 registration 
QA/images/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.gif: xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1.mat $(T1_brain)
	name=$(basename $@) ;\
	$(BIN)/sliceappend.sh -1 $(basename $(word 1,$^)).nii.gz -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ ;\
	rm $${name}.png

#> Transform resting optimally combined to CT by concatenating epireg rest->T1 transform and ANTs T1->CT nonlinear transform
xfm_dir/TARGET-TYPE_e00213_tsoc_to_CT_epireg_ants.nii.gz: TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz $(PROJECT_DIR)/standard/Subject-specific_template.nii.gz xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1_ras.txt xfm_dir/T1_to_CT_deformed.nii.gz
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 $(word 1,$^) $@ $(word 2,$^) xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt $(word 3,$^)

#> Overlay image of rest to CT image and CT template (subject-specific_template)
QA/images/TARGET-TYPE_e00213_tsoc_to_CT_epireg_ants.gif: xfm_dir/TARGET-TYPE_e00213_tsoc_to_CT_epireg_ants.nii.gz $(PROJECT_STANDARD)
	name=$(basename $@) ;\
	$(BIN)/sliceappend.sh -1 $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ ;\
	rm $${name}.png

# rest to MNI using epireg & ants

#> Transform resting optimally combined to MNI: concatenate epireg rest->T1 transform, ANTs T1->CT nonlinear transform, CT->MNI nonlinear transform
xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz: TARGET-TYPE/fMRI_e00213_tsoc_reoriented_vol0.nii.gz $(MNI2mmBRAIN) $(PROJECT_DIR)/standard/CT_to_mni_Warp.nii.gz $(PROJECT_DIR)/standard/CT_to_mni_Affine.txt xfm_dir/T1_to_CT_deformed.nii.gz xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1_ras.txt
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_T1_ras.txt

#> Overlay of optimally combined image with MNI, registered with ANTs
QA/images/TARGET-TYPE_e00213_tsoc_reoriented_to_mni_epireg_ants.gif: xfm_dir/TARGET-TYPE_e00213_tsoc_reoriented_to_mni_epireg_ants.nii.gz $(MNI2mmBRAIN)
	name=$(basename $@) ;\
	$(BIN)/sliceappend.sh -1  $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1000 $@ ;\
	rm $${name}.png

# ###########
# # MCFLIRT #
# ###########

#? Make mcflirt motion parameters, using the second echo, to compare with meica parameters. 
TARGET-TYPE-mcflirt: mcflirt_data/TARGET-TYPE_data.par

#> Run mcflirt on resting state data, second echo
mcflirt_data/TARGET-TYPE_data.par: TARGET-TYPE/fMRI_e002.nii.gz
	mkdir -p mcflirt_data ;\
	mcflirt -in $< -out $(basename $@) -rmsrel -rmsabs -plots


##    ##
## QA ##
##    ##

##########
# Movies #
##########

#? Resting state meica movies
TARGET-TYPE-meicamovies: QA/images/TARGET-TYPE_e00213_medn_x_animation.gif QA/images/TARGET-TYPE_e00213_tsoc_x_animation.gif QA/images/TARGET-TYPE_e00213_mefc_x_animation.gif

#? Movies of the original data
TARGET-TYPE-rawmovies: QA/images/TARGET-TYPE_e001_x_animation.gif QA/images/TARGET-TYPE_e002_x_animation.gif QA/images/TARGET-TYPE_e003_x_animation.gif

# these are individual to avoid conflict with similarily named files

#> animations for meica'd files
QA/images/TARGET-TYPE_e00213_%_x_animation.gif: TARGET-TYPE/fMRI_e00213_%.nii.gz
	mkdir -p $(dir $@) ;\
	$(BIN)/functional_movies_meica $< QA/images/ 1

#> animations for base files
QA/images/TARGET-TYPE_e00%_x_animation.gif: TARGET-TYPE/fMRI_e00%.nii.gz
	mkdir -p $(dir $@) ;\
	$(BIN)/functional_movies_meica $< QA/images/ 1


################
# MotionGraphs #
################

#? These make the summary graphs for rotations, translations, fd, and dvars
TARGET-TYPE-motiongraphs: QA/images/TARGET-TYPE_e002_MotionGraphRotations.gif

#> This makes rotations, translations, fd, and both dvars files
# If you have to remake any of those, rm QA/images/*Motion* and rerun
QA/images/TARGET-TYPE_e002_MotionGraphRotations.gif: TARGET-TYPE/fMRI_e002.nii.gz TARGET-TYPE/fMRI_dvars_vals TARGET-TYPE/fMRI_fd_vals 
	mkdir -p QA/images/ ;\
	Rscript $(RScripts)/MakingGraphs.R e002 TARGET-TYPE 
	for i in QA/images/*.png ; do convert $$i `dirname $$i`/`basename $$i .png`.gif ; done ;\
	rm QA/images/*.png


# ###############
# # TSNR - fMRI #
# ###############

#? threshold signal-to-noise ratio for functional scans
TARGET-TYPE-TSNR: QA/images/TARGET-TYPE_e001_tsdiffana.gif QA/images/TARGET-TYPE_e002_tsdiffana.gif QA/images/TARGET-TYPE_e003_tsdiffana.gif QA/images/TARGET-TYPE_e001_tsnr_z.gif QA/images/TARGET-TYPE_e002_tsnr_z.gif QA/images/TARGET-TYPE_e003_tsnr_z.gif

#> I don't know how to describe this one.
QA/images/TARGET-TYPE_%_tsdiffana.gif: TARGET-TYPE/fMRI_%.nii.gz
	mkdir -p QA/images/ ;\
	nipy_tsdiffana --out-file $(basename $@).png $< ;\
	convert $(basename $@).png $@ ;\
	rm $(basename $@).png

#> or this one.
QA/images/TARGET-TYPE_%_tsnr_z.gif: TARGET-TYPE/fMRI_%.nii.gz
	mkdir -p QA/images/ ;\
	python $(BIN)/TSNR_Images.py -i $< ;\
	name=$(subst .nii.gz,,$(notdir $<)) ;\
	$(BIN)/make_xyz $${name}_tsnr.nii.gz QA/images/ 2 50 ;\
	$(BIN)/make_xyz $${name}_tsnr_mean.nii.gz QA/images/ 2 50 ;\
	$(BIN)/make_xyz $${name}_tsnr_stddev.nii.gz QA/images/ 2 50 ;\
	rm $${name}_tsnr.nii.gz $${name}_tsnr_mean.nii.gz $${name}_tsnr_stddev.nii.gz
