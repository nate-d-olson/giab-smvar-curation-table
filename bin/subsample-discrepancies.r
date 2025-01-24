#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))
suppressPackageStartupMessages(library("tidyverse"))
## increasing number of printed rows
options(pillar.print_max = 50, pillar.print_min = 50)

# Command Line Arguments
## Code based on https://cran.r-project.org/web/packages/argparse/vignettes/argparse.html
## seed
## input SNP and INDEL table path
## output table path
parser <- ArgumentParser()

# specify our desired options
parser$add_argument("-s", "--seed",
  type = "integer", default = 1234,
  help = "Seed for random sampling [default %(default)s]",
  metavar = "number"
)
parser$add_argument("--snp",
  type = "character",
  help = "Path to input SNP.tsv.gz generated by StratoMod"
)
parser$add_argument("--indel",
  type = "character",
  help = "Path to input INDEL.tsv.gz generated by StratoMod"
)
parser$add_argument("--outtable",
  default = "vars_to_curate.tsv", type = "character",
  help = "Path to write table with variants to curate [default %(default)s]"
)
parser$add_argument("--outbed",
  default = "vars_to_curate.bed", type = "character",
  help = "Path to write bed file with variants to curate [default %(default)s]"
)
parser$add_argument("--stratacounts",
  default = "strata_counts.tsv", type = "character",
  help = "Path to write number of variants per strata [default %(default)s]"
)

args <- parser$parse_args()

## Testing arguments
# args <- list(
#   seed = 1234,
#   snp = "SNV.tsv.gz",
#   indel = "INDEL.tsv.gz",
#   outtable = "test.tsv",
#   outbed = "test.bed"
# )

### Start of parsing and annotation code
print("loading files")
snps <- read.delim(
  args$snp,
  stringsAsFactors = FALSE,
  header = TRUE,
  sep = "\t",
  na.strings = c("NA", NA, "NaN")
)

indels <- read.delim(
  args$indel,
  stringsAsFactors = FALSE,
  header = TRUE,
  sep = "\t",
  na.strings = c("NA", NA, "NaN")
)

print("Combining tables and updating classifications")
stratomod_df <- bind_rows(snps, indels) %>%
  ## Penalizing callers for filtering variants IN benchmark (TPs to FNs)
  ## and not penalizing callers for filtering variants NOT IN benchmark (FPs to TNs)
  mutate(
    label = case_when(
      !(VCF_FILTER %in% c("PASS", ".", "")) & label == "tp" ~ "fn",
      !(VCF_FILTER %in% c("PASS", ".", "")) & label == "fp" ~ "tn",
      TRUE ~ label
    )
  ) %>%
  ## excluding TPs and TNs (only including discrepancies)
  filter(label %in% c("fn", "fp")) |>
  ## Defining var_type
  mutate(var_type = if_else(VCF_indel_length == 0, "SNP", "INDEL")) %>%
  ## Converting columns to factors
  mutate(var_type = factor(var_type), label = factor(label)) %>%
  ## Fixing chromosome and GT
  mutate(
    chrom = case_when(
      chrom %in% 1:22 ~ paste0("chr", chrom),
      chrom == 23 ~ "chrX",
      chrom == 24 ~ "chrY",
      TRUE ~ as.character(chrom)
    ),
    VCF_GT = case_when(
      VCF_GT == 1 ~ "0/0",
      VCF_GT == 2 ~ "0/1",
      VCF_GT == 3  ~ "1/1",
      VCF_GT == 4  ~ "1/2",
      VCF_GT == 5  ~ "0|0",
      VCF_GT == 6  ~ "0|1",
      VCF_GT == 7  ~ "1|1",
      VCF_GT == 8  ~ "1|2",
      VCF_GT == 9 ~ "1|0",
      VCF_GT == 10 ~ "2|1",
      VCF_GT == 11 ~ "0/2",
      VCF_GT == 12 ~ "0/3",
      VCF_GT == 13 ~ "0/4",
      VCF_GT == 14 ~ "1/3",
      VCF_GT == 15 ~ "2/3",
      VCF_GT == 16 ~ "2/4",
      VCF_GT == 17 ~ "3/4",
      VCF_GT == 18 ~ "1",
      VCF_GT == 19 ~ "./.",
      VCF_GT == 20 ~ "0|2",
      VCF_GT == 21 ~ "0|3",
      VCF_GT == 22 ~ "1|3",
      VCF_GT == 23 ~ "1/4",
      VCF_GT == 24 ~ "2|0",
      VCF_GT == 25 ~ "2|3",
      VCF_GT == 26 ~ "2|4",
      VCF_GT == 27 ~ "3|0",
      VCF_GT == 28 ~ "3|1",
      VCF_GT == 29 ~ "3|2",
      VCF_GT == 30 ~ "4|1",
      VCF_GT == 31 ~ "4|2",
      VCF_GT == 32 ~ "0/5",
      TRUE ~ as.character(VCF_GT)
    )
  )

