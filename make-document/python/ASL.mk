.PHONY: PCASL-all PCASL PCASL-QA

T1=$(SubjDIR)/mprage/T1_brain.nii.gz #! Subject-specific T1 to register to

#? Make both the pcasl registrations and QA images
PCASL-all: PCASL PCASL-QA


#? Make the pcasl registrations (fnirt and ANTs)
PCASL: pcasl/PCASL_M0_vol0_to_T1_fnirt.nii.gz pcasl/PCASL_M0_avg_to_T1_fnirt.nii.gz pcasl/PCASL_M0_vol0_to_T1_ANTs.nii.gz

#> Motion correct using mcflirt
pcasl/PCASL_M0_mcf.nii.gz: pcasl/PCASL_M0.nii.gz
	mcflirt -in $< -out $@

#> Extract a binarized brainmask
pcasl/PCASL_M0_brainmask.nii.gz: pcasl/PCASL_M0_mcf.nii.gz
	bet $< $@ -R ;\
	fslmaths $@ -bin $@ 

#> Apply the brainmask to the 4d nifti
pcasl/PCASL_M0_brain.nii.gz: pcasl/PCASL_M0_mcf.nii.gz pcasl/PCASL_M0_brainmask.nii.gz
	fslmaths $(word 1,$^) -mas $(word 2,$^) $@

#> The first TR of the motion-corrected, skull-stripped file
pcasl/PCASL_M0_brain_vol0.nii.gz: pcasl/PCASL_M0_brain.nii.gz
	fslroi $< $@ 0 1

#> The average image of the motion-corrected, skull-stripped file.
pcasl/PCASL_M0_brain_avg.nii.gz: pcasl/PCASL_M0_brain.nii.gz
	fslmaths $< -Tmean $@

#> Register M0 to T1 using fnirt
pcasl/PCASL_M0_%_to_T1_fnirt.nii.gz: pcasl/PCASL_M0_brain_%.nii.gz $(T1)
	fnirt --ref=$(word 2,$^) --in=$(word 1,$^) --iout=$@

#> Register M0 to T1 using ANTs
pcasl/PCASL_M0_%_to_T1_ANTs.nii.gz: pcasl/PCASL_M0_brain_%.nii.gz $(T1)
	$(ANTSpath)/antsRegistrationSyN.sh -d 3 -f $(word 2,$^) -m $(word 1,$^) -o $(subst ANTs.nii.gz,,$@) ;\
	cp pcasl/PCASL/M0_$*_to_T1_Warped.nii.gz $@


#? Make the pcasl QA images
PCASL-QA: pcasl/QA/slices_vol0.gif pcasl/QA/slices_avg.gif pcasl/QA/overlay_vol0_to_T1_ANTs.gif pcasl/QA/overlay_vol0_to_T1_fnirt.gif pcasl/QA/overlay_avg_to_T1_fnirt.gif # pcasl/QA/overlay_avg_to_T1_ANTs.gif


pcasl/QA/slices_%.gif: pcasl/PCASL_M0_brain_%.nii.gz
	mkdir -p pcasl/QA ;\
	$(BIN)/slices $< -o $@ ;\
	convert $@ -resize 1000 $@ 

pcasl/QA/overlay_%.gif: pcasl/PCASL_M0_%.nii.gz $(T1)
	mkdir -p pcasl/QA ;\
	name=$(subst .gif,.png,$@) ;\
	$(BIN)/sliceappend.sh -1  $(word 1,$^) -2 $(word 2,$^) -s -o $${name}.png ;\
	convert $${name}.png -resize 2000 $@ ;\
	rm $${name}.png