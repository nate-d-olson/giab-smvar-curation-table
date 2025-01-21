process ANNOTATE_VARIANTS {
    tag "${callset}"
    
    conda "r-base=4.1 r-tidyverse=1.3 r-argparse=2.1"

    input:
    tuple val(callset), path(snp_input), path(indel_input), val(seed)

    output:
    tuple val(callset), path("${callset}_vars_to_curate.tsv"), emit: curation_tsv
    tuple val(callset), path("${callset}_curation.bed"), emit: curation_bed

    script:
    """
    Rscript ${projectDir}/bin/subsample-discrepancies.r \
        --snp ${snp_input} --indel ${indel_input} \
        --outtable ${callset}_vars_to_curate.tsv \
        --outbed ${callset}_curation.bed \
        --seed ${seed}
    """
}