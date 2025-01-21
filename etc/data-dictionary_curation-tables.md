# Data Dictionary

| Column Name                | Data Type | Description |
|----------------------------|-----------|-------------|
| chrom                      | String    | Chromosome identifier in the format 'chrN' (e.g., chr1, chrX). |
| chromStart                 | Integer   | Start position of the variant on the chromosome (0-based). |
| chromEnd                   | Integer   | End position of the variant on the chromosome (1-based). |
| var_type                   | String    | Variant type, typically "SNP" (Single Nucleotide Polymorphism) or "INDEL" (Insertion/Deletion). |
| strata                     | String    | Stratum or category of the variant. |
| label                      | String    | Label indicating the variant's status, such as false positive (fp) or false negative (fn). |
| VCF_REF                    | String    | Reference allele in the VCF format. |
| VCF_ALT                    | String    | Alternate allele in the VCF format. |
| VCF_QUAL                   | Float     | Quality score of the variant in the VCF format. |
| VCF_GQ                     | Float     | Genotype Quality score, representing the confidence of the genotype call. |
| VCF_FILTER                 | String    | Filter status of the variant in the VCF format. Frequently seen as "." for unfiltered or "PASS". |
| VCF_GT                     | String    | Genotype information in the VCF format. |
| HOMOPOL_length             | Integer   | Length of homopolymer sequence nearby, used in indel context. |
| HOMOPOL_type               | String    | Type of homopolymer sequence (e.g., type 'T'). |
| HOMOPOL_imperfect_frac     | Float     | Fraction of nearby homopolymers that are imperfect. |
| mappability                | Integer   | Score representing the mappability of the sequence region. |
| SEGDUP_count               | Integer   | Number of segmental duplications overlapping the variant. |
| SEGDUP_size_mean           | Integer   | Mean size of the segmental duplications overlapping the variant. |
| SEGDUP_identity_mean       | Float     | Mean identity of the segmental duplications overlapping the variant. |
| TR_length                  | Integer   | Length of any tandem repeat sequences overlapping the variant. |
| TR_count                   | Integer   | Count of tandem repeats in the region. |
| TR_unit_size_median        | Float     | Median unit size of the tandem repeats overlapping the variant. |
| TR_identity_median         | Float     | Median identity of the tandem repeat sequences overlapping the variant. |
| VCF_INFO                   | String    | Additional information from the VCF format, potentially including annotations such as 'TRF'. |

### Categorical Values

- **var_type**
  - SNP: Single Nucleotide Polymorphism
  - INDEL: Insertion/Deletion

- **label**
  - fp: False positive variant call
  - fn: False negative variant call

- **VCF_FILTER**
  - .: Unfiltered
  - PASS: Passed all filters applied

- **strata**
  - S01: False positive SNPs in tandem repeat regions.
  - S02: False positive SNPs not in tandem repeats, but in difficult-to-map regions.
  - S03: False positive SNPs not in tandem repeats or difficult regions, in non-PAR X/Y regions.
  - S04: All other false positive SNPs not in S01, S02, or S03.
  - S05: False positive INDELs in homopolymer regions > 6bp.
  - S06: False positive INDELs not in homopolymer, but in tandem repeats.
  - S07: False positive INDELs not in homopolymer/tandem repeats, in difficult regions.
  - S08: False positive INDELs not in homopolymer/tandem/difficult regions, in non-PAR X/Y.
  - S09: All other false positive INDELs not in S05, S06, S07, or S08.
  - S10: False negative SNPs in tandem repeat regions.
  - S11: False negative SNPs not in tandem repeats, but in difficult regions.
  - S12: False negative SNPs not in tandem/difficult regions, in non-PAR X/Y regions.
  - S13: All other false negative SNPs not in S10, S11, or S12.
  - S14: False negative INDELs in homopolymer regions > 6bp.
  - S15: False negative INDELs not in homopolymer, but in tandem repeats.
  - S16: False negative INDELs not in homopolymer/tandem repeats, in difficult regions.
  - S17: False negative INDELs not in homopolymer/tandem/difficult regions, in non-PAR X/Y.
  - S18: All other false negative INDELs not in S14, S15, S16, or S17.