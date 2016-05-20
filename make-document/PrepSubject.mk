### Unpacks nifties, PARRECs


.PHONY: PrepSubject ConvertAll PrepStructurals
.SECONDARY:

PrepSubject: ConvertAll PrepStructurals


# Convert all of those PAR files to nifti. Will convert everything in the working directory, not just Survey
ConvertAll:session_info/Survey.nii.gz swi/SWI_mag.nii.gz flair/Flair.nii.gz pcasl/Pcasl.nii.gz mprage/T1.nii.gz rest/rest_e001.nii.gz fieldmap/B0_mag_fMRI.nii.gz T2/T2.nii.gz breathhold/breathhold_e001.nii.gz

session_info/Survey.nii.gz: parrec/Survey.ZIP
	# Create Survey.nii.gz	
	mkdir -p session_info ;\
	unzip $(word 1,$^) -d session_info/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/session_info/ ;\
	rm -f session_info/*.PAR session_info/*.REC  session_info/*.XML  session_info/*.LOG ;\
	mv session_info/*WIP_Survey*.nii session_info/Survey.nii ;\
	gzip session_info/*.nii

# SWI
swi/SWI_mag.nii.gz: parrec/SWI.ZIP
	mkdir -p swi ;\
	unzip $(word 1,$^) -d swi/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/swi/ ;\
	rm -f swi/*.PAR swi/*.REC swi/*.XML  swi/*.LOG ;\
	mv swi/*SWI*000* swi/SWI_mag.nii ;\
	mv swi/*SWI*003* swi/SWI_phase.nii ;\
	gzip swi/*.nii


flair/Flair.nii.gz: parrec/FLAIR.ZIP
	# Convert and reorient flair
	mkdir -p flair
	unzip $(word 1,$^) -d flair/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/flair/ ;\
	rm -f flair/*.PAR flair/*.REC flair/*.XML flair/*.LOG ;\
	mv flair/*FLAIR*.nii flair/Flair.nii ;\
	gzip flair/*.nii ;\
	fslreorient2std flair/Flair.nii.gz flair/Flair.nii.gz


T2/T2.nii.gz: parrec/3DT2.ZIP
	# Convert and reorient 3DT2
	mkdir -p T2
	unzip $(word 1,$^) -d T2/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/T2/ ;\
	rm -f T2/*.PAR T2/*.REC T2/*.XML T2/*.LOG ;\
	mv T2/*3DT2*.nii T2/T2.nii ;\
	gzip T2/*.nii ;\
	fslreorient2std T2/T2.nii.gz T2/T2.nii.gz


# Convert DTI
dti/blipA.nii.gz: parrec/DTI-BlipA.ZIP parrec/DTI-BlipP.ZIP
	mkdir -p dti
	unzip parrec/DTI-BlipA.ZIP -d dti/ ;\
	unzip parrec/DTI-BlipP.ZIP -d dti/ ;\
	parrec2nii -v -b -c --scaling fp --overwrite -d --field-strength=3 -o dti dti/*PAR
	rm -f dti/*.PAR dti/*.REC dti/*.XML dti/*.LOG ;\
	mv dti/*BlipA*.nii.gz dti/blipA_DWIs.nii.gz ;\
	mv dti/*BlipA*.bvals dti/blipA.bvals ;\
	mv dti/*BlipA*.bvecs dti/blipA.bvecs ;\
	mv dti/*BlipP*.nii.gz dti/blipP_DWIs.nii.gz ;\
	mv dti/*BlipP*.bvals dti/blipP.bvals ;\
	mv dti/*BlipP*.bvecs dti/blipP.bvecs 


# PCASL conversion should be done with mcverter. This conversion is done in
# subject_setup
pcasl/Pcasl.nii.gz: 
	mkdir -p pcasl
	cp dicom/*PCASL*.nii.gz pcasl ;\
	mv pcasl/PCASL_pld*.nii.gz pcasl/Pcasl.nii.gz 


mprage/T1.nii.gz: parrec/MPRAGE.ZIP
	# Convert and reorient MPRAGE 
	mkdir -p mprage ;\
	unzip $(word 1,$^) -d mprage ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/mprage/ 
	rm -f mprage/*.PAR  mprage/*.REC mprage/*.XML mprage/*.LOG ;\
	mv mprage/*.nii mprage/T1.nii ;\
	gzip mprage/T1.nii ;\
	fslreorient2std mprage/T1.nii.gz mprage/T1.nii.gz


rest/rest_e001.nii.gz: parrec/ME-RS.ZIP
	# Convert resting state
	mkdir -p rest ;\
	unzip $(word 1,$^) -d rest/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/rest/ ;\
	rm -f rest/*.PAR rest/*.REC rest/*.XML rest/*.LOG ;\
	for i in `seq 1 3`; do mv rest/*RS*-e00$${i}*.nii rest/rest_e00$${i}.nii; done ;\
	gzip rest/*.nii

breathhold/breathhold_e001.nii.gz: parrec/Breathhold.ZIP
	# Convert resting state
	mkdir -p breathhold ;\
	unzip $(word 1,$^) -d breathhold/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/breathhold/ ;\
	rm -f breathhold/*.PAR breathhold/*.REC breathhold/*.XML breathhold/*.LOG ;\
	for i in `seq 1 3`; do mv breathhold/*BreathHold*-e00$${i}*.nii breathhold/breathhold_e00$${i}.nii; done ;\
	gzip breathhold/*.nii

# convert B0 fieldmap
fieldmap/B0_mag_fMRI.nii.gz: parrec/B0-ME.ZIP
	unzip $(word 1,$^) -d fieldmap/ ;\
	$(BIN)/run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Runtime/v81 $(SubjDIR)/fieldmap/ ;\
	rm -f fieldmap/*.PAR fieldmap/*.REC fieldmap/*.XML fieldmap/*.LOG ;\
	mv fieldmap/*B0_ME*2.nii fieldmap/B0_mag_fMRI.nii ;\
	mv fieldmap/*B0_ME*5.nii fieldmap/B0_phase_fMRI.nii ;\
	gzip fieldmap/*.nii


#####################
#Combining, Reorienting and Skullstripping

PrepStructurals: mprage/T1_brain.nii.gz fieldmap/B0_mag_fMRI_brain.nii.gz 


#####################
# Skull Stripping
mprage/T1_brain.nii.gz: mprage/T1.nii.gz
	bet $< $@ -B -f .1

fieldmap/B0_mag_fMRI_brain.nii.gz: fieldmap/B0_mag_fMRI.nii.gz
	bet fieldmap/B0_mag_fMRI.nii.gz fieldmap/B0_mag_fMRI_brain.nii.gz -R


