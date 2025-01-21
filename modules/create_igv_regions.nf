process CREATE_IGV_REGIONS {
    tag "${callset}"

    input:
    tuple val(callset), path(repeat_anno_bed)

    output:
    tuple val(callset), path("${callset}_GRCh38_igv_regions.bed")

    script:
    """
    awk '{FS=OFS="\t"} {if (\$4 == ".") print \$1, \$2-20, \$3+20, \$1, \$2-20, \$3+20, \$1, \$2, \$3; else print \$1, \$(NF-1), \$NF,  \$1, \$(NF-1), \$NF,\$1, \$2, \$3}' ${repeat_anno_bed} > ${callset}_GRCh38_igv_regions.bed
    """
}