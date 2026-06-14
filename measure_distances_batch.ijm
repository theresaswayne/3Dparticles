//@ String(label = "Object A name", value = "Nup") objAName
//@ String(label = "Object B name", value = "Erg") objBName
//@ File(label = "Object A label image folder:", style = "directory") objAFolder
//@ File(label = "Object B label image folder:", style = "directory") objBFolder
//@ File(label = "Output folder:", style = "directory") outDir
//@ String(label = "File suffix", value = ".tif") suffix
//@ Double(label = "Distance criterion (µm):", value = 0.9) dist

// Take 2 label image stacks representing particles in 2 channels
// Use DiAnA to measure minimum edge-edge distances 
//    from objects in channel 1 to objects in channel 2

// Limitations: Assumes names in format: aCTY132-6hrDTT-013_roi_1_seg.tif 

// ---- Setup ----

// clean up images and memory
while (nImages>0) { // clean up open images
	selectImage(nImages);
	close();
	}
print("\\Clear"); // clear Log window
run("Collect Garbage"); // clear memory

// close one or more results windows
while (isOpen("Results")) {
     selectWindow("Results"); 
     run("Close" );
}

// options: important to NOT show as IJ results table beause it conflicts with the other table
run("3D Manager Options", "volume feret centroid_(pix) centroid_(unit) distance_to_surface objects radial_distance distance_between_centers=0 distance_max_contact=0 drawing=Contour use_0");

// get time
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
startTime = getTime();
timeString = "" + year + "-" + month + "-" + dayOfMonth + "-" + hour + "-" + minute; // must start with an empty string
summaryName = timeString + "_results.csv";

// dataset counter
n = 0;


// ---- Run ----

processFolder(objAFolder, objBFolder, outDir, suffix, objAName, objBName, dist); 
showMessage("Finished.");
run("Clear Results");
print("Finished in",(1000*(getTime() - startTime)),"seconds"); 

// save Log
selectWindow("Log");
saveAs("text", outDir + File.separator + timeString + "_Log.txt");

// ---- Function for processing a folder

function processFolder(inputObjA, inputObjB, outputdir, suffix, objAName, objBName, distance) {
	{
	list = getFileList(inputObjA);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], suffix)) {
	       	processImage(inputObjA, inputObjB, list[i], outputdir, objAName, objBName, distance);
			} 
		}
	} // end processFolder function


// ------- Function for processing an individual file

function processImage(objAFolder, objBFolder, name, outDir, objAName, objBName, dist) 
	{
	// ---- Open image from Object A folder and get name, info
	
	print("Processing image", name);

	while (nImages>0) { // clean up open images
		selectImage(nImages);
		close();
		}
	
	// open the channel 1 file and get its name
	open(objAFolder + File.separator + name);
	objATitle = getTitle();
	
	// determine the name of the file without extension
	dotIndex = lastIndexOf(objATitle, ".");
	objABasename = substring(objATitle, 0, dotIndex); // format expected: aCTY132-6hrDTT-013_roi_1_seg.tif
	imageBasename = substring(objABasename, 0, dotIndex-4); // remove "_seg"
	selectWindow(objATitle);
	rename("ObjA");
	
	// determine the name of the channel 2 file
	objBFile = imageBasename + "_seg.tif"; // ok it's actually the same name but we're preparing for other situations here
	
	// open the channel 2 file, if it exists, and get its name
	if (File.exists(objBFolder + File.separator + objBFile)) {
		open(objBFolder + File.separator + objBFile);
		objBTitle = getTitle();
		dotIndex = lastIndexOf(objBTitle, ".");
		objBBasename = substring(objBTitle, 0, dotIndex);
		selectWindow(objBTitle);
		rename("ObjB");
	}
	else {
		print("No matching", objBName,"image",objBFile, "for",objATitle);
		return; // to next image in folder loop
	}
	
	// ---- 3D ROI Manager Setup ----
	
	// initialize 3D functions
	run("3D Manager");
	Ext.Manager3D_Reset();
	//run("3D Manager Options", "volume feret centroid_(pix) centroid_(unit) distance_to_surface objects radial_distance distance_between_centers=0 distance_max_contact=0 drawing=Contour use_0");
	
	// check for absence of objects in each channel
	
	selectWindow("ObjA");
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	if (max == 0) {
		print("No objects in",objAName," image");
		objAEmpty = true;
	}
	else {
		objAEmpty = false;
	}
	
	selectWindow("ObjB");
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	if (max == 0) {
		print("No objects in",objBName,"image");
		objBEmpty = true;
	}
	else {
		objBEmpty = false;
	}
	
	// Add Ch1 objects to the 3D Mgr with appropriate names
	
	if (!objAEmpty) {
		// add ObjA objects and rename
		selectWindow("ObjA");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Rename(objAName);
		Ext.Manager3D_DeselectAll();
		Ext.Manager3D_Count(objACount); // number of objects A
	}
	else {
		objACount = 0;
	}
	
	// Add Ch2 objects to the 3D Mgr with appropriate names
	
	if (!objBEmpty) {
		selectWindow("ObjB");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(allCount); // total number of objects
		Ext.Manager3D_SelectFor(objACount, allCount, 1); // select all the objects B
		Ext.Manager3D_Rename(objBName);
		Ext.Manager3D_DeselectAll();
		objBCount = allCount - objACount;
	}
	else {
		objBCount = 0;
	}
	
	// ---- Measure distances ----

	output3DMgrName = timeString+"_"+imageBasename + "_3dMgrResults.csv";
	outputDianaName = timeString+"_"+imageBasename+"_DianaResults.csv";

	// only if there are objects in both channels
	if (!objAEmpty && !objBEmpty) {
		
		// Using 3D Mgr
		run("3D Distances", "image_a=ObjA image_b=ObjB distance=DistBorderBorderUnit distance_maximum="+dist);
		saveAs("Results", outDir + File.separator + output3DMgrName);
	
		// Using DiAnA
		// generate distance results (center and edge) for all objects, 1 column per measurement type
		run("DiAna_Analyse", "img1=ObjA img2=ObjB lab1=ObjA lab2=ObjB adja kclosest="+objBCount);
		saveAs("Results", outDir+File.separator+outputDianaName);
		
		}
	else {
		print("No objects in one or both images. Distance not measured.");
	}
	
	// clean up
	while (nImages>0) { // clean up open images
		selectImage(nImages);
		close();
		}
	
	Ext.Manager3D_Reset();
	
	// close one or more results windows
	while (isOpen("Results")) {
	     selectWindow("Results"); 
	     run("Close" );
	}

	while (isOpen(outputDianaName)) {
	 	selectWindow(outputDianaName); 
	 	run("Close" );
	}

	while (isOpen(output3DMgrName)) {
	 	selectWindow(output3DMgrName); 
	 	run("Close" );
	run("Collect Garbage");
	}
} // end processImage function


// CDF with mask
//run("DiAna_Analyse", "img1=[erg 1.tif] img2=[nup 1.tif] lab1=[erg 1.tif] lab2=[nup 1.tif] shuffle mask=MASK_CloseLabels");

// cdf without mask (Diana sometimes crashes 2nd time you run it -or messes up the object pop so erg has only 1 )
//run("DiAna_Analyse", "img1=[erg 1.tif] img2=[nup 1.tif] lab1=[erg 1.tif] lab2=[nup 1.tif] shuffle");
