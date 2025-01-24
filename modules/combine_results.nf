process COMBINE_RESULTS {
    tag "${callset}"

    input:
    tuple val(callset), path(curation_tsv), path(mat_bed), path(pat_bed)

    output:
    tuple val(callset), path("${callset}_curation_table.tsv")

    script:
    println "COMBINE_RESULTS input: callset=${callset}, curation_tsv=${curation_tsv}, mat_bed=${mat_bed}, pat_bed=${pat_bed}"
    """
    #!/usr/bin/env python3
    import pandas as pd

    # Read input files
    curation_df = pd.read_csv("${curation_tsv}", sep="\t").set_index(
        ["chrom", "chromStart", "chromEnd"]
    )
    mat_df = (
        pd.read_csv(
            "${mat_bed}",
            sep="\t",
            header=None,
            names=[
                "mat_chr",
                "mat_start",
                "mat_end",
                "GRCh38_chr",
                "GRCh38_start",
                "GRCh38_end",
                "chrom",
                "chromStart",
                "chromEnd",
            ],
        )
        .set_index(
            ["GRCh38_chr", "GRCh38_start", "GRCh38_end", "chrom", "chromStart", "chromEnd"]
        )
        .astype({"mat_start": "str", "mat_end": "str"})
    )
    pat_df = (
        pd.read_csv(
            "${pat_bed}",
            sep="\t",
            header=None,
            names=[
                "pat_chr",
                "pat_start",
                "pat_end",
                "GRCh38_chr",
                "GRCh38_start",
                "GRCh38_end",
                "chrom",
                "chromStart",
                "chromEnd",
            ],
        )
        .set_index(
            ["GRCh38_chr", "GRCh38_start", "GRCh38_end", "chrom", "chromStart", "chromEnd"]
        )
        .astype({"pat_start": "str", "pat_end": "str"})
    )

    # Merge dataframes
    print(f"callset tsv has dimensions: {curation_df.shape}")
    print(f"maternal liftover bed has dimensions: {mat_df.shape}")
    print(f"paternal liftover bed has dimensions: {pat_df.shape}")
    merged_df = pat_df.join(mat_df, how="outer")
    print(f"Intermediate merged df has dimensions: {merged_df.shape}")
    if curation_df.shape[0] != merged_df.shape[0]:
        print("Intermediate merged TSV and input callset TSV have different number of rows")

    final_df = curation_df.join(merged_df, how="outer")
    print(f"final TSV has dimensions: {final_df.shape}")
    if curation_df.shape[0] != final_df.shape[0]:
        print("Final TSV and input callset TSV have different number of rows")

    # Save final table
    final_df.to_csv("${callset}_curation_table.tsv", sep="\t", index=True)
    """
}