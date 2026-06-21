# commands for making CDF from Fiji 3DMgr results

require(spatstat)
require(tidyverse)
require(ggplot2)

# assumes we have a dataframe called df with the following structure
# row number, object A label, target object B1, target object B1 distance, 
#   etc. up to an indeterminate number of columns 

# pull out the distances
# these are a vector of all of the values from the columns starting with V

# get the columns with the distances
dist_cols <- df %>% select(starts_with("V"))

# combine all these columns into a single vector
all_dists <- unlist(dist_cols)

# plot a histogram
hist <- ggplot(mapping = aes(all_dists)) +
  geom_histogram() +
  labs(x="Border-border distance, um",
       title = "Distances between all objects in one cell")

# ggsave(paste0(dataName,"_fxn_assoc_",crit,"_boxplot.png"), width=7, height = 7)
ggsave("histo.png", width=7, height = 7)
s
# plot a cumulative distance function (frequency of the distances in the table)
cdf <- ggplot(mapping = aes(all_dists)) +
  stat_ecdf(geom = "step", pad=FALSE) +
  labs(x="Border-border distance, um",
       y = "Cumulative distance function",
       title = "Distances between all objects in one cell")

cdf

# Multiple ECDFs
ggplot(df, aes(x, colour = g)) +
  stat_ecdf()

