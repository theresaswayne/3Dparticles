imageCalculator("Add create stack", "erg 1.tif","nup 1.tif");
selectImage("Result of erg 1.tif");
run("Maximum 3D...", "x=7 y=7 z=2");
run("3D Binary Close Labels", "radiusxy=7 radiusz=2 operation=Close");
run("Histogram", "stack");
close;
//setMinAndMax(0, 0);
setAutoThreshold("Default dark no-reset");
//run("Threshold...");
setThreshold(1, 65535, "raw");
setOption("BlackBackground", true);
run("Convert to Mask", "background=Dark black create");

// generate distance results (center and edge) for all objects, 1 column per measurement type
run("DiAna_Analyse", "img1=[erg 1.tif] img2=[nup 1.tif] lab1=[erg 1.tif] lab2=[nup 1.tif] adja kclosest=100b");
saveAs("Results", "/Users/theresaswayne/Desktop/m2AdjacencyResults.csv");

// CDF with mask
run("DiAna_Analyse", "img1=[erg 1.tif] img2=[nup 1.tif] lab1=[erg 1.tif] lab2=[nup 1.tif] shuffle mask=MASK_CloseLabels");

// cdf without mask (Diana sometimes crashes 2nd time you run it -or messes up the object pop so erg has only 1 )
run("DiAna_Analyse", "img1=[erg 1.tif] img2=[nup 1.tif] lab1=[erg 1.tif] lab2=[nup 1.tif] shuffle");
