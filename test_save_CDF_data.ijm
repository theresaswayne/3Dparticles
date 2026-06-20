// plot experiments
// assumes a Coloc_Shuffle plot is open
// columns: Distance (0 to ? in microns)
// 		Cumulated frequency (0 to 1): right-hand confidence interval for shuffled data (green line)
//		X1, Y1, X2, Y2, X3, Y3:  additional values that are plotted
//		X1, Y1: left-hand confidence interval for shuffled data (green line)
//		X2, Y2: shuffled data; red curve
//		X3, Y3:  experimental data (blue curve)
//
//run("Clear Results");
//Plot.getValues(d, cf, x1, y1, x2, y2, x3, y3); // does not work; wants only 2 arrays)
//Table.create("Results");
//Table.setColumn("Distance_um", d);
//Table.setColumn("CF", cf);
//Table.setColumn("X1", x1);
//Table.setColumn("Y1", y1);
//Table.setColumn("X2", x2);
//Table.setColumn("Y2", y2);
//Table.setColumn("X3", x3);
//Table.setColumn("Y3", y3);
//Table.update;
selectWindow("Coloc_Shuffle.png");
filePath = "/Users/theresaswayne/Desktop/output/plot.png";
saveAs("PNG",filePath);