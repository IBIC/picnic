# defines for all things 
SHELL=/bin/bash
PROJECT_DIR=/mnt/adrc/ADRC/
BIN=/mnt/adrc/ADRC/bin
LIB=/mnt/adrc/ADRC/lib
RScripts=$(BIN)/R
ANTSpath=/usr/local/ANTs-2.1.0-rc3/bin
FSLpath=/usr/share/fsl/5.0
AFNIpath=/usr/lib/afni/bin
MNI2mmBRAIN=$(FSLpath)/data/standard/MNI152_T1_2mm_brain.nii.gz


# This is the location of the Freesurfer directory
# 
SUBJECTS_DIR=$(PROJECT_DIR)/freesurfer

# This path should be good for any makefile that is included from here (and whose targets are called from within the subject directory, through this makefile)
# However, this is mostly to keep python under control. Paths to specific
# neuroimaging packages are defined above and are used throughout the makefiles
# to be sure we get to the correct 
export PATH=/mnt/adrc/ADRC/conda/envs/adrc/bin:/usr/local/ANTs-2.1.0-rc3/bin:/usr/local/freesurfer/stable5_3/bin:/usr/local/freesurfer/stable5_3/fsfast/bin:/usr/local/freesurfer/stable5_3/tktools:/usr/share/fsl/5.0/bin:/usr/local/freesurfer/stable5_3/mni/bin:/usr/sbin:/usr/lib/afni/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/DTIPrepPackage

# Location of custom template - right now we're using ACT-PLUS template
STANDARD_DIR=$(PROJECT_DIR)/Standard

# Set open MP number of threads to be 1, so that we can parallelize using make.
export OMP_NUM_THREADS=1

# Get the current session
SESSION=$(shell pwd|egrep -o 'session[0-9]'|egrep -o '[0-9]')

# get subject id
# This might not work if we have five digit IDs also..
subject=$(shell pwd|egrep -o '[0-9][0-9][0-9][0-9][0-9][0-9]')

#
SubjDIR=$(PROJECT_DIR)/subjects/$(subject)/session$(SESSION)

# include other makefiles that define good targets
include $(PROJECT_DIR)/lib/makefiles/PrepSubject.mk
include $(PROJECT_DIR)/lib/makefiles/PreprocessSubject.mk
include $(PROJECT_DIR)/lib/makefiles/StructuralRegistrations.mk
include $(PROJECT_DIR)/lib/makefiles/QAReports.mk
include $(PROJECT_DIR)/lib/makefiles/Flex.mk


# put your own rules here


test:
	@printf "Testing that we are making $(subject) from session $(SESSION) \n > $(shell pwd)\n"

# rules from other libraries

