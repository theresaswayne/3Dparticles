# superplot_mod.R
# commands for generating a superplot from data in one dataframe  
# based on Lord (2020) doi: 10/1083/jcb.202001064

# ---- Important Assumptions! ----
# Load a single dataframe containing all replicates under the name "combined."
# Data should contain columns "Replicate" (integer or character) and "Condition" (identifying the group),
# and another column with the name provided in measurementName below.

measurementName <- "Distance_to_nearest_LD"

# ---- Setup ----
require(ggplot2)
require(dplyr)
require(ggpubr) # for comparing means
require(ggbeeswarm)


#re-order factors
combined <- mutate(combined, Condition = fct_relevel(Condition, "WT Control", "WT DTT", "cue5∆ Control", "cue5∆ DTT"))


# ---- Calculate the average of each replicate within each treatment (these will be the big dots) ----
# note that !! and := are required if you want to rename with the value of a variable
# if you want all columns summarized, use summarise(across(everything(), list(mean = mean))) %>% # each column name XYZ will become XYZ_mean 

meanName <- paste0(measurementName,"_mean")

ReplicateAverages <- combined %>% 
  group_by(Condition, Replicate) %>% 
  summarise(across(!!measurementName, list(mean = mean))) %>% # each column name XYZ will become XYZ_mean 
  rename(!!measurementName := !!meanName) # substitute your measurement column name here
  #  mutate(Speed = Speed_mean, .keep="unused")

# save the replicate averages

write_csv(ReplicateAverages, paste0(measurementName,"_replicate_avgs2.csv"))


# ---- Create the plot ----

# For aes(), x is the column containing the experimental groups, and y is the measurement column
# stat_compare_means can be added to compute p values and show them on the plot.
# Methods are described in the documentation for ggpubr:compare_means

# y=!!measurementName does not seem to work
# cex

super <- ggplot(combined, aes(x=Condition, y=Distance_to_nearest_LD, color=factor(Replicate))) + # y = your measurement column
  geom_beeswarm(cex=0.05, alpha = 0.4) + scale_colour_brewer(palette = "Set1") +
  geom_beeswarm(data=ReplicateAverages, size=8, line="black") +
  #stat_compare_means(data=ReplicateAverages, 
  #                   comparisons = list(c("Control", "Drug")), 
  #                   method="t.test", paired=FALSE) +
  theme(legend.position="top")

# Show the plot in the plot window
print(super)

# save the plot
ggsave(paste0(measurementName,"_superplot.png"), plot=super, width=10, height = 10)


