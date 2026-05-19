# nf-mod-bwa

Nextflow module for BWA (index + mem). Used as a git submodule by pipelines.

Image: `somewhere on the GBI-EIT page`

## Processes

- `BWA_INDEX` — input: `path fasta` → output: `tuple(fasta, index_files)`
- `BWA_MEM`   — inputs: `tuple(sample, r1, r2)` + `tuple(fasta, index_files)` → output: `tuple(sample, sam)`

## Use as submodule
```bash
git submodule add https://github.com/CristiSoitu/nf-mod-bwa.git modules/bwa
```

Then in your pipeline:
```groovy
include { BWA_INDEX; BWA_MEM } from './modules/bwa/main.nf'
```
