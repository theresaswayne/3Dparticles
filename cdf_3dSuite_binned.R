# commands for making CDF from Fiji 3DSuite results, with binning of similar object numbers

require(spatstat)
require(tidyverse)
require(ggplot2)
require(dunn.test)

# assumes we have a dataframe called df with the following structure
# filename, row number, object A label, target object B1, target object B1 distance, 
#   etc. up to an indeterminate number of columns 

# and another dataframe called counts with structure
# Filename, Nup_objects, Erg_objects
# containing counts of objects per image

# ---- Gather information on dataset and groups ---- 

# **** change data name and levels as needed here!! ****
# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)
dataName = "Nup159_to_LD"
geno <- substr(df$filename, 0, 6)
treat <- substr(df$filename, 8, 10)
newFilename = str_sub(df$filename, 0, end = -15) # remove _3dResults.csv

df_mod <- mutate(df, 
             Genotype = geno, 
             Treatment = treat, 
             .after = filename) |>
  mutate(filename = newFilename)

count_geno <- substr(counts$Filename, 0, 6)
count_treat <- substr(counts$Filename, 8, 10)

counts_mod <- mutate(counts, 
                 Genotype = count_geno, 
                 Treatment = count_treat, 
                 .after = Filename)

# how many observations per group?
# count number of rows; detects NAs ONLY if they are in the geno and treat columns
table(geno, treat, useNA = "ifany") # number of distances
table(count_geno, count_treat, useNA = "ifany")  # number of cells

# ---- Select a bin of data (cells with similar particle counts) ----

# 1-4 both: done
# 5-8 both: no control cells
# 1-4 nup, 5-8 erg: done
# 1-4 nup, 9-12 erg: no control wt cells
# 1-4 nup, 13-16 erg: no control cells

min_nup <- 1
max_nup <- 4
min_erg <- 13
max_erg <- 16

binString <- paste0("Nup_",min_nup,"to",max_nup,"_Erg_",min_erg,"to",max_erg)

# which images have the desired counts?
filtered_counts <- counts |> 
  filter(between(Nup_Objects, min_nup, max_nup)) |>
  filter(between(Erg_Objects, min_erg, max_erg)) 

# filter the data to include only those images
filtered_distances <- df_mod |> 
  filter(filename %in% filtered_counts$Filename)

# see how many distances we have in each group now
table(filtered_distances$Genotype, filtered_distances$Treatment, useNA = "ifany") # number of distances


# ---- Generate CDFs ----

# split the data by genotype, treatment
CTY132_CON <- filtered_distances |> filter(Genotype == "CTY132" & Treatment == "CON")
CTY132_DTT <- filtered_distances |> filter(Genotype == "CTY132" & Treatment == "6hr")
CTY212_CON <- filtered_distances |> filter(Genotype == "CTY212" & Treatment == "CON")
CTY212_DTT <- filtered_distances |> filter(Genotype == "CTY212" & Treatment == "6hr")

# Combine all the distances into one column

CTY132_CON_dists <- CTY132_CON |> 
  select(starts_with("V")) |> 
  unlist() |> na.omit()

CTY132_DTT_dists <- CTY132_DTT |> 
  select(starts_with("V")) |> 
  unlist() |> na.omit()

CTY212_CON_dists <- CTY212_CON |> 
  select(starts_with("V")) |> 
  unlist() |> na.omit()

CTY212_DTT_dists <- CTY212_DTT |> 
  select(starts_with("V")) |> 
  unlist() |> na.omit()

# check the answer
CTY132_CON_distcols <- CTY132_CON |> select(starts_with("V"))
numDists <- sum(!is.na(CTY132_CON_distcols)) # should = the length of the CTY132_CON_dists vector

# Combine everything back into a dataframe
table1 <- data.frame(Genotype = "CTY132",
             Treatment = "Control",
             BorderBorderDist = CTY132_CON_dists)

table2 <- data.frame(Genotype = "CTY132",
                     Treatment = "6hrDTT",
                     BorderBorderDist = CTY132_DTT_dists)

table3 <- data.frame(Genotype = "CTY212",
                     Treatment = "Control",
                     BorderBorderDist = CTY212_CON_dists)

table4 <- data.frame(Genotype = "CTY212",
                     Treatment = "6hrDTT",
                     BorderBorderDist = CTY212_DTT_dists)

all_dists <- bind_rows(table1, table2, table3, table4)

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
hist_geno <- ggplot(all_dists,aes(x=BorderBorderDist, colour = Treatment)) +
  geom_density() +
  facet_wrap(~Genotype) +
  labs(x="Border-border distance, um",
       title = paste0("Distances between Nup and Erg objects ",binString))

# compare treatments
hist_treat <- ggplot(all_dists,aes(x=BorderBorderDist, colour = Genotype)) +
  geom_density() +
  facet_wrap(~Treatment) +
  labs(x="Border-border distance, um",
       title = paste0("Distances between Nup and Erg objects ",binString))

ggsave(paste0(binString,"_density_by_genotype.png"), plot=hist_geno, width=7, height = 7)
ggsave(paste0(binString,"_density_by_treatment.png"), plot=hist_treat, width=7, height = 7)

# plot a cumulative distance function (frequency of the distances in the table)
cdf_geno <- ggplot(all_dists, aes(x=BorderBorderDist, colour = Treatment)) +
  stat_ecdf(geom = "step", pad=FALSE) +
  facet_wrap(~Genotype) +
  labs(x="Border-border distance, um",
       y = "Cumulative distance function",
       title = paste0("Distances between Nup and Erg objects ",binString))


cdf_treat <- ggplot(all_dists, aes(x=BorderBorderDist, colour = Genotype)) +
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

x <- c(CTY132_CON_dists,
          CTY132_DTT_dists,
          CTY212_CON_dists,
          CTY212_DTT_dists)

g <- c(rep("CTY132_CON",length(CTY132_CON_dists)),
           rep("CTY132_DTT",length(CTY132_DTT_dists)),
               rep("CTY212_CON",length(CTY212_CON_dists)),
                   rep("CTY212_DTT",length(CTY212_DTT_dists)))

d <- dunn.test(x, g,
                  method = "bonferroni",
               list=TRUE)

d_results <- data.frame(Comparison = d$comparisons, Z = d$Z, P_adjusted = d$P.adjusted)

write_csv(d_results, paste0(binString,"_dunn_results.csv"))


#geno_KS <- ks.test(BorderBorderDist ~ Genotype, data = all_dists)
#treat_KS <- ks.test(BorderBorderDist ~ Treatment, data = all_dists)