print("Annotating Strata")
stratomod_df$strata <- "S19"

difficult_to_map <- (!is.na(stratomod_df$MAP_difficult_100bp) &
  stratomod_df$MAP_difficult_100bp == 1) |
  (!is.na(stratomod_df$MAP_difficult_250bp) &
    stratomod_df$MAP_difficult_250bp == 1) |
  (!is.na(stratomod_df$SEGDUP_count) &
    stratomod_df$SEGDUP_count > 0) |
  (!is.na(stratomod_df$REPMASK_LINE_length) &
    stratomod_df$REPMASK_LINE_length > 0) |
  (!is.na(stratomod_df$REPMASK_LTR_length) &
    stratomod_df$REPMASK_LTR_length > 0) |
  (!is.na(stratomod_df$REPMASK_Satellite_length) &
    stratomod_df$REPMASK_Satellite_length > 0)

homopolymer_longer_than_6bp <-
  (!is.na(stratomod_df$HOMOPOL_A_length) & stratomod_df$HOMOPOL_A_length > 6) |
    (!is.na(stratomod_df$HOMOPOL_T_length) & stratomod_df$HOMOPOL_T_length > 6) |
    (!is.na(stratomod_df$HOMOPOL_G_length) & stratomod_df$HOMOPOL_G_length > 6) |
    (!is.na(stratomod_df$HOMOPOL_C_length) & stratomod_df$HOMOPOL_C_length > 6)

XY_nonPAR <- (stratomod_df$chrom == "chrX" &
  (stratomod_df$chromStart > 2781479 &
    stratomod_df$chromStart < 155701383)) |
  (stratomod_df$chrom == "chrY" &
    (stratomod_df$chromStart > 2781479 & stratomod_df$chromStart <= 56887902))

tandem_repeat <- (!is.na(stratomod_df$TR_count))

# S01: label = FP & VCF_indel_length = 0 (SNP) & IN TR regions
s01_cond <- stratomod_df$label == "fp" &
  stratomod_df$var_type == "SNP" & tandem_repeat

if (nrow(stratomod_df[s01_cond, ]) > 0) {
  stratomod_df[s01_cond, ]$strata <- "S01"
}

# S02: label = FP & VCF_indel_length = 0 (SNP) & NOT IN TR & IN difficult to map regions
s02_cond <- stratomod_df$label == "fp" &
  stratomod_df$var_type == "SNP" &
  !tandem_repeat & difficult_to_map

if (nrow(stratomod_df[s02_cond, ]) > 0) {
  stratomod_df[s02_cond, ]$strata <- "S02"
}

# S03: label = FP & VCF_indel_length = 0 (SNP) & NOT IN TR & NOT IN difficult to map & IN XY non PAR regions
s03_cond <- stratomod_df$strata == "S19" &
  stratomod_df$label == "fp" &
  stratomod_df$var_type == "SNP" &
  !tandem_repeat & !difficult_to_map & XY_nonPAR

if (nrow(stratomod_df[s03_cond, ]) > 0) {
  stratomod_df[s03_cond, ]$strata <- "S03"
}

