run("3D Manager V4 Macros"); // import 3DManager macro extension
Ext.Manager3DV4_ImportImage(); // import current label image
Ext.Manager3DV4_MeasureList(); // print the list of available measurements
Ext.Manager3DV4_GetType(0, type); print(type); // get the type of objet 0
Ext.Manager3DV4_SetType(0, 1); // set the type of object 0
Ext.Manager3DV4_GetType(0, type); print(type); // get the type of objet 0
Ext.Manager3DV4_Measure(0, "Volume(Unit)", mes); print(mes); // performs measurement on object 0
Ext.Manager3DV4_MeasureIntensity(0, "CMX(unit)", mes); print(mes); // performs intensity measurement on object 0
Ext.Manager3DV4_DistanceList(); // List available distance  between two objects
Ext.Manager3DV4_Distance2(0,1,"DistCenterCenterPix",dist); print(dist); // distance between first and second object
Ext.Manager3DV4_NbObjects(nb); print(nb); // get the total number of objects
newImage("color", "RGB black", 1, 1, 1); // to store color value
for(i=0;i<nb;i++){ // loop for all object indices
    setColor(128+random*127, 128+127*random, 128+127*random); // assigns random colour
    Ext.Manager3DV4_3DViewer(i); // displays object i in 3D viewer with current colour
}
close(); // close RGB image
    

