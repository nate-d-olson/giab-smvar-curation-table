# GIAB Small Variant Curation Table

Nextflow pipeline to generate tables list of variants for manual curation as
part of the GIAB draft benchmark external evaluation process.

Running pipeline in `nfenv` mamba environment, has nextflow and python dependencies installed.

```bash
nextflow run \
    -with-dag -with-report \
    --config nextflow.config \
    main.nf 
```