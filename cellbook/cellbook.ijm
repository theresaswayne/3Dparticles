// inputs: Red fluor, Green fluor, Red seg, Green seg

// make gallery of fluor and segmented images for inspection

// open green fluor
open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 cropped images/trial 3/trial 3 isotropic Nup C5/CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced.tif");

// project and autocontrast (alt: reset min/max
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced.tif");
run("Enhance Contrast", "saturated=0.35");
resetMinAndMax;

// open red fluor
open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 cropped images/trial 3/trial 3 isotropic Erg C4/CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced.tif");

// project and autocontrast (or reset min/max)
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced.tif");
run("Enhance Contrast", "saturated=0.35");
resetMinAndMax;

// make RG merge
run("Merge Channels...", "c1=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced.tif c2=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced.tif create keep");
selectImage("Composite");
run("Stack to RGB");
saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/RG merge.tif");

// open green seg and project
open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 trial 3 Nup seg/CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced_seg.tif");
run("Z Project...", "projection=[Max Intensity]");

// convert to ROIs in the manager
run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
// alt run("Label image to ROIs", "rm=[RoiManager[size=11, visible=true]]");
roiManager("Show All");

// convert to an RGB overlay
run("Flatten");
saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/G outlines.tif");

// open red seg and project
open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 trial 3 Erg seg/CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced_seg.tif");
run("Z Project...", "projection=[Max Intensity]");

// convert to ROIs in the manager
run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
roiManager("Show All");

// convert to an RGB overlay
run("Flatten");
saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/R outlines.tif");

// colorize and merge the seg proj
selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced_seg.tif");
run("Green"); // might not be nec if the merge works as advertised
selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced_seg.tif");
run("Red");

run("Merge Channels...", "c1=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced_seg.tif c2=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced_seg.tif create keep");
run("Stack to RGB");
saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/seg merge.tif");

