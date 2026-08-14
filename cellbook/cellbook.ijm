//@File(label = "Red channel input directory", style = "directory") inputRedImg
//@File(label = "Green channel input directory", style = "directory") inputGreenImg
//@File(label = "Segmented red channel input directory", style = "directory") inputRedSeg
//@File(label = "Segmented green channel input directory", style = "directory") inputGreenSeg
//@File(label = "Output directory", style = "directory") outputDir
//@String (label = "File suffix", value = ".tif") fileSuffix

// cellbook.ijm
// ImageJ/Fiji script to make gallery of fluor and segmented images for inspection

// Theresa Swayne, 2026
//  -------- Suggested text for acknowledgement -----------
//   "These studies used the Confocal and Specialized Microscopy Shared Resource 
//   of the Herbert Irving Comprehensive Cancer Center at Columbia University, 
//   funded in part through the NIH/NCI Cancer Center Support Grant P30CA013696."

// NOTES:  If any files in the red image folder do not have matches, they will be skipped
//  All files must be in the same directory level -- there is no recursive search

// ---- Setup ----

while (nImages>0) { // clean up open images
	selectImage(nImages);
	close();
}
print("\\Clear"); // clear Log window

startTime = getTime(); // keep track of time

run("Bio-Formats Macro Extensions"); // support native microscope files

setBatchMode(true); // faster performance

// ---- Run ----

print("Starting");

// Call the processFolder function, including the parameters collected at the beginning of the script

n = processFolder(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, fileSuffix);

// Clean up images and get out of batch mode

while (nImages > 0) { // clean up open images
	selectImage(nImages);
	close(); 
}
setBatchMode(false);

time = getTime();
elapsedTime = (time - startTime)/1000;
print("Finished",n,"images in ", elapsedTime , " sec");


// ---- Functions ----

function processFolder(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, fileSuffix) {

	// this function searches for files in the first input folder that match the criteria and sends them to the processFile function

	filenum = 0;
	print("Processing red image input folder", inputRedImg);
	// scan folder tree to find files with correct suffix
	list = getFileList(inputRedImg);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], fileSuffix)) { // we will process this image
			filenum = filenum + 1;
			processFile(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, list[i], filenum); // passes the filename and parameters to the processFile function
		}
	}
	return filenum;
} // end of processFolder function


function processFile(inputRedImg, inputGreenImg, inputRedSeg, inputGreenSeg, outputDir, fileName, fileNumber) {
	
	// this function processes a single image
	
	// Set up parameters
	// What differentiates red and green file names?
	
	redChan = "c4";
	greenChan = "c5";
	
	redPath = inputRedImg + File.separator + fileName;
	print("Processing file",fileNumber," at path" ,redPath);	

	// determine the name of the file without extension
	dotIndex = lastIndexOf(fileName, ".");
	basename = substring(fileName, 0, dotIndex); 
	extension = substring(fileName, dotIndex);
	nameLength = lengthOf(basename);
	origName = substring(basename, 0, nameLength-11); // remove "cX-resliced"
	print("Red image file basename is",basename,"and the original image name is",origName);
	
	// open the red image file
	run("Bio-Formats", "open=&redPath");
	
	// open green fluor
	// the name is going to be the original name with the other channel number and "resliced"

	greenfileName = origName + greenChan + "_resliced.tif";
	greenPath = inputGreenImg + File.separator + greenfileName;
	print("Opening green image at",greenPath);
	if (File.exists(greenPath)) {
		run("Bio-Formats", "open=&greenPath");
	}
	else {
		print("No matching green image at",greenPath);
		return; // skip to next red file
	}


	
	// project and autocontrast (alt: reset min/max
//	run("Z Project...", "projection=[Max Intensity]");
//	selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced.tif");
//	run("Enhance Contrast", "saturated=0.35");
//	resetMinAndMax;
//	
//	// open red fluor
//	open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 cropped images/trial 3/trial 3 isotropic Erg C4/CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced.tif");
//	
//	// project and autocontrast (or reset min/max)
//	run("Z Project...", "projection=[Max Intensity]");
//	selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced.tif");
//	run("Enhance Contrast", "saturated=0.35");
//	resetMinAndMax;
//	
//	// make RG merge
//	run("Merge Channels...", "c1=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced.tif c2=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced.tif create keep");
//	selectImage("Composite");
//	run("Stack to RGB");
//	saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/RG merge.tif");
//	
//	// open green seg and project
//	open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 trial 3 Nup seg/CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced_seg.tif");
//	run("Z Project...", "projection=[Max Intensity]");
//	
//	// convert to ROIs in the manager
//	run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
//	// alt run("Label image to ROIs", "rm=[RoiManager[size=11, visible=true]]");
//	roiManager("Show All");
//	
//	// convert to an RGB overlay
//	run("Flatten");
//	saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/G outlines.tif");
//	
//	// open red seg and project
//	open("/Volumes/CSMSR_Pon1/Pon projects 1/Cue5/2026-07 trial 3 Erg seg/CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced_seg.tif");
//	run("Z Project...", "projection=[Max Intensity]");
//	
//	// convert to ROIs in the manager
//	run("Label Map to ROIs", "connectivity=C4 vertex_location=Corners name_pattern=r%03d");
//	roiManager("Show All");
//	
//	// convert to an RGB overlay
//	run("Flatten");
//	saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/R outlines.tif");
//	
//	// colorize and merge the seg proj
//	selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced_seg.tif");
//	run("Green"); // might not be nec if the merge works as advertised
//	selectImage("MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced_seg.tif");
//	run("Red");
//	
//	run("Merge Channels...", "c1=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c4_resliced_seg.tif c2=MAX_CTY132-CON-s1-016.nd2-mac_roi_02-c5_resliced_seg.tif create keep");
//	run("Stack to RGB");
//	saveAs("Tiff", "/Users/tcs6/Desktop/cellbook/seg merge.tif");
	

	// save the output
	//outputName = basename + "_processed.tif";
	//saveAs("tiff", outputFolder + File.separator + outputName);
	//close();
	
	// clean up
	while (nImages > 0) { // clean up open images
		selectImage(nImages);
		close(); 
	}
} // end of processFile function

