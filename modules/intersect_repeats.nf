process INTERSECT_REPEATS {
    tag "${callset}"
    conda "bioconda::bedtools=2.30.0"

    input:
    tuple val(callset), path(curation_bed)
    path repeats_bed

    output:
    tuple val(callset), path("${callset}_repeat_anno.bed")

    script:
    """
    bedtools intersect -loj -a ${curation_bed} -b ${repeats_bed} > ${callset}_repeat_anno.bed
    """
}