# This makefile runs through the IBIC task preprocessing pipeline

cwd = $(shell pwd) # this dereferences the symlinks in pwd
SUBJECT=$(notdir $(cwd))
SESSNUM=$(shell echo $(cwd) | egrep -oe session[0-9]) # grep for the session number

# Set open MP number of threads to be 1, so that we can parallelize using make.
export OMP_NUM_THREADS=1

SHELL=/bin/bash
PROJECT_DIR=/projects2/act-plus
SubjDIR=$(PROJECT_DIR)/subjects/$(SUBJECT)/$(SESSNUM)
SCRIPTpath=$(PROJECT_DIR)/bin
SUBJECTS_DIR=$(PROJECT_DIR)/freesurfer
TEMPLATES=$(PROJECT_DIR)/templates
FSLpath=/usr/share/fsl/5.0
STANDARD_DIR=$(PROJECT_DIR)/Standard
ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin/
FLEXPATH=$(SCRIPTpath)/wmprogram/sb/cross_platform/scripts
SBBINDIR=$(SCRIPTpath)/wmprogram/sb/linux
REST=rest/rest_e00213_tsoc_reoriented.nii.gz

.PHONY: PrepSubject MoveZips ConvertAll PrepStructurals physio StructRegistrations RawMovies Flex
.SECONDARY:

define task_usage
   @echo
   @echo

   @echo  Usage:
   @echo "make task                 Makes all task related targets"
   @echo "make                      Makes all interactive targets"
   @echo "make noninteractive       Makes all noninteractive targets"
   @echo 
   @echo  Interactive Targets:
   @echo  "make qa 	          Check the outputs of b0, despike, registration"
   @echo
   @echo  Noninteractive Targets:
   @echo  "make task                Run the task pipeline without inspection"
   @echo  
   @echo  Other Useful Targets:
   @echo  "make clean               Remove everything made by task pipeline"
   @echo  "make mostlyclean         Remove intermediates and files not needed later"
   @echo  "make help                Print this message"
   @echo
   @echo
endef

GARBAGE = *~

#########################
# Setup and import data #
#########################

PrepSubject: MoveZips ConvertAll PrepStructurals physio StructRegistrations RawMovies BH_RawMovies
MoveZips: rest/REST.ZIP dti/DTI_BlipA.ZIP dti/DTI_BlipP.ZIP session_info/Survey.ZIP session_info/SuperExportExam.ZIP fieldmap/B0_fMRI.ZIP memprage/MEMPRAGE.ZIP pcasl/PCASL.ZIP flair/FLAIR.ZIP breathhold/BREATHHOLD.ZIP

rest/REST.ZIP: *ME-RS*.ZIP
	mv $(word 1,$^) $@

session_info/Survey.ZIP: *Survey*.ZIP
	mv $(word 1,$^) $@

ifeq ($(wildcard *SuperExport*.ZIP),)
session_info/SuperExportExam.ZIP:

else
session_info/SuperExportExam.ZIP: *SuperExport*.ZIP
	mv $(word 1,$^) $@
endif

fieldmap/B0_fMRI.ZIP: *B0*.ZIP
	mv $(word 1,$^) $@

dti/DTI_BlipA.ZIP: *DTI*A*.ZIP
	mv $(word 1,$^) $@

dti/DTI_BlipP.ZIP: *DTI*P*.ZIP
	mv $(word 1,$^) $@

memprage/MEMPRAGE.ZIP: *MEMPRAGE*.ZIP
	mv $(word 1,$^) $@

pcasl/PCASL.ZIP: *PCASL*.ZIP
	mv $(word 1,$^) $@

flair/FLAIR.ZIP: *FLAIR*.ZIP
	mv $(word 1,$^) $@

breathhold/BREATHHOLD.ZIP: *BREATHHOLD*.ZIP
	mv $(word 1,$^) $@

swi/SWI.ZIP: *SWI*.ZIP
	mv $(word 1,$^) $@

