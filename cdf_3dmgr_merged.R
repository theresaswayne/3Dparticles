# commands for making CDF from Fiji 3DMgr results

require(spatstat)
require(tidyverse)
require(ggplot2)

# assumes we have a dataframe called df with the following structure
# filename, row number, object A label, target object B1, target object B1 distance, 
#   etc. up to an indeterminate number of columns 

# ---- Gather information on dataset and groups ---- 

# **** change data name and levels as needed here!! ****
# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)
dataName = "Nup159_to_LD"
geno <- substr(df$filename, 0, 6)
treat <- substr(df$filename, 8, 10)

df <- mutate(df, 
             Genotype = geno, 
             Treatment = treat, 
             .after = filename)

# how many observations per group?
# count number of rows; detects NAs ONLY if they are in the geno and treat columns
table(geno, treat, useNA = "ifany") 

# split the data by genotype, treatment
CTY132_CON <- df |> filter(Genotype == "CTY132" & Treatment == "CON")
CTY132_DTT <- df |> filter(Genotype == "CTY132" & Treatment == "6hr")
CTY212_CON <- df |> filter(Genotype == "CTY212" & Treatment == "CON")
CTY212_DTT <- df |> filter(Genotype == "CTY212" & Treatment == "6hr")

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
numDists <- sum(!is.na(CTY132_CON_distcols))

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

#all_dists <- bind_rows(table1, table2, table3, table4)
all_dists <- bind_rows(table1, table2, table4)

# plot a histogram
# hist <- ggplot(data = all_dists,aes(x=BorderBorderDist,
#                                     colour = Treatment)) +
#    geom_histogram() +
#   facet_wrap(all_dists$Genotype) +
#    labs(x="Border-border distance, um",
#         title = "Distances between Nup and Erg objects")
# hist

# compare genotypes in a density plot
hist_geno <- ggplot(all_dists,aes(x=BorderBorderDist, colour = Genotype)) +
  geom_density() +
  labs(x="Border-border distance, um",
       title = "Distances between Nup and Erg objects")

# compare treatments
hist_treat <- ggplot(all_dists,aes(x=BorderBorderDist, colour = Treatment)) +
  geom_density() +
  labs(x="Border-border distance, um",
       title = "Distances between Nup and Erg objects")

ggsave(paste0(dataName,"_density_by_genotype.png"), plot=hist_geno, width=7, height = 7)
ggsave(paste0(dataName,"_density_by_treatment.png"), plot=hist_treat, width=7, height = 7)

# plot a cumulative distance function (frequency of the distances in the table)
cdf_geno <- ggplot(all_dists, aes(x=BorderBorderDist, colour = Genotype)) +
  stat_ecdf(geom = "step", pad=FALSE) +
  labs(x="Border-border distance, um",
       y = "Cumulative distance function",
       title = "Distances between Nup and Erg objects")

ggsave(paste0(dataName,"_cdf_by_genotype.png"), plot=cdf_geno, width=7, height = 7)

cdf_treat <- ggplot(all_dists, aes(x=BorderBorderDist, colour = Treatment)) +
  stat_ecdf(geom = "step", pad=FALSE) +
  labs(x="Border-border distance, um",
       y = "Cumulative distance function",
       title = "Distances between Nup and Erg objects")

ggsave(paste0(dataName,"_cdf_by_treatment.png"), plot=cdf_treat, width=7, height = 7)

# statistical comparison of distributions using non-parametric Kolgomorov-Smirnov test
# (note this is not appropriate for multiple comparisons)

geno_KS <- ks.test(BorderBorderDist ~ Genotype, data = all_dists)
treat_KS <- ks.test(BorderBorderDist ~ Treatment, data = all_dists)

geno_KS[2]
treat_KS[2]

# multiple comparisons require kruskal wallis
kw <- kruskal.test(BorderBorderDist ~ Genotype, data = all_dists)
# TODO: Multiple comparisons correction
