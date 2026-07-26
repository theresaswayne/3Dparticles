# commands for analyzing object counts from Fiji 3DSuite results

require(spatstat)
require(tidyverse)
require(ggplot2)
require(dunn.test)

# assumes we have a dataframe called counts with the following structure
# Filename, Nup_objects, Erg_objects
# containing counts of objects per image

# ---- Gather information on dataset and groups ---- 

# **** change data name and levels as needed here!! ****
# parse image filename to get genotype (1st 6 chars) 
#    and treatment (search for CON or 6hr)
dataName = "Trial3"
geno <- substr(counts$Filename, 0, 6)
treat <- substr(counts$Filename, 8, 10)
treat<- str_replace(treat, "6hr", "DTT")
treat<- str_replace(treat, "CON", "Control")
geno <- str_replace(geno, "CTY132","WT")
geno <- str_replace(geno, "CTY212","Cue5∆")

counts_mod <- mutate(counts, 
             Genotype = geno, 
             Treatment = treat, 
             .after = Filename)

# how many observations (cells) per group?
# count number of rows; detects NAs ONLY if they are in the geno and treat columns
table(geno, treat, useNA = "ifany") 

# split the data by genotype, treatment
CTY132_CON <- counts_mod |> filter(Genotype == "WT" & Treatment == "Control")
CTY132_DTT <- counts_mod |> filter(Genotype == "WT" & Treatment == "DTT")
CTY212_CON <- counts_mod |> filter(Genotype == "Cue5∆" & Treatment == "Control")
CTY212_DTT <- counts_mod |> filter(Genotype == "Cue5∆" & Treatment == "DTT")


nup_box <- ggplot(counts_mod, aes(x=Treatment,y=Nup_Objects, fill = Treatment, na.rm = TRUE)) +
  geom_boxplot() +
  scale_fill_manual(values = c("white", "grey")) +
  theme_minimal(base_size = 24) +
  facet_wrap(~Genotype) +
  stat_summary(fun=mean, geom="point", shape=18,
               size=3, color="red") +
  theme(legend.position="none") +
  labs(y = "Nup159 Puncta Per Cell",
       title = dataName)

ggsave(paste0(dataName,"_nup_count_boxplot.png"),plot=nup_box, width=7, height = 7)


erg_box <- ggplot(counts_mod, aes(x=Treatment,y=Erg_Objects, fill = Treatment, na.rm = TRUE)) +
  geom_boxplot() +
  scale_fill_manual(values = c("white", "grey")) +
  theme_minimal(base_size = 24) +
  facet_wrap(~Genotype) +
  stat_summary(fun=mean, geom="point", shape=18,
               size=3, color="red") +
  theme(legend.position="none") +
  labs(y = "LDs Per Cell",
       title=dataName)

ggsave(paste0(dataName,"_erg_count_boxplot.png"),plot=erg_box, width=7, height = 7)

# statistical comparison of distributions using non-parametric Kolgomorov-Smirnov test
# with Dunn's test for multiple comparisons

nupCounts <- c(CTY132_CON$Nup_Objects,
          CTY132_DTT$Nup_Objects,
          CTY212_CON$Nup_Objects,
          CTY212_DTT$Nup_Objects)


ergCounts <- c(CTY132_CON$Erg_Objects,
       CTY132_DTT$Erg_Objects,
       CTY212_CON$Erg_Objects,
       CTY212_DTT$Erg_Objects)

groups <- c(rep("CTY132_CON",length(CTY132_CON$Erg_Objects)),
           rep("CTY132_DTT",length(CTY132_DTT$Erg_Objects)),
               rep("CTY212_CON",length(CTY212_CON$Erg_Objects)),
                   rep("CTY212_DTT",length(CTY212_DTT$Erg_Objects)))

nup_d <- dunn.test(nupCounts, groups,
                  method = "bonferroni",
               list=TRUE)

nup_d_results <- data.frame(Comparison = nup_d$comparisons,
                            Z = nup_d$Z,
                            P_adjusted = nup_d$P.adjusted)


write_csv(nup_d_results, paste0(dataName,"_nup_count_dunn_results.csv"))


erg_d <- dunn.test(ergCounts, groups,
               method = "bonferroni",
               list=TRUE)

erg_d_results <- data.frame(Comparison = erg_d$comparisons,
                            Z = erg_d$Z,
                            P_adjusted = erg_d$P.adjusted)

write_csv(erg_d_results, paste0(dataName,"_erg_count_dunn_results.csv"))

counts_summ <- counts_mod |>
  group_by(Genotype, Treatment) |>
  summarise(MeanNupPerCell = mean(Nup_Objects),
            SDNupPerCell = sd(Nup_Objects),
            MeanErgPerCell = mean(Erg_Objects),
            SDErgPerCell = sd(Erg_Objects),
            nCells = n())

write_csv(counts_summ, paste0(dataName,"_count_summary.csv"))