# Covert all of those PAR files to nifti. Will convert everything in the working directory, not just Survey
ConvertAll: session_info/Survey.nii.gz swi/SWI_mag.nii.gz flair/Flair.nii.gz pcasl/Pcasl.nii.gz memprage/MEMPRAGE-e001.nii.gz rest/rest_e001.nii.gz breathhold/BREATHHOLD-e001.nii.gz fieldmap/B0_mag_fMRI.nii.gz dti/DTI32_b1000_BlipA.nii.gz

session_info/Survey.nii.gz: session_info/Survey.ZIP
	unzip $(word 1,$^) -d session_info/ ;\
	cp /mnt/home/ibic/bin/run_ConvertR2A.sh $(SubjDIR) ;\
	cp /mnt/home/ibic/bin/ConvertR2A $(SubjDIR) ;\
	bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime_8.1/v81 $(SubjDIR)/session_info/ ;\
	rm run_ConvertR2A.sh ;\
	rm -r ConvertR2A ;\
	rm session_info/*.PAR ;\
	rm session_info/*.REC ;\
	rm session_info/*.XML ;\
	rm session_info/*.LOG ;\
	mv session_info/*WIP_Survey*.nii session_info/Survey.nii ;\
	mv session_info/*WIP_SuperExportExam*.nii session_info/SuperExportExam.nii ;\
	if [ -e session_info/*.nii]; then gzip session_info/*.ni; fi

swi/SWI_mag.nii.gz: swi/SWI.ZIP
	unzip $(word 1,$^) -d swi/ ;\
	cp /mnt/home/ibic/bin/run_ConvertR2A.sh $(SubjDIR) ;\
	cp /mnt/home/ibic/bin/ConvertR2A $(SubjDIR) ;\
	bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime_8.1/v81 $(SubjDIR)/swi/ ;\
	rm run_ConvertR2A.sh ;\
	rm -r ConvertR2A ;\
	rm swi/*.PAR ;\
	rm swi/*.REC ;\
	rm swi/*.XML ;\
	rm swi/*.LOG ;\
	mv swi/*SWI*000* swi/SWI_mag.nii
	mv swi/*SWI*003* swi/SWI_phase.nii
	gzip swi/*.nii

## nat: re:flair -- dcm2nii has trouble processing parrec files but works okay with dicom files and Flex seems to work fine with the converted files that were originally in dicom format (tested on 109002). Can't find where the ZIP files came from. I will thus work with dicom files first, although this will only work for some of the subjects. 
# 109001 ZIP file missing, must restore from backup
# 109010, 109047-109060 +++ many more missing dicom files

#flair/Flair.nii.gz: flair/*.dcm
#	cp dicom/701_3D-FLAIR*/DICOM/*.dcm flair/ ;\
#	/usr/bin/mricron/dcm2nii -d N -e N -o flair/ -f N -g Y -i N -n Y -p Y -v N flair/*.dcm ;\
#	mv flair/o*.nii.gz flair/Flair.nii.gz ;\
#	rm 

flair/Flair.nii.gz: flair/FLAIR.ZIP
	unzip $(word 1,$^) -d flair/ ;\
	/usr/bin/mricron/dcm2nii -d N -e N -o flair/ -f N -g Y -i N -n Y -p Y -v N flair/*.PAR ;\
	rm flair/*.PAR ;\
	rm flair/*.REC ;\
	mv flair/*FLAIR*.nii.gz $@

pcasl/Pcasl.nii.gz: pcasl/PCASL.ZIP
	mcverter -o $(SubjDIR)/pcasl/. -f fsl -n -d -F+SeriesDescription-PatientName-PatientId-SeriesDate-SeriesTime-StudyId-StudyDescription-SeriesNumber-SequenceName-ProtocolName $(SubjDIR)/dicom/*PCASL*/DICOM/*dcm ;\
	mv $(SubjDIR)/pcasl/*/*/*.nii $(SubjDIR)/pcasl/Pcasl.nii ;\
	mcverter -o $(SubjDIR)/dicom -f fsl -n -d -F+SeriesDescription-PatientName-PatientId-SeriesDate-SeriesTime-StudyId-StudyDescription-SeriesNumber-SequenceName-ProtocolName $(SubjDIR)/dicom/IM* ;\
	mv $(SubjDIR)/dicom/PCASL* $(SubjDIR)/pcasl ;\
	mv $(SubjDIR)/pcasl/PCASL* $(SubjDIR)/pcasl/Pcasl.nii ;\
	gzip pcasl/*.nii ;\
	rm $(SubjDIR)/dicom/*.nii $(SubjDIR)/dicom/*.txt $(SubjDIR)/dicom/DTI*

dti/DTI32_b1000_BlipA.nii.gz: dti/DTI_BlipA.ZIP
	mcverter -o $(SubjDIR)/dti/. -f fsl -n -d -F+SeriesDescription-PatientName-PatientId-SeriesDate-SeriesTime-StudyId-StudyDescription-SeriesNumber-SequenceName-ProtocolName $(SubjDIR)/dicom/*DTI*/DICOM/*dcm ;\
	rm -r $(SubjDIR)/pcasl/$(SUBJECT) ;\
	gzip dti/*.nii

memprage/MEMPRAGE-e001.nii.gz: memprage/MEMPRAGE.ZIP
	unzip $(word 1,$^) -d memprage/ ;\
	cp /mnt/home/ibic/bin/run_ConvertR2A.sh $(SubjDIR) ;\
	cp /mnt/home/ibic/bin/ConvertR2A $(SubjDIR) ;\
	bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime_8.1/v81 $(SubjDIR)/memprage/ ;\
	rm run_ConvertR2A.sh ;\
	rm -r ConvertR2A ;\
	rm memprage/*.PAR ;\
	rm memprage/*.REC ;\
	rm memprage/*.XML ;\
	rm memprage/*.LOG ;\
	for i in `seq 1 4`; do mv memprage/*MEMPRAGE*-e00$${i}*.nii memprage/MEMPRAGE-e00$${i}.nii; done ;\
	gzip memprage/*.nii

rest/rest_e001.nii.gz: rest/REST.ZIP
	unzip $(word 1,$^) -d rest/ ;\
	cp /mnt/home/ibic/bin/run_ConvertR2A.sh $(SubjDIR) ;\
	cp /mnt/home/ibic/bin/ConvertR2A $(SubjDIR) ;\
	bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime_8.1/v81 $(SubjDIR)/rest/ ;\
	rm run_ConvertR2A.sh ;\
	rm -r ConvertR2A ;\
	rm rest/*.PAR ;\
	rm rest/*.REC ;\
	rm rest/*.XML ;\
	rm rest/*.LOG ;\
	for i in `seq 1 3`; do mv rest/*RS*-e00$${i}*.nii rest/rest_e00$${i}.nii; done ;\
	gzip rest/*.nii

breathhold/BREATHHOLD-e001.nii.gz: breathhold/BREATHHOLD.ZIP
	unzip $(word 1,$^) -d breathhold/ ;\
	cp /mnt/home/ibic/bin/run_ConvertR2A.sh $(SubjDIR) ;\
	cp /mnt/home/ibic/bin/ConvertR2A $(SubjDIR) ;\
	bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime_8.1/v81 $(SubjDIR)/breathhold/ ;\
	rm run_ConvertR2A.sh ;\
	rm -r ConvertR2A ;\
	rm breathhold/*.PAR ;\
	rm breathhold/*.REC ;\
	rm breathhold/*.XML ;\
	rm breathhold/*.LOG ;\
	for i in `seq 1 3`; do mv breathhold/*BreathHold*-e00$${i}*.nii breathhold/BREATHHOLD-e00$${i}.nii; done ;\
	gzip breathhold/*.nii

fieldmap/B0_mag_fMRI.nii.gz: fieldmap/B0_fMRI.ZIP
	unzip $(word 1,$^) -d fieldmap/ ;\
	cp /mnt/home/ibic/bin/run_ConvertR2A.sh $(SubjDIR) ;\
	cp /mnt/home/ibic/bin/ConvertR2A $(SubjDIR) ;\
	bash run_ConvertR2A.sh /usr/local/MATLAB/MATLAB_Compiler_Runtime_8.1/v81 $(SubjDIR)/fieldmap/ ;\
	rm run_ConvertR2A.sh ;\
	rm -r ConvertR2A ;\
	rm fieldmap/*.PAR ;\
	rm fieldmap/*.REC ;\
	rm fieldmap/*.XML ;\
	rm fieldmap/*.LOG ;\
	mv fieldmap/*B0_ME*2.nii fieldmap/B0_mag_fMRI.nii ;\
	mv fieldmap/*B0_ME*4.nii fieldmap/B0_phase_fMRI.nii ;\

# Let's do some physio analysis from the rest and breathhold physio data

physio: physio/$(SUBJECT)_rest_cardio.txt physio/$(SUBJECT)_rest_resp.txt physio/$(SUBJECT)_breathhold_cardio.txt physio/$(SUBJECT)_breathhold_resp.txt 

physio/$(SUBJECT)_rest_cardio.txt physio/$(SUBJECT)_rest_resp.txt: physio/*log*
	/projects2/act-plus/bin/act_findphysio $(SUBJECT) rest 720 $(session)

physio/$(SUBJECT)_breathhold_cardio.txt physio/$(SUBJECT)_breathhold_resp.txt: physio/*log*
	/projects2/act-plus/bin/act_findphysio $(SUBJECT) breathhold 305 $(session)

physio/rest.oba.slibase.1D: physio/$(SUBJECT)_rest_cardio.txt physio/$(SUBJECT)_rest_resp.txt
	cd physio ;\
	/projects2/act-plus/bin/McRetroTS.sh $(SUBJECT)_rest_cardio.txt $(SUBJECT)_rest_resp.txt 2.5 43 500 0;\
	mv oba.slibase.1D rest.oba.slibase.1D

physio/breathhold.oba.slibase.1D: physio/$(SUBJECT)_breathhold_cardio.txt physio/$(SUBJECT)_breathhold_resp.txt
	cd physio ;\
	/projects2/act-plus/bin/McRetroTS.sh $(SUBJECT)_breathhold_cardio.txt $(SUBJECT)_breathhold_resp.txt 2.5 43 500 0;\
	mv oba.slibase.1D breathhold.oba.slibase.1D
	gzip fieldmap/*.nii

# Copy the PAR files into the QA directory

CopyPARs: QA/images/PAR/WIP_3D-FLAIR_1mmISO_SENSE_9_1.PAR QA/images/PAR/WIP_B0_ME_CLEAR_5_1.PAR QA/images/PAR/WIP_MEMPRAGE_S2_SENSE_8_1.PAR QA/images/PAR/WIP_DTI32_b1000_BlipA_SENSE_6_1.PAR QA/images/PAR/WIP_DTI32_b1000_BlipA_SENSE_6_1.PAR QA/images/PAR/WIP_DTI32_b1000_BlipP_SENSE_7_1.PAR QA/images/PAR/WIP_ME-RS_SENSE_3_1.PAR QA/images/PAR/WIP_PCASL_pld2000_SENSE_11_1.PAR QA/images/PAR/WIP_Survey_32ch_HeadCoil_1_1.PAR QA/images/PAR/WIP_SWI-0.75x0.75x2_SENSE_10_1.PAR QA/images/PAR/WIP_VPC_SENSE_4_1.PAR

QA/images/PAR/WIP_3D-FLAIR_1mmISO_SENSE_9_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_3D-FLAIR_1mmISO_SENSE_9_1.PAR
	cp $(word 1,$^) $@

QA/images/PAR/WIP_B0_ME_CLEAR_5_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_B0_ME_CLEAR_5_1.PAR
	cp $(word 1,$^) $@

QA/images/PAR/WIP_MEMPRAGE_S2_SENSE_8_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_MEMPRAGE_S2_SENSE_8_1.PAR 
	cp $(word 1,$^) $@

QA/images/PAR/WIP_DTI32_b1000_BlipA_SENSE_6_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_DTI32_b1000_BlipA_SENSE_6_1.PAR 
	cp $(word 1,$^) $@

QA/images/PAR/WIP_DTI32_b1000_BlipP_SENSE_7_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_DTI32_b1000_BlipP_SENSE_7_1.PAR
	cp $(word 1,$^) $@

QA/images/PAR/WIP_ME-RS_SENSE_3_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_ME-RS_SENSE_3_1.PAR 
	cp $(word 1,$^) $@

QA/images/PAR/WIP_PCASL_pld2000_SENSE_11_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_PCASL_pld2000_SENSE_11_1.PAR
	cp $(word 1,$^) $@

QA/images/PAR/WIP_Survey_32ch_HeadCoil_1_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_Survey_32ch_HeadCoil_1_1.PAR
	cp $(word 1,$^) $@

QA/images/PAR/WIP_SWI-0.75x0.75x2_SENSE_10_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_SWI-0.75x0.75x2_SENSE_10_1.PAR
	cp $(word 1,$^) $@

QA/images/PAR/WIP_VPC_SENSE_4_1.PAR: $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/parrec/$(SUBJECT)_WIP_VPC_SENSE_4_1.PAR
	cp $(word 1,$^) $@

###################
# PrepStructurals #
###################

# Combine, reorient an skullstrip files

PrepStructurals: memprage/T1.nii.gz memprage/T1_brain.nii.gz fieldmap/B0_mag_fMRI_brain.nii.gz $(SUBJECTS_DIR)/$(SUBJECT) memprage/T1_brain_mask.nii.gz QA/images/T1_brain.gif memprage/T1_brain_wmseg.nii.gz QA/images/csf.gif QA/images/gm.gif QA/images/wm.gif QA/images/wm_seg.gif

memprage/T1.nii.gz: memprage/MEMPRAGE-e001.nii.gz
	fslmaths memprage/MEMPRAGE-e001 -sqr memprage/MEMPRAGE-e001_sqr ;\
	fslmaths memprage/MEMPRAGE-e002 -sqr memprage/MEMPRAGE-e002_sqr ;\
	fslmaths memprage/MEMPRAGE-e003 -sqr memprage/MEMPRAGE-e003_sqr ;\
	fslmaths memprage/MEMPRAGE-e004 -sqr memprage/MEMPRAGE-e004_sqr ;\
	fslmaths memprage/MEMPRAGE-e001_sqr -add memprage/MEMPRAGE-e002_sqr -add memprage/MEMPRAGE-e003_sqr -add memprage/MEMPRAGE-e004_sqr -div 4 -sqrt memprage/MEMPRAGE ;\
	fslreorient2std memprage/MEMPRAGE memprage/T1

fieldmap/B0_mag_fMRI_brain.nii.gz: fieldmap/B0_mag_fMRI.nii.gz
	bet fieldmap/B0_mag_fMRI.nii.gz fieldmap/B0_mag_fMRI_brain.nii.gz -R

# Freesurfer stuff removed to a seperate file

memprage/T1_brain_mask.nii.gz: xfm_dir/fs_to_T1.mat $(SUBJECTS_DIR)/$(SUBJECT)/mri/brainmask.nii.gz
	flirt -ref memprage/T1.nii.gz -in $(word 2,$^) -init $(word 1,$^) -applyxfm -out $@ ;\
	fslmaths $@ -bin $@

memprage/T1_brain.nii.gz: memprage/T1.nii.gz memprage/T1_brain_mask.nii.gz
	fslmaths $(word 1,$^) -mul  $(word 2,$^) $@

QA/images/T1_brain.gif: memprage/T1.nii.gz memprage/T1_brain_mask.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 memprage/T1.nii.gz -a $(word 2,$^) 1 10 memprage/rendered_T1_brain.nii.gz ;\
	$(SCRIPTpath)/slices memprage/rendered_T1_brain.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm memprage/rendered_T1_brain.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

#Do segmentation with fast (only for later use of epi-reg) and make some pretty QA images of the segmentations

memprage/T1_brain_wmseg.nii.gz: memprage/T1_brain.nii.gz
	rm -f $@ ;\
	mkdir -p memprage/fast_segmentation ;\
	fast -n 3 -t 1 -o memprage/fast_segmentation/T1_brain $(word 1,$^) ;\
	fslmaths memprage/fast_segmentation/T1_brain_pve_2 -thr 0.5 -bin $@ ;\

QA/images/csf.gif: memprage/T1_brain.nii.gz memprage/T1_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a memprage/fast_segmentation/T1_brain_pve_0 1 10 QA/rendered_csf.nii.gz ;\
	$(SCRIPTpath)/slices QA/rendered_csf.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_csf.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

QA/images/gm.gif: memprage/T1_brain.nii.gz memprage/T1_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a memprage/fast_segmentation/T1_brain_pve_1 1 10 QA/rendered_gm.nii.gz ;\
	$(SCRIPTpath)/slices QA/rendered_gm.nii.gz -o `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_gm.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

QA/images/wm.gif: memprage/T1_brain.nii.gz memprage/T1_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a memprage/fast_segmentation/T1_brain_pve_2 1 10 QA/rendered_wm.nii.gz ;\
	$(SCRIPTpath)/slices QA/rendered_wm.nii.gz -o `dirname $@`/`basename $@ .gif`.png
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_wm.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

QA/images/wm_seg.gif: memprage/T1_brain.nii.gz memprage/T1_brain_wmseg.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/overlay 1 1 $(word 1,$^) -a $(word 2,$^) 1 10 QA/rendered_wm_seg.nii.gz ;\
	$(SCRIPTpath)/slices QA/rendered_wm_seg.nii.gz -o `dirname $@`/`basename $@ .gif`.png
	convert `dirname $@`/`basename $@ .gif`.png -resize 500 $@ ;\
	rm QA/rendered_wm_seg.nii.gz ;\
	rm `dirname $@`/`basename $@ .gif`.png

# Create Registration Matrices between T1 and Custom Subjects Template (CT) and MNI (2mm FSL) spaces

StructRegistrations: xfm_dir/T1_to_fs.mat xfm_dir/T1_to_CT_deformed.nii.gz QA/images/T1_to_CT_deformed.gif xfm_dir/T1_to_mni_deformed.nii.gz QA/images/T1_to_mni_deformed.gif QA/

# Inverse of freesurfer registration matrix

xfm_dir/T1_to_fs.mat: xfm_dir/fs_to_T1.mat
	mkdir -p xfm_dir ;\
	convert_xfm -omat $@ -inverse xfm_dir/fs_to_T1.mat

#Registration matrix for T1 MPRAGE to Freesurfer space

xfm_dir/fs_to_T1.mat: $(SUBJECTS_DIR)/$(SUBJECT)/mri/aparc+aseg.mgz
	mkdir -p xfm_dir ;\
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	tkregister2 --mov $(SUBJECTS_DIR)/$(SUBJECT)/mri/orig.mgz --targ memprage/T1.nii.gz --noedit --regheader --reg xfm_dir/fs_to_T1.dat --fslregout xfm_dir/fs_to_T1_init.mat ;\
	mri_convert $(SUBJECTS_DIR)/$(SUBJECT)/mri/orig.mgz $(SUBJECTS_DIR)/$(SUBJECT)/mri/orig.nii.gz ;\
	flirt -ref $(PROJECT_DIR)/subjects/$(SUBJECT)/session1/memprage/T1.nii.gz -in $(SUBJECTS_DIR)/$(SUBJECT)/mri/orig.nii.gz -init xfm_dir/fs_to_T1_init.mat -omat $@

# Ants registrations from T1 to Custom Subjects Template (CT) and from T1 to 2 mm MNI (through CT intermediate). We do these from the T1 in fsl space

xfm_dir/T1_to_CT_deformed.nii.gz: memprage/T1_brain.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz
	mkdir -p xfm_dir ;\
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)antsIntroduction.sh -d 3 -i $(word 1,$^) -m 30x90x20 -o $(SubjDIR)/xfm_dir/T1_to_CT_ -s CC -r $(word 2,$^) -t GR

QA/images/T1_to_CT_deformed.gif: xfm_dir/T1_to_CT_deformed.nii.gz $(STANDARD_DIR)/Subject-specific_template.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/slicer $(word 1,$^) $(word 2,$^) -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ;\
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png QA/images/intermediate1.png ;\
	$(FSLpath)/bin/slicer $(word 2,$^) $(word 1,$^) -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ;\
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png QA/images/intermediate2.png ;\
	pngappend QA/images/intermediate1.png - QA/images/intermediate2.png `dirname $@`/`basename $@ .gif`.png ;\
	rm -f sl?.png QA/images/intermediate?.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 1500 $@ ;\
	rm `dirname $@`/`basename $@ .gif`.png

xfm_dir/T1_to_mni_deformed.nii.gz: memprage/T1_brain.nii.gz $(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz $(STANDARD_DIR)/CT_to_mni_Warp.nii.gz $(STANDARD_DIR)/CT_to_mni_Affine.txt xfm_dir/T1_to_CT_deformed.nii.gz
	export ANTSPATH=$(ANTSpath) ;\
	$(ANTSpath)WarpImageMultiTransform 3 $(word 1,$^) $@ -R $(word 2,$^) $(word 3,$^) $(word 4,$^) xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Warp.nii.gz xfm_dir/`basename $(word 5,$^) _deformed.nii.gz`_Affine.txt	

QA/images/T1_to_mni_deformed.gif: xfm_dir/T1_to_mni_deformed.nii.gz $(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz
	mkdir -p QA/images ;\
	$(FSLpath)/bin/slicer $(word 1,$^) $(word 2,$^) -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ;\
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png QA/images/intermediate1.png ;\
	$(FSLpath)/bin/slicer $(word 2,$^) $(word 1,$^) -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ;\
	pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png QA/images/intermediate2.png ;\
	pngappend QA/images/intermediate1.png - QA/images/intermediate2.png `dirname $@`/`basename $@ .gif`.png ;\
	rm -f sl?.png QA/images/intermediate?.png ;\
	convert `dirname $@`/`basename $@ .gif`.png -resize 1500 $@ ;\
	rm `dirname $@`/`basename $@ .gif`.png

#################################
# Movies of raw functional data #
#################################

RawMovies: QA/images/rest_e001_x_animation.gif QA/images/rest_e002_x_animation.gif QA/images/rest_e003_x_animation.gif

# These are split up because the naming conflicts with other files like
# QA/images/rest_e00213_medn_x_animation.gif etc...

QA/images/rest_e001_x_animation.gif: rest/rest_e001.nii.gz
	$(SCRIPTpath)/functional_movies $(word 1,$^) `dirname $@` 3

QA/images/rest_e002_x_animation.gif: rest/rest_e002.nii.gz
	$(SCRIPTpath)/functional_movies $(word 1,$^) `dirname $@` 3

QA/images/rest_e003_x_animation.gif: rest/rest_e003.nii.gz
	$(SCRIPTpath)/functional_movies $(word 1,$^) `dirname $@` 3

# Movies of raw breathhold data

BH_RawMovies: QA/images/breathhold/BREATHHOLD-e001_x_animation.gif QA/images/breathhold/BREATHHOLD-e002_x_animation.gif QA/images/breathhold/BREATHHOLD-e003_x_animation.gif

# These don't conflict with anything
QA/images/breathhold/%_x_animation.gif: breathhold/%.nii.gz
	mkdir -p QA/images/breathhold/ ;\
	$(SCRIPTpath)/functional_movies $< `dirname $@` 3

#########################################
# Extract WM Hyperintensities with FLEX #
#########################################

Flex: flair/Flair.nii.gz flair/Flair_RO.nii.gz flair/Flair_brain.hdr flair/Flair_brain_flwmt_lesions.hdr flair/Flair_wmh_mask.nii.gz QA/images/checkflex.gif flair/wmhstats.csv flair/wmh_to_func.nii.gz

flair/Flair_RO.nii.gz: flair/Flair.nii.gz
	fslreorient2std $< $@

#produce bias-field corrected image that is segmented 
flair/Flair_restore.nii.gz: flair/Flair_RO.nii.gz 
	fast -B -o flair/Flair -t 2 $<

flair/Flair_brain.hdr: flair/Flair_restore.nii.gz
	bet $< `basename $@ .hdr`.nii.gz -R ;\
	fslchfiletype ANALYZE `basename $@ .hdr`.nii.gz $@ ;\
	rm `basename $@ .hdr`.nii.gz

flair/Flair_brain_flwmt_lesions.hdr: flair/Flair_brain.hdr 
	@echo "Flex processing " $(word 1,$^) ;\
	export PATH=$(FLEXPATH):$(SBBINDIR):$$PATH ;\
	export SBBINDIR=$(SBBINDIR) ;\
	$(FLEXPATH)/sb_flex -fl $(word 1,$^) 

flair/Flair_wmh_mask.nii.gz: flair/Flair_brain_flwmt_lesions.hdr
	fslmaths $< -uthr 1 $@

# check flex output - this is a quickie image for checking skull stripping
# and whether the hyperintensities seem at least to be in the right places
QA/images/checkflex.gif: flair/Flair_brain.hdr flair/Flair_wmh_mask.nii.gz 
	slicer flair/Flair_brain.hdr flair/Flair_wmh_mask.nii.gz -l "orange" -a `dirname $@`/`basename $@ .gif`.png ;\
	convert `dirname $@`/`basename $@ .gif`.png $@

flair/wmhstats.csv: flair/Flair_brain_flwmt_lesions.hdr flair/Flair_brain.hdr
	@echo Writing wmhstats.csv 
	tot=`fslstats $(word 2,$^) -V | awk '{print $$2}'`; \
	wmh=`fslstats $(word 1,$^) -u 2 -V | awk '{print $$2}'` ; \
	per=`echo $$wmh $$tot | awk '{print ($$1/$$2)*100}'` ; \
	echo $(SUBJECT)","  $$wmh", " $$per > $@ 

flair/wmh_to_func.nii.gz: flair/Flair_brain_flwmt_lesions.hdr flair/Flair_brain_flwmt_lesions.img $(REST) xfm_dir/ANTS_t1_to_rest.txt xfm_dir/T1_to_mni_InverseWarp.nii.gz 
	fslchfiletype NIFTI_GZ $(word 1, $^) $(word 2, $^) ;\
	WarpImageMultiTransform 3 flair/Flair_brain_flwmt_lesions.nii.gz $@ -R $(REST) xfm_dir/ANTS_t1_to_rest.txt -i xfm_dir/T1_to_mni_Affine.txt xfm_dir/T1_to_mni_InverseWarp.nii.gz ;\
	fslmaths $@ -uthr 1 -bin $@


