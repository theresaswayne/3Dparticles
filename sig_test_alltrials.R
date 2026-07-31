# commands for testing significance of differences between groups

# assumes a dataframe "trials" in tidy format:
# Columns = replicate, condition, value


require(tidyverse)
require(ggplot2)
require(dunn.test)
require(rstatix) # dunn_test
require(broom)
require(ggpubr)

# Name of the dataset

dataName = "PercentInContact"

# ---- Hypothesis testing ----

# statistical comparison of distributions using non-parametric Kolgomorov-Smirnov test
# with Dunn's test for multiple comparisons

x <- trials$PctInContact # the values
g <- trials$Condition # the groups

# kw test will tell if there are any significant differences
kw <- kruskal.test(x ~ g, data = trials)

# format the list as a table and save
kw |> broom::tidy() |> readr::write_csv(paste0(dataName,"_kw.csv"))


# Note: Default of dunn.test is one sided; use the altp = TRUE option to get a 2-sided p value
# https://github.com/kassambara/rstatix/issues/50
#https://stats.stackexchange.com/questions/160634/dunns-test-p-values-in-r-are-exactly-half-those-in-spss-and-graphpad-for-the-sa


# using the dunn.test package
d_two <- dunn.test(x, g,
               method = "bonferroni",
               list=TRUE,
               altp = TRUE)

d_two_results <- data.frame(Comparison = d_two$comparisons, P_adjusted = d_two$altP.adjusted)
write_csv(d_two_results, paste0(dataName,"_2sided_dunn.test_results.csv"))

d_one <- dunn.test(x, g,
                   method = "bonferroni",
                   list=TRUE)

d_one_results <- data.frame(Comparison = d_one$comparisons, P_adjusted = d_one$P.adjusted)
write_csv(d_two_results, paste0(dataName,"_1sided_dunn.test_results.csv"))

# using the rstatix dunn_test function
trials_summ <- trials |> group_by(Condition) |>
  get_summary_stats(PctInContact, type = "mean_sd")
write_csv(trials_summ, paste0(dataName,"_trials_summary.csv"))

d_rstatix <- trials %>% dunn_test(PctInContact ~ Condition)
write_csv(d_rstatix, paste0(dataName,"_rstatix_dunn_results.csv"))

# pairwise tests
wt_con <- trials %>% filter(Condition == "WT Control") %>% select(PctInContact) %>% pull()
wt_dtt <- trials %>% filter(Condition == "WT DTT") %>% select(PctInContact)  %>% pull()
c5_con <- trials %>% filter(Condition == "cue5del Control") %>% select(PctInContact)  %>% pull()
c5_dtt <- trials %>% filter(Condition == "cue5del DTT") %>% select(PctInContact)  %>% pull()

w_wt <- wilcox.test(wt_con, wt_dtt)
w_c5 <- wilcox.test(c5_con, c5_dtt)
# format the list as a table
w_wt <- w_wt |> broom::tidy()
w_c5 <- w_c5 |> broom::tidy()

w_combined <- rbind(w_wt, w_c5)
w_combined <- w_combined %>% 
  mutate(Comparison = c("WT Control vs DTT", "cue5del Control vs DTT"), .before=statistic)

write_csv(w_combined, paste0(dataName,"_wilcoxon.csv"))

