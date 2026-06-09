# nf-mod-bwa

Nextflow module for BWA (index + mem). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-bwa:latest`

## :gear: Processes

- `BWA_INDEX` — input: `path fasta` → output: `tuple(fasta, index_files)`
- `BWA_MEM`   — inputs: `tuple(sample, r1, r2)` + `tuple(fasta, index_files)` → output: `tuple(sample, sam)`

## :hammer_and_wrench: Use as submodule
```bash
git submodule add https://github.com/eit-gbi/nf-mod-bwa.git modules/bwa
```

Then in your pipeline:
```
include { BWA_INDEX } from './modules/bwa/index/main.nf'
include { BWA_MEM }   from './modules/bwa/mem/main.nf'
```
