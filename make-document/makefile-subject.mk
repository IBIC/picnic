# defines for all things 

SHELL=/bin/bash
PROJECT_DIR=/mnt/panuc/udallp2
BIN=$(PROJECT_DIR)/bin
LIB=$(PROJECT_DIR)/lib
RScripts=$(BIN)/R
ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin
FSLpath=/usr/share/fsl/5.0
AFNIpath=/usr/lib/afni/bin
MNI2mmBRAIN=$(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz

#! group identifier cat'd from file
GROUP=$(shell cat 0_group)

FREESURFER_SETUP=/usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh

#! all the groups
GROUPS=$(shell cat $(LIB)/makefiles/0_groups)

#! T1 image
T1=mprage/T1.nii.gz

#! The skull-stripped T1
T1_brain=mprage/T1_brain.nii.gz

#! Location of custom template (ACT-PLUS)
STANDARD_DIR=$(PROJECT_DIR)/standard

#! Group average template
PROJECT_STANDARD=$(STANDARD_DIR)/Subject-specific_template.nii.gz

#! This is the location of the Freesurfer directory
SUBJECTS_DIR=$(PROJECT_DIR)/freesurfer

# This path should be good for any makefile that is included from here (and whose targets are called from within the subject directory, through this makefile)
# However, this is mostly to keep python under control. Paths to specific
# neuroimaging packages are defined above and are used throughout the makefiles
# to be sure we get to the correct 
export PATH=/mnt/adrc/ADRC/conda/envs/adrc/bin:/usr/local/ANTs-2.1.0-rc3/bin:/usr/local/freesurfer/stable5_3/bin:/usr/local/freesurfer/stable5_3/fsfast/bin:/usr/local/freesurfer/stable5_3/tktools:/usr/share/fsl/5.0/bin:/usr/local/freesurfer/stable5_3/mni/bin:/usr/sbin:/usr/lib/afni/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/DTIPrepPackage

# Set open MP number of threads to be 1, so that we can parallelize using make.
export OMP_NUM_THREADS=1

SESSION=$(strip $(shell pwd | egrep -o 'session[0-9]' | egrep -o '[0-9]'))#? current session

subject=$(strip $(shell pwd | egrep -o '[0-9][0-9][0-9][0-9][0-9][0-9]'))#? subject ID

ifeq ($(strip $(GROUP)),PATIENT)
PreprocessSubject: axcpt-on axcpt-off rest-on rest-off
else
PreprocessSubject: axcpt-on rest-on
endif

#! subject directory
SubjDIR=$(PROJECT_DIR)/subjects/$(subject)/session$(SESSION)

# put your own rules here

test:
	@printf "Testing that we are making $(subject) from session $(SESSION) \n > $(shell pwd)\n"

test-%:
	@echo $($*)

# rules from other libraries

# include other makefiles that define good targets
include $(LIB)/makefiles/PrepSubject.mk
include $(LIB)/makefiles/StructuralRegistrations.mk
include $(LIB)/makefiles/First.mk
#include $(PROJECT_DIR)/lib/makefiles/QAReports.mk
#include $(PROJECT_DIR)/lib/makefiles/Flex.mk
#include $(PROJECT_DIR)/lib/makefiles/ASL.mk


include $(LIB)/makefiles/dependent-makefiles/rest-on.mk
include $(LIB)/makefiles/dependent-makefiles/rest-off.mk
include $(LIB)/makefiles/dependent-makefiles/axcpt-on.mk
include $(LIB)/makefiles/dependent-makefiles/axcpt-off.mk
