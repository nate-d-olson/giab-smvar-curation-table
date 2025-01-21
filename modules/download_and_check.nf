process DOWNLOAD_AND_CHECK {
    conda "conda-forge::wget=1.20.3 conda-forge::coreutils=9.5"

    input:
    val repeats_bed_url
    val repeats_bed_md5
    val mat_chain_url
    val mat_chain_md5
    val pat_chain_url
    val pat_chain_md5

    output:
    path "GRCh38_AllTandemRepeatsandHomopolymers_slop5.bed.gz", emit: repeats_bed
    path "GRCh38_to_hg002v1.1.mat.chain.gz", emit: mat_chain
    path "GRCh38_to_hg002v1.1.pat.chain.gz", emit: pat_chain

    script:
    """
    wget -O GRCh38_AllTandemRepeatsandHomopolymers_slop5.bed.gz "${repeats_bed_url}"
    wget -O GRCh38_to_hg002v1.1.mat.chain.gz "${mat_chain_url}"
    wget -O GRCh38_to_hg002v1.1.pat.chain.gz "${pat_chain_url}"

    # Check MD5 if provided
    if [ ! -z "${repeats_bed_md5}" ]; then
        echo "${repeats_bed_md5}  GRCh38_AllTandemRepeatsandHomopolymers_slop5.bed.gz" | md5sum -c
    fi

    if [ ! -z "${mat_chain_md5}" ]; then
        echo "${mat_chain_md5}  GRCh38_to_hg002v1.1.mat.chain.gz" | md5sum -c
    fi

    if [ ! -z "${pat_chain_md5}" ]; then
        echo "${pat_chain_md5}  GRCh38_to_hg002v1.1.pat.chain.gz" | md5sum -c
    fi
    """
}