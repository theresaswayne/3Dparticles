# commands for visualizing nearest-neighbor distances from Fiji 3DSuite results, with optional binning of similar object numbers

require(spatstat)
require(tidyverse)
require(ggplot2)
require(dunn.test)
require(ggpubr)
require(ggbeeswarm)

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

min_nup <- 5
max_nup <- 15
min_erg <- 5
max_erg <- 15

# ---- Gather information on dataset and groups ---- 

# **** change data name and levels as needed here!! ****
# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)
geno <- substr(df$filename, 0, 6)
treat <- substr(df$filename, 8, 10)

# replace original filename and treatment with more readable info
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
counts_mod <- mutate(counts, 
                 Genotype = count_geno, 
                 Treatment = count_treat, 
                 .after = Filename)

# Use only the nearest neighbor distance
df_nn <- df_mod |> select(filename,Genotype, Treatment, `...2`, Nup_Obj, O1, V1)

# how many observations per group? (before filtering)
# count number of rows; detects NAs ONLY if they are in the geno and treat columns
table(df_nn$Genotype, df_nn$Treatment, useNA = "ifany") # number of NN distances
table(counts_mod$Genotype, counts_mod$Treatment, useNA = "ifany")  # number of cells

# Filter on distance if desired
df_nn_close <- df_nn |> filter(V1 <= max_dist)

# how many observations per group? (after filtering on distance)
# count number of rows; detects NAs ONLY if they are in the geno and treat columns
table(df_nn_close$Genotype, df_nn_close$Treatment, useNA = "ifany") # number of distances

# ---- Select a bin of data (cells with similar particle counts) ----

binString <- paste0("Nup_",min_nup,"to",max_nup,"_Erg_",min_erg,"to",max_erg)

# which images have the desired counts?
filtered_counts <- counts_mod |> 
  filter(between(Nup_Objects, min_nup, max_nup)) |>
  filter(between(Erg_Objects, min_erg, max_erg)) 

# filter the data to include only those images
filtered_distances <- df_nn_close |> 
  filter(filename %in% filtered_counts$Filename)

# see how many total distances we have in each group now
table(filtered_distances$Genotype, filtered_distances$Treatment, useNA = "ifany") # number of distances

# how many cells in each group after filtering
table(filtered_counts$Genotype, filtered_counts$Treatment, useNA = "ifany") # number of distances


# ---- Generate CDFs ----

# split the data by genotype, treatment
CTY132_CON <- filtered_distances |> filter(Genotype == "CTY132" & Treatment == "Control")
CTY132_DTT <- filtered_distances |> filter(Genotype == "CTY132" & Treatment == "DTT")
CTY212_CON <- filtered_distances |> filter(Genotype == "CTY212" & Treatment == "Control")
CTY212_DTT <- filtered_distances |> filter(Genotype == "CTY212" & Treatment == "DTT")

# Combine everything back into a dataframe with meaningful factors
table1 <- data.frame(Genotype = "CTY132",
             Treatment = "Control",
             BorderBorderDist = CTY132_CON$V1)

table2 <- data.frame(Genotype = "CTY132",
                     Treatment = "DTT",
                     BorderBorderDist = CTY132_DTT$V1)

table3 <- data.frame(Genotype = "CTY212",
                     Treatment = "Control",
                     BorderBorderDist = CTY212_CON$V1)

table4 <- data.frame(Genotype = "CTY212",
                     Treatment = "DTT",
                     BorderBorderDist = CTY212_DTT$V1)

combo_dists <- bind_rows(table1, table2, table3, table4)

# see how many NN distances we have in each group now (should be same as table of filtered distances)
table(combo_dists$Genotype, combo_dists$Treatment, useNA = "ifany") # number of distances

# how many cells per group now
how_many_cells <- filtered_distances |> 
  group_by(Genotype, Treatment) |> 
  summarise(nCells = n_distinct(filename))

write_csv(how_many_cells, paste0(binString,"_ncells.csv"))
# ---- Plots ----

#plot a histogram 
hist_dist <- ggplot(data = combo_dists,aes(x=BorderBorderDist,
                                    fill = Treatment)) +
   geom_histogram(alpha=0.5) +
  theme_minimal(base_size = 18) +
  scale_colour_brewer(palette = "Set1") +
  facet_wrap(Genotype~Treatment) +
   labs(x="Border-border distance, um",
        title = "Distance between Nup159 and closest LD")

ggsave(paste0(binString,"_nn_histo.png"), plot=hist_dist, width=8, height = 8)


