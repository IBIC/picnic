# Create Registration Matrices between T1 and Custom Subjects Template (CT) and MNI (2mm FSL) spaces

FREESURFER_SETUP=/usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh

StructuralRegistrations: xfm_dir/T1_to_fs.mat xfm_dir/T1_to_CT_deformed.nii.gz QA/images/T1_to_CT_deformed.gif xfm_dir/T1_to_mni_deformed.nii.gz QA/images/T1_to_mni_deformed.gif QA/images/T1_fs_brain.gif QA/images/wm.gif QA/images/gm.gif QA/images/csf.gif mprage/T1_fs_brain_wmseg.nii.gz mprage/T1_fs_brain.nii.gz

######################################################################
# Inverse of Registration matrix for Freesurfer space to T1
# (i.e., T1 to freesurfer space transformation)
xfm_dir/T1_to_fs.mat: xfm_dir/fs_to_T1.mat
	convert_xfm -omat $@ -inverse xfm_dir/fs_to_T1.mat

#Registration matrix for T1 MPRAGE to Freesurfer space
xfm_dir/fs_to_T1.mat: $(SUBJECTS_DIR)/$(subject).s$(SESSION)/mri/aparc+aseg.mgz
	mkdir -p xfm_dir ;\
	source $(FREESURFER_SETUP);\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	tkregister2 --mov $(SUBJECTS_DIR)/$(subject).s$(SESSION)/mri/orig.mgz --targ mprage/T1.nii.gz --noedit --regheader --reg xfm_dir/fs_to_T1.dat --fslregout xfm_dir/fs_to_T1_init.mat ;\
	mri_convert $(SUBJECTS_DIR)/$(subject).s$(SESSION)/mri/orig.mgz $(SUBJECTS_DIR)/$(subject).s$(SESSION)/mri/orig.nii.gz ;\
	flirt -ref mprage/T1.nii.gz -in $(SUBJECTS_DIR)/$(subject).s$(SESSION)/mri/orig.nii.gz -init xfm_dir/fs_to_T1_init.mat -omat $@

######################################################################
# Ants registrations from T1 to Custom Subjects Template (CT) and from
#T1 to 2 mm MNI (through CT intermediate). 

# Register skull stripped brain to Subject specific template using ANTS
xfm_dir/T1_to_CT_deformed.nii.gz: mprage/T1_brain.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/antsIntroduction.sh -d 3 -i $(word 1,$^) -m 30x90x20 -o $(SubjDIR)/xfm_dir/T1_to_CT_ -s CC -r $(word 2,$^) -t GR

# Overlay image of T1 to CT image over subject specific template
QA/images/T1_to_CT_deformed.gif: xfm_dir/T1_to_CT_deformed.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz
	mkdir -p QA/images ;\
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1 $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1500 $@ 

# Register the T1 to MNI space, through the nonlinear transform to CT and
# the nonlinear transform from CT to MNI
xfm_dir/T1_to_mni_deformed.nii.gz: mprage/T1_brain.nii.gz $(MNI2mmBRAIN) $(STANDARD_DIR)/CT_to_mni_Warp.nii.gz $(STANDARD_DIR)/CT_to_mni_Affine.txt xfm_dir/T1_to_CT_deformed.nii.gz
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)/WarpImageMultiTransform 3 mprage/T1_brain.nii.gz $@ -R $(MNI2mmBRAIN) $(STANDARD_DIR)/CT_to_mni_Warp.nii.gz $(STANDARD_DIR)/CT_to_mni_Affine.txt xfm_dir/T1_to_CT_Warp.nii.gz xfm_dir/T1_to_CT_Affine.txt	

# Overlay image of T1 to MNI image
QA/images/T1_to_mni_deformed.gif: xfm_dir/T1_to_mni_deformed.nii.gz $(MNI2mmBRAIN)
	mkdir -p QA/images ;\
	name=`dirname $@`/`basename $@ .gif` ;\
	$(BIN)/sliceappend.sh -1 $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 1500 $@ 

###############################################################################
# QA images with Freesurfer output

# A little rule to convert mgz files to .nii.gz files
%.nii.gz: %.mgz
	mri_convert $< $@

# Create Freesurfer brain mask - it should be most accurate
mprage/T1_fs_brain_mask.nii.gz: xfm_dir/fs_to_T1.mat $(SUBJECTS_DIR)/$(subject).s$(SESSION)/mri/brainmask.nii.gz
	flirt -ref mprage/T1.nii.gz -in $(word 2,$^) -init $(word 1,$^) -applyxfm -out $@ ;\
	fslmaths $@ -bin $@

# Use freesurfer brain mask to actually mask out the brain
mprage/T1_fs_brain.nii.gz: mprage/T1.nii.gz mprage/T1_fs_brain_mask.nii.gz
	fslmaths $(word 1,$^) -mul  $(word 2,$^) $@

# QA image of freesurfer brain mask on top of T1
QA/images/T1_fs_brain.gif: mprage/T1.nii.gz mprage/T1_fs_brain_mask.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 mprage/T1.nii.gz -a $(word 2,$^) 1 10 mprage/rendered_T1_brain.nii.gz ;\
	$(BIN)/slices mprage/rendered_T1_brain.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm mprage/rendered_T1_brain.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

###############################################################################
# Segmentation with FAST and some pretty QA images

mprage/T1_fs_brain_wmseg.nii.gz: mprage/T1_fs_brain.nii.gz
	rm -f $@ ;\
	mkdir -p mprage/fast_segmentation ;\
	fast -n 3 -t 1 -o mprage/fast_segmentation/T1_fs_brain $(word 1,$^) ;\
	fslmaths mprage/fast_segmentation/T1_fs_brain_pve_2 -thr 0.5 -bin $@ ;\

QA/images/csf.gif: mprage/T1_fs_brain.nii.gz mprage/T1_fs_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a mprage/fast_segmentation/T1_fs_brain_pve_0 1 10 QA/rendered_csf.nii.gz ;\
	$(BIN)/slices QA/rendered_csf.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_csf.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

QA/images/gm.gif: mprage/T1_fs_brain.nii.gz mprage/T1_fs_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a mprage/fast_segmentation/T1_fs_brain_pve_1 1 10 QA/rendered_gm.nii.gz ;\
	$(BIN)/slices QA/rendered_gm.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_gm.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

QA/images/wm.gif: mprage/T1_fs_brain.nii.gz mprage/T1_fs_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a mprage/fast_segmentation/T1_fs_brain_pve_2 1 10 QA/rendered_wm.nii.gz ;\
	$(BIN)/slices QA/rendered_wm.nii.gz -o `dirname $@`/`basename $@ .gif`.png
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_wm.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

QA/images/wm_seg.gif: mprage/T1_fs_brain.nii.gz mprage/T1_fs_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a $(word 2,$^) 1 10 QA/rendered_wm_seg.nii.gz ;\
	$(BIN)/slices QA/rendered_wm_seg.nii.gz -o `dirname $@`/`basename $@ .gif`.png
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_wm_seg.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

