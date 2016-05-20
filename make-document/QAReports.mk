# Makes the QA .html files


.PHONY: display QAReports QA_FMRI QA_MPRAGE QA_BH
.SECONDARY:

RMDTEMPLATES=$(LIB)/RmdTemplates

QAReports:  QA/fMRI_Preprocessing.html QA/breathhold.html QA/MPRAGE.html

# shortcuts
QA_FMRI: QA/fMRI_Preprocessing.html
QA_MPRAGE: QA/MPRAGE.html
QA_BH: QA/breathhold.html

# setting the files dependent on the .Rmd file updates them if the markdown script changes

QA/MPRAGE.html: $(RMDTEMPLATES)/MPRAGE.Rmd $(SUBJECTS_DIR)/QA/$(subject).s1/rgb/snaps/$(subject).s1.html QA/images/T1_brain.gif QA/images/csf.gif QA/images/gm.gif QA/images/wm.gif QA/images/wm_seg.gif QA/images/T1_to_CT_deformed.gif QA/images/T1_to_mni_deformed.gif 
	sed -e 's/SUBJECT/$(subject)/g' $(word 1,$^) > QA/MPRAGE.Rmd ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/MPRAGE.Rmd")'

rgb: $(SUBJECTS_DIR)/QA/$(subject).s1/rgb/snaps/$(subject).s1.html

$(SUBJECTS_DIR)/QA/$(subject).s1/rgb/snaps/$(subject).s1.html: $(SUBJECTS_DIR)/$(subject).s1
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	export QA_TOOLS=/usr/local/freesurfer/QAtools_v1.1/ ;\
	/usr/local/freesurfer/QAtools_v1.1/recon_checker -s $(subject).s1 -snaps-detailed

QA/images/T1_brain.gif: mprage/T1.nii.gz mprage/T1_brain_mask.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 mprage/T1.nii.gz -a $(word 2,$^) 1 10 mprage/rendered_T1_brain.nii.gz ;\
	$(BIN)/slices mprage/rendered_T1_brain.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm mprage/rendered_T1_brain.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

# Generate the QA report for the resting state data. QA report template takes
# two parameters -the subject and the TASK (resting or breathhold)
# Changed the dependencies to no longer rely on PHONY targets (because then it will remake each time) -Trevor
QA/fMRI_Preprocessing.html: $(RMDTEMPLATES)/fMRI.Rmd QA/images/rest/rest_e001_x_animation.gif QA/images/rest/rest_e001_tsdiffana.gif QA/images/rest/rest_e002_MotionGraphRotations.gif QA/images/rest/rest_e00213_medn_x_animation.gif xfm_dir/rest_e00213_tsoc_to_CT_epireg_ants.nii.gz
	sed -e 's/SUBJECT/$(subject)/g' -e 's/TASK/rest/g' -e 's/PARREC/ME-RS_SENSE/g' $(RMDTEMPLATES)/fMRI.Rmd > QA/fMRI_Preprocessing.Rmd ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/fMRI_Preprocessing.Rmd")' ;\

# Generate the QA report for the breathhold data. QA report template takes
# two parameters -the subject and the TASK (resting or breathhold)
QA/breathhold.html: $(RMDTEMPLATES)/fMRI.Rmd QA/images/breathhold/breathhold_e001_x_animation.gif QA/images/breathhold/breathhold_e001_tsdiffana.gif QA/images/breathhold/breathhold_e002_MotionGraphRotations.gif  QA/images/breathhold/breathhold_e00213_medn_x_animation.gif xfm_dir/breathhold_e00213_tsoc_to_CT_epireg_ants.nii.gz 
	sed -e 's/SUBJECT/$(subject)/g' -e 's/TASK/breathhold/g' -e 's/PARREC/BreathHold_Task/g' $(RMDTEMPLATES)/fMRI.Rmd > QA/breathhold.Rmd ;\
	R -e 'library("rmarkdown");rmarkdown::render("QA/breathhold.Rmd")' ;\


# Remove QAreports
QAReports_clean:
	rm -rf QA/breathhold.html QA/fMRI_Preprocessing.html QA/MPRAGE.html


## Adjusted dependencies:
# RawMovies 	-> QA/images/rest/rest_e001_x_animation.gif
# TSNR_fMRI	-> QA/images/rest/rest_e001_tsdiffana.gif
# MotionGraphs	-> QA/images/rest/rest_e002_MotionGraphRotations.gif
# MeicaMovies	-> QA/images/rest/rest_e00213_medn_x_animation.gif
# epireg	-> xfm_dir/rest_e00213_tsoc_to_CT_epireg_ants.nii.gz
#
# BH_RawMovies	-> QA/images/breathhold/breathhold_e001_x_animation.gif
# BH_TSNR	-> QA/images/breathhold/breathhold_e001_tsdiffana.gif
# BH_MotionGraphs -> QA/images/breathhold/breathhold_e002_MotionGraphRotations.gif
# BH_Movies	->  QA/images/breathhold/breathhold_e00213_medn_x_animation.gif
# bh_epireg	-> xfm_dir/breathhold_e00213_tsoc_to_CT_epireg_ants.nii.gz 
