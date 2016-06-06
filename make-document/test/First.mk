#! where the FSL scripts are stored
FSLDIR=/usr/share/fsl/5.0/

.PHONY: First
.SECONDARY: first/T1_brain_all_fast_firstseg.nii.gz

#? create the hippocampal segmentation and the QA html page
First: first/l-hippocampus-vol first/r-hippocampus-vol first/slicesdir/index.html

#> segmentation, includes l, r hippocampus
first/T1_brain_all_fast_firstseg.nii.gz: $(T1)
	run_first_all -s L_Hipp,R_Hipp -i $< -o first/T1_brain

#> size of left hippocampus (voxels, volume) non-zero
first/l-hippocampus-vol: first/T1_brain_all_fast_firstseg.nii.gz
	fslstats $< -l 16.5 -u 17.5 -V > $@

#> size of right hippocampus (voxels, volume) non-zero
first/r-hippocampus-vol: first/T1_brain_all_fast_firstseg.nii.gz
	fslstats $< -l 52.5 -u 53.5 -V > $@

#> QA for segmentation
#> testing mutli-line comments
first/slicesdir/index.html: $(T1) first/T1_brain_all_fast_firstseg.nii.gz
	first_roi_slicesdir $^ ;\
	cp -r slicesdir first/ ;\
	rm -rf slicesdir