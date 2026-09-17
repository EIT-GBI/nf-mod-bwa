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

Flags are passed through `task.ext.args` (and `args2`/`args3` where a process
runs more than one command) rather than read from pipeline `params`, so the
module never depends on a particular pipeline's parameter names:

```groovy
process {
    withName: BWA_INDEX {
        ext.args = '--some-flag'
    }
}
```

`BWA_MEM` composes its own `@RG` read group from the sample's `meta`: `meta.id`
becomes `ID`, `SM` and `LB`, and `meta.platform` becomes `PL`, defaulting to
`ILLUMINA` when unset. Setting it per sample means one run can mix platforms.

```groovy
channel.of([[id: 'sample1', platform: 'OXFORD_NANOPORE'], r1, r2])
// -> @RG\tID:sample1\tSM:sample1\tPL:OXFORD_NANOPORE\tLB:sample1
```

Do not pass `-R` through `ext.args` to override this: bwa accepts a second `-R`
and silently keeps the last one, so the two read groups would not conflict
loudly, and the override would have to restate `ID`, `SM` and `LB` as well.

Tuning flags go through `ext.args`:

```groovy
process {
    withName: BWA_MEM {
        ext.args = '-k 25 -T 40'
    }
}
```

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
in a `setup` block to get a real index, and `tests-args.config` adds tuning
flags through `ext.args`.

The `BWA_MEM` snapshots use read-level checksums via `nft-bam` rather than the
BAM checksum: bwa and samtools each write their command line into an `@PG`
header line, and samtools records `-@ task.cpus` there, so the file checksum
moves whenever the config does. The read group and bwa's own `@PG` record are
asserted directly.

Note that `-T` does not change how many reads are in the output: bwa emits
low-scoring reads as unmapped rather than dropping them. What moves is mapping
quality, so that is what the tests assert on - 60/60 min/mean with bwa's
defaults against 48/59 at `-k 25 -T 40`.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
