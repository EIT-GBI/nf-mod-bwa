# nf-mod-bwa

Nextflow module for BWA (read alignment (index + mem)). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-bwa:v0.0.0`

## Processes

Each subtool lives in its own folder (nf-core style), with a `main.nf`, a
`meta.yml` and an nf-test case under `tests/`.

| Process | Path | Inputs | Emits |
| --- | --- | --- | --- |
| `BWA_INDEX` | `index/main.nf` | `path fasta` | `index` |
| `BWA_MEM` | `mem/main.nf` | `tuple val(meta), path(r1), path(r2)`<br>`tuple path(fasta), path(index_files)` | `bam` |

## Publishing

These processes do **not** publish their own outputs. Publishing is the
consuming pipeline's job, via a workflow `output {}` block. This keeps the
module reusable across pipelines that want different result layouts.

## Tool arguments

Extra tool flags are passed through `task.ext.args` (and `args2`/`args3` where a
process runs more than one command):

```groovy
process {
    withName: BWA_INDEX {
        ext.args = '--some-flag'
    }
}
```

## Module-owned parameters

Where a setting is a property of what the module *does* rather than of a
particular pipeline, the module owns it: it declares the `params` names and
builds the tool invocation from them, so every consuming pipeline configures it
the same way instead of each one re-deriving the same flags.

| Param | Process | Becomes |
| --- | --- | --- |
| `params.alignment.platform` | `BWA_MEM` | `PL:` in the `@RG` read group (default `ILLUMINA`) |
| `params.alignment.min_seed_length` | `BWA_MEM` | `-k <value>` |
| `params.alignment.min_score` | `BWA_MEM` | `-T <value>` |
| `params.alignment.index_algorithm` | `BWA_INDEX` | `-a <value>`, to force `bwtsw` or `is` |

```groovy
params {
    alignment {
        platform        = 'ILLUMINA'
        min_seed_length = 19
        min_score       = 30
    }
}
```

Each may be left unset, which drops that flag; `platform` falls back to
`ILLUMINA`, which is what the read group was hardcoded to before these params
existed. A pipeline that sets none of them keeps its previous behaviour.

`params.alignment.device` is **not** one of these, and stays with the consuming
pipeline. It selects whether `BWA_MEM` runs at all or another aligner does,
which is a routing decision about the pipeline rather than a setting for bwa.
The module never reads it.

Do **not** declare defaults for these in `conf/module.config`. Pipelines
normally `includeConfig` that file *after* their own `params` block, so a
default there would silently overwrite whatever the pipeline had set.

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-bwa.git modules/bwa
git -C modules/bwa checkout v0.0.0
```

Then include the module's container config from your `nextflow.config`. Nextflow
does not read a submodule's config on its own, so without this line the
processes have no image:

```groovy
includeConfig 'modules/bwa/conf/module.config'
```

`conf/module.config` pins the image to the version built from this same commit,
and carries no `manifest {}` block, so it will not overwrite your pipeline's
own manifest. Override it in your pipeline with a `withName` selector if needed.

And include the processes:

```groovy
include { BWA_INDEX } from './modules/bwa/index/main.nf'
include { BWA_MEM } from './modules/bwa/mem/main.nf'
```

## Requirements

Nextflow 26.04.4 or newer.

## Tests

`nf-test test`. Each process has a stub test covering wiring and output names,
and tests that run bwa for real against `ghcr.io/eit-gbi/nf-mod-bwa:latest` and
snapshot what comes out. The real tests need Docker. `BWA_MEM` runs `BWA_INDEX`
in a `setup` block to get a real index.

The `BWA_MEM` snapshots use read-level checksums via `nft-bam` rather than the
BAM checksum: bwa and samtools each write their command line into an `@PG`
header line, and samtools records `-@ task.cpus` there, so the file checksum
moves whenever the config does. The read group and bwa's own `@PG` record are
asserted directly, which pins the params to the flags they produce.

Note that `-T` does not change how many reads are in the output: bwa emits
low-scoring reads as unmapped rather than dropping them. What moves is mapping
quality, so that is what the tests assert on.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