# S04: label = FP & VCF_indel_length = 0 (SNP) & NOT IN S01, S02, S03 (all other FP SNPs)
s04_cond <- stratomod_df$strata == "S19" &
  stratomod_df$label == "fp" & stratomod_df$var_type == "SNP"

if (nrow(stratomod_df[s04_cond, ]) > 0) {
  stratomod_df[s04_cond, ]$strata <- "S04"
}

# S05: label = FP & !VCF_indel_length = 0 (INDEL) & IN homopolymer > 6bp
s05_cond <- stratomod_df$label == "fp" &
  stratomod_df$var_type == "INDEL" & homopolymer_longer_than_6bp

if (nrow(stratomod_df[s05_cond, ]) > 0) {
  stratomod_df[s05_cond, ]$strata <- "S05"
}

# S06: label = FP & !VCF_indel_length = 0 (INDEL) & NOT IN homopolymer > 6bp & IN tandem repeat region
s06_cond <- stratomod_df$label == "fp" &
  stratomod_df$var_type == "INDEL" &
  !homopolymer_longer_than_6bp & tandem_repeat

if (nrow(stratomod_df[s06_cond, ]) > 0) {
  stratomod_df[s06_cond, ]$strata <- "S06"
}

# S07: label = FP & !VCF_indel_length = 0 (INDEL) & NOT IN homopolymer > 6bp & NOT tandem repeat & IN difficult to map region
s07_cond <- stratomod_df$label == "fp" &
  stratomod_df$var_type == "INDEL" &
  !homopolymer_longer_than_6bp & !tandem_repeat & difficult_to_map

if (nrow(stratomod_df[s07_cond, ]) > 0) {
  stratomod_df[s07_cond, ]$strata <- "S07"
}

# S08: label = FP & !VCF_indel_length = 0 (INDEL) & NOT IN homopolymer > 6bp & NOT IN tandem repeat & NOT IN difficult to map region & IN XY non PAR
s08_cond <- stratomod_df$label == "fp" &
  stratomod_df$var_type == "INDEL" &
  !homopolymer_longer_than_6bp &
  !tandem_repeat & !difficult_to_map & XY_nonPAR

if (nrow(stratomod_df[s08_cond, ]) > 0) {
  stratomod_df[s08_cond, ]$strata <- "S08"
}

# S09: label = FP & !VCF_indel_length = 0 (INDEL) & NOT IN S05, S06, S07, S08 (all other FP INDELS)
s09_cond <- stratomod_df$strata == "S19" &
  stratomod_df$label == "fp" & stratomod_df$var_type == "INDEL"

if (nrow(stratomod_df[s09_cond, ]) > 0) {
  stratomod_df[s09_cond, ]$strata <- "S09"
}

# S10: label = FN & VCF_indel_length = 0 (SNP) & IN TR regions
s10_cond <- stratomod_df$label == "fn" &
  stratomod_df$var_type == "SNP" & tandem_repeat

if (nrow(stratomod_df[s10_cond, ]) > 0) {
  stratomod_df[s10_cond, ]$strata <- "S10"
}

# S11: label = FN & VCF_indel_length = 0 (SNP) & NOT IN TR & IN difficult to map regions
s11_cond <- stratomod_df$label == "fn" &
  stratomod_df$var_type == "SNP" &
  !tandem_repeat & difficult_to_map

if (nrow(stratomod_df[s11_cond, ]) > 0) {
  stratomod_df[s11_cond, ]$strata <- "S11"
}

# S12: label = FN & VCF_indel_length = 0 (SNP) & NOT IN TR & NOT IN difficult to map & IN XY non PAR regions
s12_cond <- stratomod_df$strata == "S19" &
  stratomod_df$label == "fn" &
  stratomod_df$var_type == "SNP" &
  !tandem_repeat & !difficult_to_map & XY_nonPAR

if (nrow(stratomod_df[s12_cond, ]) > 0) {
  stratomod_df[s12_cond, ]$strata <- "S12"
}

