# commands for calculating average nearest neighbor distance from Fiji 3DSuite results, 
# with optional binning of similar object numbers

require(spatstat)
require(tidyverse)
require(ggplot2)
require(dunn.test)
require(beeswarm)
require(ggpubr)

# assumes we have two dataframes: 1)  df, with the following structure:
# filename, row number, object A label, target object B1, target object B1 distance, 
#   etc. up to an indeterminate number of columns 

# and 2) counts, with structure:
# Filename, Nup_objects, Erg_objects
# containing counts of objects per image


# ---- Parameters for filtering ----

# Name of the dataset

dataName = "Nup159_to_LD"

# Distances to consider

max_dist <- 2.0

# Particle counts

min_nup <- 0
max_nup <- 100
min_erg <- 0
max_erg <- 100

# **** change data name and levels as needed here!! ****
# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)

dataName = "Nup159_to_LD"
geno <- substr(df$filename, 0, 6)
treat <- substr(df$filename, 8, 10)

# replace original genotype, filename, and treatment with more readable info
geno <- str_replace(geno, "CTY132", "WT")
geno <- str_replace(geno, "CTY212", "cue5∆")
treat<- str_replace(treat, "6hr", "DTT")
treat<- str_replace(treat, "CON", "Control")
newFilename = str_sub(df$filename, 0, end = -15) # remove _3dResults.csv

df_mod <- mutate(df, 
                 Genotype = geno, 
                 Treatment = treat, 
                 .after = filename) |>
  mutate(filename = newFilename)

count_geno <- substr(counts$Filename, 0, 6)
count_treat <- substr(counts$Filename, 8, 10)
count_treat<- str_replace(count_treat, "6hr", "DTT")
count_treat<- str_replace(count_treat, "CON", "Control")
count_geno <- str_replace(count_geno, "CTY132", "WT")
count_geno <- str_replace(count_geno, "CTY212", "cue5∆")
counts_mod <- mutate(counts, 
                     Genotype = count_geno, 
                     Treatment = count_treat, 
                     .after = Filename)

# re-order so WT is first
df_mod <- mutate(df_mod, Genotype = fct_relevel(Genotype, "WT", "cue5∆"))
counts_mod <- mutate(counts_mod, , Genotype = fct_relevel(Genotype, "WT", "cue5∆"))         

# Use only the nearest neighbor distance
df_nn <- df_mod |> select(filename,Genotype, Treatment, `...2`, Nup_Obj, O1, V1)

# how many observations per group?
# count number of rows; detects NAs ONLY if they are in the geno and treat columns
table(df_nn$Genotype, df_nn$Treatment, useNA = "ifany") # number of distances
table(counts_mod$Genotype, counts_mod$Treatment, useNA = "ifany")  # number of cells

# # Filter on distance if desired
# df_nn_close <- df_nn |> filter(V1 <= max_dist)
# 
# # how many observations per group? (after filtering on distance)
# # count number of rows; detects NAs ONLY if they are in the geno and treat columns
# table(df_nn_close$Genotype, df_nn_close$Treatment, useNA = "ifany") # number of distances


# ---- Select a bin of data (cells with similar particle counts) ----

binString <- paste0("Nup_",min_nup,"to",max_nup,"_Erg_",min_erg,"to",max_erg)

# which images have the desired counts?
filtered_counts <- counts_mod |> 
  filter(between(Nup_Objects, min_nup, max_nup)) |>
  filter(between(Erg_Objects, min_erg, max_erg)) 

# filter the data to include only those images
filtered_distances <- df_nn |> 
  filter(filename %in% filtered_counts$Filename)

# see how many distances we have in each group now
table(filtered_distances$Genotype, filtered_distances$Treatment, useNA = "ifany") # number of distances

# ---- Calculate average and median NN distances per group ----

filtered_dist_summary <- filtered_distances |> 
  group_by(Genotype, Treatment) |>
  summarise(Median_NN_Dist_Nup159toLD = median(V1),
            Average_NN_Dist_Nup159toLD = mean(V1),
            SD_NN_Dist = sd(V1),
            TotalNup159 = n(),
            TotalCells = n_distinct(filename))

write_csv(filtered_dist_summary, paste0(binString,"_distance_summary.csv"))


# ---- Calculate % in contact ----

filtered_contact_summary <- filtered_distances |>
  group_by(Genotype, Treatment) |>
  summarise("%Nup159PunctaInContactWithLD" = 100*sum(V1==0)/n(),
            "%Nup159<200nmFromLD" = 100*sum(V1<=0.2)/n(),
            TotalNup159 = n(),
            TotalCells = n_distinct(filename))
write_csv(filtered_contact_summary, paste0(binString,"_contact_summary.csv"))


