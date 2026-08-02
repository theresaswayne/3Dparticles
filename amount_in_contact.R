# amount_in_contact.R
# commands to determine the amount of fluorescence puncta intensity (integrated intensity) in structures in contact
# requires 2 inputs derived from ImageJ 3D Mgr/Suite:
# dist, containing objects in Nup159 channel and the distance to their closest neighbor in the LD channel
# quant, containing the intensity measurements for the Nup159 channel (note that this includes only aggregates,not all Nup159 signal)

# ---- Setup -----

require(spatstat)
require(tidyverse)
require(ggplot2)
require(dunn.test)
require(beeswarm)
require(ggpubr)

dataName = "replicate 3"

# ---- Clean up data ----

# remove all but the nearest neighbor distance
dist_nn <- dist %>%
  select(filename, Nup_Obj, O1, V1)

# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)

genoD <- substr(dist_nn$filename, 0, 6)
genoQ <- substr(quant$filename, 3, 8) # the quant results have Q_ prepended

treatD <- substr(dist_nn$filename, 8, 10)
treatQ <- substr(quant$filename, 10, 12) # the quant results have Q_ prepended

# replace original genotype, treatment, and filename with more readable info
genoD <- genoD %>% 
  str_replace("CTY132", "WT") %>% 
  str_replace("CTY212", "cue5∆")

genoQ <- genoQ %>% 
  str_replace("CTY132", "WT") %>% 
  str_replace("CTY212", "cue5∆")

treatD <- treatD %>% 
  str_replace("6hr", "DTT") %>%
  str_replace("CON", "Control")

treatQ <- treatQ %>% 
  str_replace("6hr", "DTT") %>%
  str_replace("CON", "Control")

newDistFilename = str_sub(dist_nn$filename, 0, end = -15) # remove _3dResults.csv
newQuantFilename = str_sub(quant$filename, 3, end = -38) # remove _quant_results.csv

# update the dataframes
dist_mod <-  mutate(dist_nn, 
                   Genotype = genoD, 
                   Treatment = treatD, 
                   .after = filename) %>%
  mutate(filename = newDistFilename)

quant_mod <-  mutate(quant, 
                    Genotype = genoQ, 
                    Treatment = treatQ, 
                    .after = filename) %>%
  mutate(filename = newQuantFilename) %>%
  rename(Nup_Obj = Label)


# ---- Combine the distance and intensity data into one dataframe ----
# (each row = 1 Nup159 puncta)

# Note that the number of observations may be different
# Special cases -- presumably when there is no LD, there is no distance measured

# Check for diffs -- if there are many, review analysis
setdiff(quant_mod$filename, dist_mod$filename)

# join the tables, ignoring any cells that do not have distance measurements
combined <- left_join(dist_mod, quant_mod, by=join_by(filename, Nup_Obj, Genotype, Treatment))

# Re-order so WT comes first 
combined <- mutate(combined, Genotype = fct_relevel(Genotype, "WT", "cue5∆"))


# ---- Calculations ----

# Table of IntDen for particles with V1 (nn dist) = 0
NupContact <- combined %>% 
  group_by(filename) %>%
  filter(V1 == 0) %>%
  summarise(Genotype = first(Genotype),
            Treatment = first(Treatment),
            IntDenContact = sum(IntDen),
            nPunctaContact = n())

# Table of IntDen for particles with V1 (nn dist) = 0
NupNotContact <- combined %>% 
  group_by(filename) %>%
  filter(V1 > 0) %>%
  summarise(Genotype = first(Genotype),
            Treatment = first(Treatment),
            IntDenNotContact = sum(IntDen),
            nPunctaNotContact = n())

# Table of both values
NupContactByCell <- full_join(NupContact, NupNotContact, by=join_by(filename, Genotype, Treatment)) %>%
  mutate_if(is.numeric,coalesce,0) # make NAs 0

# Calculate % of IntDen in contact per cell
NupContactByCell <- NupContactByCell %>%
  mutate(FxnIntDenContact = IntDenContact/(IntDenContact + IntDenNotContact))

# Calculate overall % of puncta IntDen in contact
#totalContact = sum(NupContactByCell$IntDenContact)
#totalNotContact = sum(NupContactByCell$IntDenNotContact)
#totalFxnContact = totalContact/(totalContact + totalNotContact)

# Write table of cells
cellTableName <- paste0(dataName, "_IntDenContact_byCell.csv")
write_csv(NupContactByCell,cellTableName)

# Get totals by group
NupContactByGroup <- NupContactByCell %>% 
  group_by(Genotype, Treatment) %>%
  summarise(MeanFxnIntDenContact = mean(FxnIntDenContact),
            MedianFxnIntDenContact = median(FxnIntDenContact),
            SDFxnIntDenContact = sd(FxnIntDenContact),
              nPuncta = sum(nPunctaContact + nPunctaNotContact),
            nCells = n())
            
# Write summary
groupTableName <- paste0(dataName, "_IntDenContact_byGroup.csv")
write_csv(NupContactByGroup,groupTableName)


# boxplot

intden_box <- ggplot(NupContactByCell, aes(x=Treatment,y=FxnIntDenContact, fill = Treatment, na.rm = TRUE)) +
  geom_boxplot() +
  scale_fill_manual(values = c("white", "grey")) +
  theme_minimal(base_size = 14) +
  facet_wrap(~Genotype) +
  stat_summary(fun=mean, geom="point", shape=18,
               size=3, color="red") +
  theme(legend.position="none") +
  labs(y = "Fraction of Nup159 Puncta Intensity in Contact with LD",
       title=dataName)

ggsave(paste0(dataName,"_IntDenContact_boxplot.png"),plot=intden_box, width=8, height = 8)
