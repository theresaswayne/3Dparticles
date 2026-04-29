# ---- Setup ----
import os
import math
import io
from net.imglib2.view import Views
from ij import IJ, ImagePlus, ImageStack
from ij.process import ImageProcessor, FloatProcessor, StackProcessor
from ij.process import ImageConverter
import string
from ij.measure import ResultsTable
from ij.plugin import ImageCalculator
from ij import WindowManager

#imp = IJ.getImage();
imp1 = WindowManager.getImage("erg 1.tif");
imp2 = WindowManager.getImage("nup 1.tif");
imp3 = ImageCalculator.run(imp1, imp2, "Add create stack");
imp3.show();
IJ.setRawThreshold(imp3, 1, 65535);
imp3.setAutoThreshold("Default dark stack no-reset");
IJ.run(imp3, "Convert to Mask", "background=Dark black");
imp3.setTitle("sumthresh");
imp3.show();

imp = imp3.duplicate();
IJ.run(imp, "Maximum 3D...", "x=5 y=5 z=2");
imp.show();