library(tidyverse)

strata_counts_df <- list.files(path = "results/annotate_variants", pattern = "strata_counts.tsv", recursive = TRUE, full.names = TRUE) %>% 
  set_names(str_extract(.,"(?<=annotate_variants/).*(?=/)")) |> 
  map_dfr(read_tsv, .id = "callset") |> 
  pivot_wider(names_from = "callset", values_from = "n", names_repair = "universal")

strata_counts_df
write_tsv(x = strata_counts_df, "strata_counts.tsv")
