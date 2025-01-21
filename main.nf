#!/usr/bin/env nextflow

include { DOWNLOAD_AND_CHECK } from './modules/download_and_check'
include { ANNOTATE_VARIANTS } from './modules/annotate_variants'
include { INTERSECT_REPEATS } from './modules/intersect_repeats'
include { CREATE_IGV_REGIONS } from './modules/create_igv_regions'
include { LIFTOVER } from './modules/liftover'
include { COMBINE_RESULTS } from './modules/combine_results'


workflow {
    println "Starting pipeline"
    // Input channels
    Channel
        .fromPath(params.callset_csv)
        .splitCsv(header:true)
        .map { row -> 
            if (!file(row.snp).exists()) {
                error "SNP file not found: ${row.snp}"
            }
            if (!file(row.indel).exists()) {
                error "INDEL file not found: ${row.indel}"
            }
            tuple(row.callset, file(row.snp), file(row.indel), row.seed)
        }
        .set { callset_ch }

    println "Channel created: ${callset_ch.dump()}"

    // Download and check reference files
    DOWNLOAD_AND_CHECK(
        params.repeats_bed.url,
        params.repeats_bed.md5,
        params.mat_chain.url,
        params.mat_chain.md5,
        params.pat_chain.url,
        params.pat_chain.md5
    )
    println "Before ANNOTATE_VARIANTS"
    // Annotate variants
    ANNOTATE_VARIANTS(callset_ch)
    println "After ANNOTATE_VARIANTS"
    // Intersect with repeats
    INTERSECT_REPEATS(ANNOTATE_VARIANTS.out.curation_bed, DOWNLOAD_AND_CHECK.out.repeats_bed)

    // Create IGV regions
    CREATE_IGV_REGIONS(INTERSECT_REPEATS.out)

    // LiftOver to maternal and paternal haplotypes
    LIFTOVER(CREATE_IGV_REGIONS.out, DOWNLOAD_AND_CHECK.out.mat_chain, DOWNLOAD_AND_CHECK.out.pat_chain)

    // Combine results
    COMBINE_RESULTS(ANNOTATE_VARIANTS.out.curation_tsv, LIFTOVER.out.mat_bed, LIFTOVER.out.pat_bed)
}