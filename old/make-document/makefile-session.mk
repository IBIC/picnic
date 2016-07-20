# Top level makefile
# make all will recursively make specified targets in each subject directory.

# A link to this makefile should reside in $(PROJECT_DIR)/subjects/sessionN directory.
# This sessionN directory is also assumed to contain links to multiple $(PROJECT_DIR)/subjects/SubjectID/sessionN
# directories, so that the "SUBJECTS=$(wildcard..." statement will resolve to a list of sessionN directories from each subject.
# Each of these sessionN directories will contain a link to $(PROJECT_DIR)/subjects/makefile_subject, which is called
# recursively from here to make specified targets in each SubjectID/sessionN.

# In this context, "specified targets" means targets passed to make from the command line using the "TARGET=..." argument



SUBJECTS=$(wildcard 1?????)

.PHONY: all $(SUBJECTS)

all: $(SUBJECTS)

$(SUBJECTS):
	$(MAKE) --directory=$@ $(TARGET)

