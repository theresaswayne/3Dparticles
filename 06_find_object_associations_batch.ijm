//@ String(label = "Object 1 name", value = "Nup") obj1Name
//@ String(label = "Object 2 name", value = "Erg") obj2Name
//@ File(label = "Object 1 label image folder:", style = "directory") obj1Folder
//@ File(label = "Object 2 label image folder:", style = "directory") obj2Folder
//@ File(label = "Output folder:", style = "directory") outDir
//@ String(label = "File suffix", value = ".tif") suffix
//@ Double(label = "Distance criterion (µm):", value = 0.9) dist
// find_object_associations_batch.ijm
// Detect and visualize 3D closest objects within a specified distance
// input: 2 label image stacks; distance criterion
// For each object in the first input stack, the closest object (center-center) is found using 3D Suite
// If the center-center distance is <= the criterion, the two objects are counted as associated
// output: 2 label image stacks containing all associated objects; 
//		3D Manager size/position measurements for all objects and associated objects;
//		table giving IDs of closest associated Erg object for each Nup object, or 0 if no associated object

// Limitation: Erg count of associations could be inaccurate if the same LD is associated with 2 Nup aggregates


// setup general
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

// dataset counter
n = 0;

// collect association counts in a table with a time/date stamp
headerString = "ImageName,Total"+obj1Name+",Total"+obj2Name+",Associated"+obj1Name;
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
startTime = getTime();
timeString = "" + year + "-" + month + "-" + dayOfMonth + "-" + hour + "-" + minute; // have to start with empty string
summaryName = timeString + "_results.csv";
summaryFile = outDir + File.separator + summaryName;
if (File.exists(summaryFile)==false) { // start the file with headers
	File.append(headerString, summaryFile);	
	print("Added headings");
    }


// ---- Commands to run the processing functions

processFolder(obj1Folder, obj2Folder, outDir, suffix, obj1Name, obj2Name, dist); // actually do the analysis
showMessage("Finished.");
run("Clear Results");
print("Finished in",(1000*(getTime() - startTime)),"seconds"); 
//print("Finished");

// save Log
selectWindow("Log");
saveAs("text", outDir + File.separator + "Log.txt");


// ---- Function for processing folders
function processFolder(inputObj1, inputObj2, outputdir, suffix, obj1Name, obj2Name, distance) {
	{
	list = getFileList(inputObj1);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], suffix)) {
	       	processImage(inputObj1, inputObj2, list[i], outputdir, obj1Name, obj2Name, suffix, distance);
			} 
		}
	} // end processFolder function

// ------- Function for processing individual files

