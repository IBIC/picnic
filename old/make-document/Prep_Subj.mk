### Unpacks nifties, PARRECs

.PHONY: PrepSubject ConvertCommon ConvertOn ConvertOff PrepStructurals
#.SECONDARY:

#! always use the same version of MATLAB
#*SKIP
MATLABCompiler=/usr/local/MATLAB/MATLAB_Runtime/v81 

# all:

# test whether this is a control or PD
ifeq ($(strip $(GROUP)),CONTROL)
PrepSubject: ConvertCommon ConvertOn PrepStructurals
else
PrepSubject: ConvertCommon ConvertOn ConvertOff PrepStructurals PrepStructuralsOff
endif

#? Convert survey, flair, T1 PAR/RECS to nifti. 
ConvertCommon: flair/Flair.nii.gz mprage/T1.nii.gz dti/blipA.nii.gz

#? Convert ON scans
#*SKIP
ConvertOn: pcasl-on/Pcasl.nii.gz rest-on/rest_e001.nii.gz axcpt-on/rest_e001.nii.gz fieldmap-on/B0_mag_fMRI.nii.gz

#? Convert OFF scans
ConvertOff: pcasl-off/Pcasl.nii.gz rest-off/rest_e001.nii.gz axcpt-off/rest_e001.nii.gz fieldmap-off/B0_mag_fMRI.nii.gz

#
# Scans for which there is only one per subject
#

#> Convert and reorient Flair
#*SKIP
flair/Flair.nii.gz: parrec/FLAIR.zip
	mkdir -p flair
	unzip $(word 1,$^) -d flair/ ;\
	$(BIN)/run_ConvertR2A.sh $(MATLABCompiler) $(SubjDIR)/flair/ ;\
	rm -f flair/*.PAR flair/*.REC flair/*.XML flair/*.LOG ;\
	mv flair/*FLAIR*.nii flair/Flair.nii ;\
	gzip flair/*.nii ;\
	fslreorient2std flair/Flair.nii.gz flair/Flair.nii.gz

#> Convert DTI
dti/blipA.nii.gz: parrec/DTI-BlipA.zip parrec/DTI-BlipP.zip
	mkdir -p dti ;\
	unzip parrec/DTI-BlipA.zip -d dti/ ;\
	unzip parrec/DTI-BlipP.zip -d dti/ ;\
	parrec2nii -v -b -c --scaling fp --overwrite -d --field-strength=3 -o dti dti/*PAR ;\
	rm -f dti/*.PAR dti/*.REC dti/*.XML dti/*.LOG ;\
	mv dti/*BlipA*.nii.gz dti/blipA.nii.gz ;\
	mv dti/*BlipA*.bvals dti/blipA.bvals ;\
	mv dti/*BlipA*.bvecs dti/blipA.bvecs ;\
	mv dti/*BlipP*.nii.gz dti/blipP.nii.gz ;\
	mv dti/*BlipP*.bvals dti/blipP.bvals ;\
	mv dti/*BlipP*.bvecs dti/blipP.bvecs 

#> Convert and reorient MPRAGE 
mprage/T1.nii.gz: parrec/MPRAGE.zip
	mkdir -p mprage ;\
	unzip $(word 1,$^) -d mprage ;\
	$(BIN)/run_ConvertR2A.sh $(MATLABCompiler) $(SubjDIR)/mprage/ 
	rm -f mprage/*.PAR  mprage/*.REC mprage/*.XML mprage/*.LOG ;\
	mv mprage/*.nii mprage/T1.nii ;\
	gzip mprage/T1.nii ;\
	fslreorient2std mprage/T1.nii.gz mprage/T1.nii.gz

#
# ON/OFF scans
#

#> PCASL conversion should be done with mcverter in subject_setup
pcasl-%/Pcasl.nii.gz: 
	mkdir -p pcasl-$*
	cp dicom/*PCASL*.nii.gz pcasl-$* ;\
	mv pcasl-$*/PCASL_pld*.nii.gz pcasl-$*/Pcasl.nii.gz 

#> Convert resting state
rest-%/rest_e001.nii.gz: parrec/rest_%.zip
	mkdir -p rest-$* ;\
	unzip $(word 1,$^) -d rest-$*/ ;\
	$(BIN)/run_ConvertR2A.sh $(MATLABCompiler) $(SubjDIR)/rest-$*/ ;\
	rm -f rest-$*/*.PAR rest-$*/*.REC rest-$*/*.XML rest-$*/*.LOG ;\
	for i in `seq 1 3`; do mv rest-$*/*RS*-e00$${i}*.nii rest-$*/rest_e00$${i}.nii; done ;\
	gzip rest-$*/*.nii

#> Convert task scan
axcpt-%/rest_e001.nii.gz: parrec/axcpt_%.zip
	mkdir -p axcpt-$* ;\
	unzip $(word 1,$^) -d axcpt-$*/ ;\
	$(BIN)/run_ConvertR2A.sh $(MATLABCompiler) $(SubjDIR)/axcpt-$*/ ;\
	rm -f axcpt-$*/*.PAR axcpt-$*/*.REC axcpt-$*/*.XML axcpt-$*/*.LOG ;\
	for i in `seq 1 3`; do mv axcpt-$*/*Task*-e00$${i}*.nii axcpt-$*/rest_e00$${i}.nii; done ;\
	gzip axcpt-$*/*.nii

#> convert B0 fieldmap
fieldmap-%/B0_mag_fMRI.nii.gz: parrec/B0-ME_%.zip
	mkdir -p fieldmap-$* ;\
	unzip $(word 1,$^) -d fieldmap-$*/ ;\
	$(BIN)/run_ConvertR2A.sh $(MATLABCompiler) $(SubjDIR)/fieldmap-$*/ ;\
	rm -f fieldmap-$*/*.PAR fieldmap-$*/*.REC fieldmap-$*/*.XML fieldmap-$*/*.LOG ;\
	mv fieldmap-$*/*B0_ME*2.nii fieldmap-$*/B0_mag_fMRI.nii ;\
	mv fieldmap-$*/*B0_ME*5.nii fieldmap-$*/B0_phase_fMRI.nii ;\
	gzip fieldmap-$*/*.nii

#
# PrepStructurals
#

#? Combining, Reorienting and Skullstripping
PrepStructurals: mprage/T1_brain.nii.gz fieldmap-on/B0_mag_fMRI_brain.nii.gz
PrepStructuralsOff: fieldmap-off/B0_mag_fMRI_brain.nii.gz 

#> skull-stripped brain
mprage/T1_brain.nii.gz: mprage/T1.nii.gz
	bet $< $@ -B -f .1

#> skull-stripped fieldmap
fieldmap-%/B0_mag_fMRI_brain.nii.gz: fieldmap-%/B0_mag_fMRI.nii.gz
	bet fieldmap-$*/B0_mag_fMRI.nii.gz fieldmap-$*/B0_mag_fMRI_brain.nii.gz -R

# requires freesurfer
mprage/T1_in_fs.nii.gz: $(SUBJECTS_DIR)/$(subject).s1/mri/T1.mgz
	source $(FREESURFER_SETUP) ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	mri_convert $(word 1,$^) $@



#
# Testing
#

test-grp:
	@echo $(GROUP)
