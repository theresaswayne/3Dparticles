# commands exploring CDF and random distance distributions

require(spatstat)

# Generate some 3D coordinates: 20 random integers in a space of 100 x 100 x 100 units
# --they don't have to be unique (some may colocalize perfectly)
xs <- sample(1:100, 20, replace = TRUE)
ys <- sample(1:100, 20, replace = TRUE)
zs <- sample(1:100, 20, replace = TRUE)

# add some labels identifying objects as class A or B
freqA <- 30
freqB <- 70

#As <- replicate(freqA, sample(c("A"))) # also works
As <- sample(c("A"), freqA, replace = TRUE)
Bs <- sample(c("B"), freqB, replace = TRUE)
classes <- sample(c(As, Bs), 20, replace = FALSE)

# check total (should equal freqA)
count <- sum(classes == "A")

coords <- data.frame(X = xs, Y = ys, Z = zs, Label = classes)

#coords <- unique(coords)
# Convert the data so it can be used in spatstat functions

# -- define the window of observation as the max range of coords
w <- owin(c(1,100), c(1,100), c(1,100))

# -- convert the coords to a spatstat 3D point pattern object
coordsPPP <- as.ppp(coords, w)
coords3dPPP <- pp3(coords$X, coords$Y, coords$Z, box3(c(1,100), c(1,100), c(1,100)),marks = coords$Label)

# Plot the cumulative distance distribution for these random points
randomCDF <- distcdf(coordsPPP)
plot(randomCDF)

# TODO: why doesnt this work in 3D?
random3dCDF <- distcdf(coords3dPPP)

# Use spatstat to test randomness of one coord

randTest <- cdf.test(coordsPPP, "x", "ks")
plot.cdftest(randTest)
