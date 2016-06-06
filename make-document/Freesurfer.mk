# UDALL freesurfer makefile

WAVE=1
#! session number
PROJHOME=/mnt/panuc/udallp2/subjects/session$(WAVE)
subjs=$(notdir $(wildcard $(PROJHOME)/??????)) #! select the subject directories (of length 6)
SUBJECTS:=$(subjs:%=%.s1) #! append .s1 to the subject names (that's how they show up in the freesurfer directory
#SUBJECTS=107000.s1

# Set open MP number of threads to be 1, so that we can parallize using make.
export OMP_NUM_THREADS=1

# for Freesurfer (running version 5.3)
export SUBJECTS_DIR=/mnt/panuc/udallp2/freesurfer
export QA_TOOLS=/usr/local/freesurfer/QAtools_v1.1

# be really careful with paths and variables - two versions of freesurfer installed
export FSBIN=/usr/local/freesurfer/stable5_3/bin
export FREESURFER_SETUP=/usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh
export RECON_ALL=/usr/local/freesurfer/stable5_3/bin/recon-all
export TKMEDIT=/usr/local/freesurfer/stable5_3/bin/tkmedit

define usage
   @echo Usage:
   @echo "make, or make interactive	Makes interactive targets"
   @echo "make noninteractive		Makes noninteractive targets"
   echo 
   @echo Noninteractive targets:
   @echo "make setup			Copies source files to this directory"
   @echo "make freesurfer		Runs freesurfer"
   @echo
   @echo Other useful targets:
   @echo "make clean			Remove everything! Be careful!"
   @echo "make mostlyclean		Remove everything but the good bits."
   @echo "make help			Print this message."
   @echo
   @echo Variables:
   @echo "RECON_FLAGS			Set to flags to recon-all, by default"
   @echo "WAVE				1, 2 or 3 to select subjects, for setup"
endef

export SHELL=/bin/bash

.PHONY: QA clean output noninteractive brainmasks 

noninteractive: setup freesurfer 

all: noninteractive

output=$(SUBJECTS:%=%/mri/aparc+aseg.mgz) 

freesurfer: $(output)

brainmasks: $(SUBJECTS:%=%/mri/brainmask.nii.gz)

qcache: $(SUBJECTS:%=%/surf/rh.thickness.fwhm10.fsaverage.mgh)

### Freesurfer ###

#> aparc+aseg.mgz is one of the final freesurfer files, so we use it to check for completion
%/mri/aparc+aseg.mgz: $(PROJHOME)/
	rm -rf $(dirname $@)/IsRunning.* ;\
	subj=$(basename $* .s$(WAVE)) ;\
	source $${FREESURFER_SETUP} ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	$(RECON_ALL) -subjid $* -all ;\
	$(RECON_ALL) -s $* -T2 $(PROJHOME)/$${subj}/flair/Flair.nii.gz -T2pial

#> I don't know what this one is for
%/surf/rh.thickness.fwhm10.fsaverage.mgh: %
	rm -rf $(dirname $@)/IsRunning.* ;\
	source $$FREESURFER_SETUP ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	$(RECON_ALL) -s $* -qcache


#> Use Registration matrix to create skull stripped brain (memprage/T1_brain) from FreeSurfer's skull strip in fsl T1 space
%/mri/brainmask.nii.gz: $(SUBJECTS_DIR)/%/mri/aparc+aseg.mgz
	source $$FREESURFER_SETUP ;\
	$(FSBIN)/mri_convert $(SUBJECTS_DIR)/$*/mri/brainmask.mgz $@

#> Burn it to the ground
clean:
	echo rm -rf $(inputdirs)


#? make all the subject directories
setup: $(SUBJECTS)

#> this matches the setup recipie 
%.s1:  $(PROJHOME)/%/mprage/T1.nii.gz 
	mkdir -p $@/mri/orig ;\
	cp $^ $@/mri/orig ;\
	cd $@/mri/orig ;\
	$(FSBIN)/mri_convert T1.nii.gz 001.mgz

help:
	$(usage)

### QA ###

qafiles=$(SUBJECTS:%=QA/%)

QA: $(qafiles)

QA/%: %
	source $$FREESURFER_SETUP ;\
	$(QA_TOOLS)/recon_checker -s $*

test:
	@echo $(SUBJECTS)