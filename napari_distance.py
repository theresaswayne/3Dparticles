# commands to load and process label images within napari console

# setup
import numpy as np
import skimage as sk

# label images from disk representing 2 different channels of the same dataset, segmented
nupPath = "/Volumes/CSMSR_Pon1/Pon projects 1/Cue5 consolidated/nup.tif"
ergPath = "/Volumes/CSMSR_Pon1/Pon projects 1/Cue5 consolidated/erg.tif"

# define the data at the path as a label image
label_nup = sk.io.imread(nupPath)
label_erg = sk.io.imread(ergPath)


# if you're already in napari, the viewer exists by default
viewer.add_labels(label_nup, name='nup')
viewer.add_labels(label_erg, name='erg')