# S13: label = FN & VCF_indel_length = 0 (SNP) & NOT IN S10, S11, S12 (all other FN SNPS)
s13_cond <- stratomod_df$strata == "S19" &
  stratomod_df$label == "fn" & stratomod_df$var_type == "SNP"

if (nrow(stratomod_df[s13_cond, ]) > 0) {
  stratomod_df[s13_cond, ]$strata <- "S13"
}

# S14: label = FN & !VCF_indel_length = 0 (INDEL) & IN homopolymer > 6bp
s14_cond <- stratomod_df$label == "fn" &
  stratomod_df$var_type == "INDEL" & homopolymer_longer_than_6bp

if (nrow(stratomod_df[s14_cond, ]) > 0) {
  stratomod_df[s14_cond, ]$strata <- "S14"
}

# S15: label = FN & !VCF_indel_length = 0 (INDEL) & NOT IN homopolymer > 6bp & IN tandem repeat region
s15_cond <- stratomod_df$label == "fn" &
  stratomod_df$var_type == "INDEL" &
  !homopolymer_longer_than_6bp & tandem_repeat

if (nrow(stratomod_df[s15_cond, ]) > 0) {
  stratomod_df[s15_cond, ]$strata <- "S15"
}

# S16: label = FN & !VCF_indel_length = 0 (INDEL) & NOT IN homopolymer > 6bp & NOT IN tandem repeat & IN difficult to map region
s16_cond <- stratomod_df$label == "fn" &
  stratomod_df$var_type == "INDEL" &
  !homopolymer_longer_than_6bp & !tandem_repeat & difficult_to_map

if (nrow(stratomod_df[s16_cond, ]) > 0) {
  stratomod_df[s16_cond, ]$strata <- "S16"
}

# S17: label = FN & !VCF_indel_length = 0 (INDEL) & NOT IN homopolymer > 6bp & NOT IN tandem repeat & NOT IN difficult to map region & IN XY non PAR
s17_cond <- stratomod_df$label == "fn" &
  stratomod_df$var_type == "INDEL" &
  !homopolymer_longer_than_6bp &
  !tandem_repeat & !difficult_to_map & XY_nonPAR

if (nrow(stratomod_df[s17_cond, ]) > 0) {
  stratomod_df[s17_cond, ]$strata <- "S17"
}

# S18: label = FN & !VCF_indel_length = 0 (INDEL) & NOT IN S14 S15, S16, S17 (all other FP INDELS)
s18_cond <- stratomod_df$strata == "S19" &
  stratomod_df$label == "fn" & stratomod_df$var_type == "INDEL"

if (nrow(stratomod_df[s18_cond, ]) > 0) {
  stratomod_df[s18_cond, ]$strata <- "S18"
}

## Strata Count Summary
print(
  stratomod_df %>%
    group_by(strata) %>%
    count()
)

## saving strata counts
stratomod_df |> 
  group_by(strata) |> 
  count() |> 
  write_tsv(file = args$stratacounts)

## Sampling for manual curation ################################################

## Setting seed for reproducibility
if (args$seed) {
  print(paste("Setting seed:", args$seed))
  set.seed(seed = args$seed)
}

# subsetting to discrepancies (FPs and FNs)
subsampled_df <- stratomod_df %>%
  filter(label %in% c("fp", "fn")) %>%
  group_by(strata) %>%
  slice_sample(n = 5, replace = FALSE) %>%
  mutate(to_curate = TRUE)

print(
  subsampled_df %>%
    group_by(strata) %>%
    count()
)

stratomod_anno_df <- left_join(stratomod_df, subsampled_df) %>%
  mutate(to_curate = if_else(is.na(to_curate), FALSE, TRUE))

## sanity check for number of variants sampled per strata
print(
  stratomod_anno_df %>%
    group_by(strata, to_curate) %>%
    count()
)

## Saving Table of Variants to Curate ##########################################
subsampled_df <- subsampled_df %>%
  ungroup() %>%
  mutate(chrom = factor(chrom,
    levels = c(paste0("chr", 1:22), "chrX", "chrY")
  )) %>%
  arrange(chrom, chromStart, chromEnd)