# compare groups in a density plot separated by genotype
# dens_geno <- ggplot(all_dists,aes(x=BorderBorderDist, colour = Treatment)) +
#   geom_density() +
#   facet_wrap(~Genotype) +
#   labs(x="Border-border distance, um",
#        title = paste0("Distance between Nup159 and closest LD object ",binString))
# 
# # compare treatments
# dens_treat <- ggplot(all_dists,aes(x=BorderBorderDist, colour = Genotype)) +
#   geom_density() +
#   facet_wrap(~Treatment) +
#   labs(x="Border-border distance, um",
#        title = paste0("Distance, Nup159 puncta to closest LD, µm,",binString))
# 
# ggsave(paste0(binString,"_nn_density_by_genotype.png"), plot=dens_geno, width=7, height = 7)
# ggsave(paste0(binString,"_nn_density_by_treatment.png"), plot=dens_treat, width=7, height = 7)

# density all conditions in one plot
dens_dist <- ggplot(combo_dists, aes(x=BorderBorderDist,
                                     fill = Treatment,
                                     na.rm = TRUE)) +
  geom_density() +
  theme_minimal(base_size = 18) +
  facet_wrap(Genotype~Treatment) +
  labs(x = "Distance, Nup159 Puncta to nearest LD, µm",
       title =  paste0("Density plot of ",binString))

ggsave(paste0(binString,"_nn_density.png"), plot=dens_dist, width=8, height = 8)

#  plot of distances
# bee_dist <- ggplot(combo_dists, aes(x=Treatment,y=BorderBorderDist, color = Treatment)) +
#     geom_beeswarm(method = "compactswarm", alpha=0.5, dodge.width = 0.5) +
#   facet_wrap(~Genotype) +
#     scale_colour_brewer(palette = "Set1") +
#   scale_x_discrete(expand = expansion(mult = c(0.2, 0.2))) +
#     theme_minimal() 
# 
# ggsave(paste0(binString,"_nn_beeswarm.png"), plot = bee_dist, width=8, height = 8)

# plot a cumulative distribution function (cumulative frequency of the NN distances in the table)
cdf_dist <- ggplot(combo_dists, aes(x=BorderBorderDist, colour = Treatment)) +
  stat_ecdf(geom = "smooth", pad=TRUE) +
  facet_wrap(~Genotype) +
  theme_minimal(base_size = 20) +
  theme(panel.spacing = unit(2, "lines")) +
#  theme(plot.title = element_text(hjust = 0.5)) +
  labs(x="Border-border distance, um",
       y = "Cumulative frequency",
       title = "Distance between Nup159 and closest LD",
       subtitle = "In cells with 5-15 Nup159 puncta and 5-15 LDs"
)

ggsave(paste0(binString,"_nn_cdf.png"), plot=cdf_dist, width=8, height=8)

# 
# cdf_geno <- ggplot(combo_dists, aes(x=BorderBorderDist, colour = Treatment)) +
#   stat_ecdf(geom = "step", pad=FALSE) +
#   facet_wrap(~Genotype) +
#   labs(x="Border-border distance, um",
#        y = "Cumulative frequency",
#        title = paste0("Distance between Nup159 and closest LD ",binString))
# 
# cdf_treat <- ggplot(combo_dists, aes(x=BorderBorderDist, colour = Genotype)) +
#   stat_ecdf(geom = "step", pad=FALSE) +
#   facet_wrap(~Treatment) +
#   labs(x="Border-border distance, um",
#        y = "Cumulative distance",
#        title = paste0("Distance between Nup159 and closest LD ",binString))
# 
# ggsave(paste0(binString,"_nn_cdf_by_genotype.png"), plot=cdf_geno, width=7, height = 7)
# ggsave(paste0(binString,"_nn_cdf_by_treatment.png"), plot=cdf_treat, width=7, height = 7)

# ---- Hypothesis testing ----

# statistical comparison of distributions using non-parametric Kolgomorov-Smirnov test
# with Dunn's test for multiple comparisons

x <- c(CTY132_CON$V1,
          CTY132_DTT$V1,
          CTY212_CON$V1,
          CTY212_DTT$V1)

g <- c(rep("CTY132_CON",length(CTY132_CON$V1)),
           rep("CTY132_DTT",length(CTY132_DTT$V1)),
               rep("CTY212_CON",length(CTY212_CON$V1)),
                   rep("CTY212_DTT",length(CTY212_DTT$V1)))

d <- dunn.test(x, g,
                  method = "bonferroni",
               list=TRUE)

d_results <- data.frame(Comparison = d$comparisons, Z = d$Z, P_adjusted = d$P.adjusted)

write_csv(d_results, paste0(binString,"_nn_dunn_results.csv"))

#geno_KS <- ks.test(BorderBorderDist ~ Genotype, data = all_dists)
#treat_KS <- ks.test(BorderBorderDist ~ Treatment, data = all_dists)