function processImage(obj1Folder, obj2Folder, name, outDir, suffix, dist) 
	{
	// ---- Open image and get name, info
	
	print("Processing image", name);

	while (nImages>0) { // clean up open images
		selectImage(nImages);
		close();
		}
	// open datasets
	open(obj1Folder + File.separator + name);
	obj1Title = getTitle();
	// determine the name of the file without extension
	dotIndex = lastIndexOf(obj1Title, ".");
	obj1Basename = substring(obj1Title, 0, dotIndex);
	
	imageBasename = substring(obj1Basename, 0, dotIndex-16); // remove "-c4_resliced_seg.tif"
	obj2File = imageBasename + "-c4_resliced_seg.tif";
	
	if (File.exists(obj2Folder + File.separator + obj2File)) {
		open(obj2Folder + File.separator + obj2File);
		obj2Title = getTitle();
		dotIndex = lastIndexOf(obj2Title, ".");
		obj2Basename = substring(obj2Title, 0, dotIndex);
	}
	else {
		print("No matching", obj2Name,"image",obj2File, "for",obj1Title);
		return; // to next image in folder loop
	}
	
	// initialize 3D functions
	run("3D Manager");
	Ext.Manager3D_Reset();
	//run("3D Manager Options", "volume feret centroid_(pix) centroid_(unit) distance_to_surface objects radial_distance distance_between_centers=0 distance_max_contact=0 drawing=Contour use_0");
	
	// check for absence of objects in each channel
	selectWindow(obj1Title);
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	if (max == 0) {
		print("No objects in Nup image");
		obj1Empty = true;
	}
	else {
		obj1Empty = false;
	}
	
	selectWindow(obj2Title);
	Stack.getStatistics(voxelCount, mean, min, max, stdDev);
	if (max == 0) {
		print("No objects in Erg image");
		obj2Empty = true;
	}
	else {
		obj2Empty = false;
	}
	
	// --- get measurements for all objects
	
	if (!obj1Empty) {
		// add Obj1 objects and rename
		selectWindow(obj1Title);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Rename(obj1Name);
		Ext.Manager3D_DeselectAll();
		Ext.Manager3D_Count(obj1Count); // number of objects 1
	}
	else {
		obj1Count = 0;
	}
	if (!obj2Empty) {
		// add erg objects and rename
		selectWindow(obj2Title);
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(allCount); // total number of objects
		Ext.Manager3D_SelectFor(obj1Count, allCount, 1); // select all the objects2
		Ext.Manager3D_Rename(obj2Name);
		Ext.Manager3D_DeselectAll();
		obj2Count = allCount - obj1Count;
	}
	else {
		obj2Count = 0;
	}
	// save results; M is prepended whether you want it or not
	Ext.Manager3D_Measure(); 
	//Ext.Manager3D_SaveResult("M",subFolder + "allMeas.csv");
	Ext.Manager3D_SaveResult("M", outDir + File.separator + imageBasename + "_allMeas.csv");
	Ext.Manager3D_CloseResult("M");
	
	// find objects meeting association criteria
	if (!obj1Empty && !obj2Empty) {
		run("3D Distances Closest", "image_a="+obj1Basename+" image_b="+obj2Basename+" number=1 distance=DistCenterCenterUnit distance_maximum="+dist);
	
		// save the data
		distTableName = imageBasename + "_assoc.csv";
		saveAs("Results", outDir + File.separator + distTableName);
		
		// read the results
		
		rowCount = getValue("results.count");
		obj1Assocs = newArray();
		obj1NonAssocs = newArray();
		obj2Assocs = newArray();
		
		assocCount = 0;
		nonAssocCount = 0;
		
		if (rowCount > 0) { // if there are any association (behavior varies; may be one row per object or not)
		
			for (i = 0; i < rowCount; i++) { // go through the table
			
				obj1Num = Table.get("LabelObj", i); // each nup object will have a row whether or not it meets criteria
				obj2Num = Table.get("O1", i); // will be 0 if no match
				
				// check if there is a matching Erg object and if so, add to the array of assocs
				if (obj2Num > 0) {
					
					obj1Assocs[assocCount] = obj1Num;
					obj2Assocs[assocCount] = obj2Num;
					assocCount = assocCount + 1;
				}
				else {
					obj1NonAssocs[nonAssocCount] = obj1Num;
					nonAssocCount = nonAssocCount + 1;
				}
			}
			
			print("Associated "+obj1Name+":");
			Array.print(obj1Assocs);
			print("Non-associated "+obj1Name+":");
			Array.print(obj1NonAssocs);
			print("Associated "+obj2Name+":");
			Array.print(obj2Assocs);
		}
		else {
			print("No data in table between",obj1Title, "and",obj2Title);
		}
		print("total associations: ",assocCount);
		
		// collect association counts in a table
		summaryString = imageBasename + "," + obj1Count + "," + obj2Count + "," + assocCount;
		File.append(summaryString, summaryFile);
	
		// generate an image of only the associated Nups
		Ext.Manager3D_Reset();
		selectWindow(obj1Title);
		run("Duplicate...", "title=obj1Assoc duplicate");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Rename(obj1Name);
		Ext.Manager3D_DeselectAll();
		
		Ext.Manager3D_MultiSelect();
		// object numbers start at 1, ROI indices start at 0
		for (j = 0; j < nonAssocCount; j++) {
			obj1Object = obj1NonAssocs[j];
			obj1Index = obj1Object-1;
			//print("Selecting ROI index",nupIndex,",",obj1Name," object number",obj1Object);
			Ext.Manager3D_Select(obj1Index);
		}
		
		Ext.Manager3D_Erase(); // fill with black in the duplicated stack
		Ext.Manager3D_DeselectAll();
		Ext.Manager3D_Measure(); // measure only the assoc objects1
		
		// save the image
		selectWindow("obj1Assoc");
		saveAs("Tiff", outDir  + File.separator + imageBasename + "_"+obj1Name+"_Assoc.tif");
		
		// save the measurements for Nups with associations
		// Ext.Manager3D_SaveResult("M",subFolder + "nupAssocMeas.csv");
		Ext.Manager3D_SaveResult("M",outDir + File.separator + imageBasename + "_"+obj1Name+"_AssocMeas.csv");
		//Ext.Manager3D_SaveResult(outDir + File.separator + imageBasename + "_nupAssocMeas.csv");
		Ext.Manager3D_CloseResult("M");
		
	
		// generate an image of only the associated Object 2s
		Ext.Manager3D_Reset();
		selectWindow(obj2Title);
		run("Duplicate...", "title=obj2Assoc duplicate");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_SelectAll();
		Ext.Manager3D_Rename(obj2Name);
		Ext.Manager3D_DeselectAll();
		
		// make a list of nonassociated Objects 2, that is everything that is not in the obj2Assoc array
		Ext.Manager3D_Count(obj2Count);
		ergNonAssocs = Array.getSequence(obj2Count+1);
		ergNonAssocs = Array.deleteValue(obj2NonAssocs, 0);// start with a list of all erg obj numbs starting with 1
		for (idx = 0; idx < assocCount; idx++) {
			obj2Obj = obj2Assocs[idx];
			obj2NonAssocs = Array.deleteValue(obj2NonAssocs, obj2Obj); // delete the object number from the array and make the array shorter
		}
		obj2NonAssocCount = lengthOf(obj2NonAssocs);
		
		Ext.Manager3D_MultiSelect();
		// object numbers start at 1, ROI indices start at 0
		
		for (k = 0; k < obj2NonAssocCount; k++) { // loop over the non-assoc ergs in the roi mgr
		
			obj2Object = obj2NonAssocs[k];
			obj2Index = obj2Object-1;
			//print("Selecting ROI index",ergIndex,",Erg object number",ergObject);
			Ext.Manager3D_Select(obj2Index);
		}
		
		Ext.Manager3D_Erase(); // fill with black in the duplicated stack
		Ext.Manager3D_DeselectAll();
		Ext.Manager3D_Measure(); // measure only the assoc ergs
		
		// save the image
		selectWindow("obj2Assoc");
		saveAs("Tiff", outDir + File.separator  + imageBasename + "_" + obj2Name + "_Assoc.tif");
		
		// save the measurements
		//Ext.Manager3D_SaveResult("M",subFolder + "ergAssocMeas.csv");
		Ext.Manager3D_SaveResult("M",outDir + File.separator + imageBasename + "_" + obj2Name + "_AssocMeas.csv");
		Ext.Manager3D_CloseResult("M");
	}
	else {
		print("No objects in one or both images. Association not determined.");
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
	distTableName = imageBasename + "_assoc.csv";
	while (isOpen(distTableName)) {
	 	selectWindow(distTableName); 
	 	run("Close" );
	 	
	run("Collect Garbage");
	}
} // end processImage function