## Tidying table for viewing in miqa

# reducing homopolymer columns
simplified_subsampled_df <- subsampled_df %>%
  mutate(
    across(ends_with("_length"), ~ if_else(is.na(.x), 0, .x)),
    across(ends_with("_count"), ~ if_else(is.na(.x), 0, .x))
  ) |> 
  rowwise() %>%
  ## simplifying HOMOPOL columns
  mutate(
    HOMOPOL_length = max(HOMOPOL_A_length, HOMOPOL_C_length, HOMOPOL_G_length, HOMOPOL_T_length, na.rm = TRUE),
    HOMOPOL_type = case_when(
      HOMOPOL_length == 0 ~ NA,
      HOMOPOL_A_length == HOMOPOL_length ~ "A",
      HOMOPOL_C_length == HOMOPOL_length ~ "C",
      HOMOPOL_G_length == HOMOPOL_length ~ "G",
      HOMOPOL_T_length == HOMOPOL_length ~ "T"
    ),
    HOMOPOL_imperfect_frac = case_when(
      HOMOPOL_A_length == HOMOPOL_length ~ HOMOPOL_A_imperfect_frac,
      HOMOPOL_C_length == HOMOPOL_length ~ HOMOPOL_C_imperfect_frac,
      HOMOPOL_G_length == HOMOPOL_length ~ HOMOPOL_G_imperfect_frac,
      HOMOPOL_T_length == HOMOPOL_length ~ HOMOPOL_T_imperfect_frac
    )
  ) %>%
  select(-matches("HOMOPOL_[ACGT]_")) %>%
  ## simplifying mappability columns
  mutate(mappability = case_when(
    is.na(MAP_difficult_250bp) & is.na(MAP_difficult_100bp) ~ NA,
    is.na(MAP_difficult_100bp) & !is.na(MAP_difficult_250bp) ~ "250bp",
    !is.na(MAP_difficult_100bp) & is.na(MAP_difficult_250bp) ~ "100bp",
    !is.na(MAP_difficult_250bp) & !is.na(MAP_difficult_100bp) ~ "100bp&250bp"
  )) %>%
  select(-starts_with("MAP_difficult")) %>%
  ## cleaning up SegDup columns
  select(-matches("SEGDUP_.*_min") & -matches("SEGDUP_.*_max")) %>%
  ## cleaning up Tandem Repeat columns
  # - keeping count, length, and unit size cols, median value only
  select(!starts_with("TR"), TR_length, TR_count, TR_unit_size_median, TR_identity_median) %>%
  ## Cleaning up REPMASK
  # - removing LINE subtypes
  select(-matches("REPMASK_LINE_.*_length")) %>%
  ## Ordering columns
  select(
    var_type, strata, label, starts_with("chrom"),
    VCF_REF, VCF_ALT, VCF_QUAL, VCF_GQ, VCF_FILTER, VCF_GT,
    starts_with("HOMOPOL"),
    mappability,
    starts_with("SEGDUP"),
    starts_with("TR"),
    VCF_INFO
  ) |>
  ## removing columns that are all NA
  select_if(~ sum(!is.na(.)) > 0) |> 
  ## Converting length and count columns to integers
mutate(
  across(ends_with("_length") | ends_with("_count"), ~ as.integer(.x))
)

simplified_subsampled_df %>%
  ## excluding XYnonPar strata
  filter(!(strata %in% c("S03","S08", "S12", "S17"))) |> 
  write_tsv(file = args$outtable)

subsampled_df %>%
  ungroup() %>%
  filter(!(strata %in% c("S03","S08", "S12", "S17"))) |> 
  select(chrom, chromStart, chromEnd) %>%
  write_tsv(file = args$outbed, col_names = FALSE)

## TODO ########################################################################
# - add print statements for logging

## Future Work
# - configurable strata definitions, potentially data driven based on stratomod or hap.py output
