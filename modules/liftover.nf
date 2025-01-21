process LIFTOVER {
    tag "${callset}"
    conda "bioconda::ucsc-liftover=377"

    input:
    tuple val(callset), path(igv_regions_bed)
    path mat_chain
    path pat_chain

    output:
    tuple val(callset), path("${callset}_HG002mat_regions.bed"), emit: mat_bed
    tuple val(callset), path("${callset}_HG002mat_unlifted.bed"), emit: mat_unlifted
    tuple val(callset), path("${callset}_HG002pat_regions.bed"), emit: pat_bed
    tuple val(callset), path("${callset}_HG002pat_unlifted.bed"), emit: pat_unlifted
    
    script:
    """
    liftOver ${igv_regions_bed} ${mat_chain} ${callset}_HG002mat_regions.bed ${callset}_HG002mat_unlifted.bed -minMatch=0.1 -bedPlus=3 
    liftOver ${igv_regions_bed} ${pat_chain} ${callset}_HG002pat_regions.bed ${callset}_HG002pat_unlifted.bed -minMatch=0.1 -bedPlus=3
    """
}