# split the data by genotype, treatment
WT_CON <- filtered_distances |> filter(Genotype == "WT" & Treatment == "Control")
WT_DTT <- filtered_distances |> filter(Genotype == "WT" & Treatment == "DTT")
CUE5_CON <- filtered_distances |> filter(Genotype == "cue5∆" & Treatment == "Control")
CUE5_DTT <- filtered_distances |> filter(Genotype == "cue5∆" & Treatment == "DTT")

# Combine everything back into a dataframe with meaningful factors
table1 <- data.frame(Genotype = "WT",
                     Treatment = "Control",
                     BorderBorderDist = WT_CON$V1)

table2 <- data.frame(Genotype = "WT",
                     Treatment = "DTT",
                     BorderBorderDist = WT_DTT$V1)

table3 <- data.frame(Genotype = "cue5∆",
                     Treatment = "Control",
                     BorderBorderDist = CUE5_CON$V1)

table4 <- data.frame(Genotype = "cue5∆",
                     Treatment = "DTT",
                     BorderBorderDist = CUE5_DTT$V1)

combo_dists <- bind_rows(table1, table2, table3, table4)

# see how many NN distances we have in each group now (should be same as table of filtered distances)
table(combo_dists$Genotype, combo_dists$Treatment, useNA = "ifany") # number of distances

# how many cells per group now
how_many_cells <- filtered_distances |> 
  group_by(Genotype, Treatment) |> 
  summarise(nCells = n_distinct(filename))

write_csv(how_many_cells, paste0(binString,"_ncells.csv"))

#plot a histogram
# hist <- ggplot(data = all_dists,aes(x=BorderBorderDist,
#                                     colour = Treatment)) +
#    geom_histogram() +
#   facet_wrap(all_dists$Genotype) +
#    labs(x="Border-border distance, um",
#         title = "Distances between Nup and Erg objects")
# hist

# ---- Plots ----

# compare groups in a density plot separated by genotype
hist_geno <- ggplot(combo_dists,aes(x=BorderBorderDist, colour = Treatment)) +
  geom_density() +
  facet_wrap(~Genotype) +
  labs(x="Border-border distance, um",
       title = paste0("Distances between Nup and Erg objects ",binString))

# compare treatments
hist_treat <- ggplot(combo_dists,aes(x=BorderBorderDist, colour = Genotype)) +
  geom_density() +
  facet_wrap(~Treatment) +
  labs(x="Border-border distance, um",
       title = paste0("Distances between Nup and Erg objects ",binString))

ggsave(paste0(binString,"_density_by_genotype.png"), plot=hist_geno, width=7, height = 7)
ggsave(paste0(binString,"_density_by_treatment.png"), plot=hist_treat, width=7, height = 7)

# plot a cumulative distance function (frequency of the distances in the table)
cdf_geno <- ggplot(combo_dists, aes(x=BorderBorderDist, colour = Treatment)) +
  stat_ecdf(geom = "step", pad=FALSE) +
  facet_wrap(~Genotype) +
  labs(x="Border-border distance, um",
       y = "Cumulative distance function",
       title = paste0("Distances between Nup and Erg objects ",binString))


cdf_treat <- ggplot(combo_dists, aes(x=BorderBorderDist, colour = Genotype)) +
  stat_ecdf(geom = "step", pad=FALSE) +
  facet_wrap(~Treatment) +
  labs(x="Border-border distance, um",
       y = "Cumulative distance function",
       title = paste0("Distances between Nup and Erg objects ",binString))

ggsave(paste0(binString,"_cdf_by_genotype.png"), plot=cdf_geno, width=7, height = 7)
ggsave(paste0(binString,"_cdf_by_treatment.png"), plot=cdf_treat, width=7, height = 7)

# ---- Hypothesis testing ----

# statistical comparison of distributions using non-parametric Kolgomorov-Smirnov test
# with Dunn's test for multiple comparisons

x <- c(WT_CON$V1,
          WT_DTT$V1,
          CUE5_CON$V1,
          CUE5_DTT$V1)

g <- c(rep("WT_CON",length(WT_CON$V1)),
           rep("WT_DTT",length(WT_DTT$V1)),
               rep("CUE5_CON",length(CUE5_CON$V1)),
                   rep("CUE5_DTT",length(CUE5_DTT$V1)))

d <- dunn.test(x, g,
                  method = "bonferroni",
               list=TRUE)

d_results <- data.frame(Comparison = d$comparisons, Z = d$Z, P_adjusted = d$P.adjusted)

write_csv(d_results, paste0(binString,"_dunn_results.csv"))


#geno_KS <- ks.test(BorderBorderDist ~ Genotype, data = all_dists)
#treat_KS <- ks.test(BorderBorderDist ~ Treatment, data = all_dists)

