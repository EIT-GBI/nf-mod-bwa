process BWA_MEM {
    tag "${meta.id}"
    

    input:
    tuple val(meta), path(r1), path(r2)
    tuple path(fasta), path(index_files)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    // Alignment settings belong to the module rather than the consuming
    // pipeline: every pipeline sets the same params.alignment.* names and the
    // bwa flags are assembled here, once.
    //
    // params.alignment.device is NOT one of these. It selects whether bwa runs
    // at all, or Parabricks instead, which is the pipeline's routing decision
    // rather than a bwa setting.
    def platform  = params.alignment?.platform ?: 'ILLUMINA'
    def seed_opt  = params.alignment?.min_seed_length != null ? "-k ${params.alignment.min_seed_length}" : ''
    def score_opt = params.alignment?.min_score      != null ? "-T ${params.alignment.min_score}"      : ''
    def args = task.ext.args ?: ''
    """
    bwa mem \\
        ${seed_opt} \\
        ${score_opt} \\
        ${args} \\
        -R "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:${platform}\\tLB:${meta.id}" \\
        -t ${task.cpus} \\
        ${fasta} \\
        ${r1} \\
        ${r2} \\
        | samtools sort -@ ${task.cpus} \\
            -o ${meta.id}.sorted.bam
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    """
}
