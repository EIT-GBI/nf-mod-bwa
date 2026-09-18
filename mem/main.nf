process BWA_MEM {
    tag "${meta.id}"
    

    input:
    tuple val(meta), path(r1), path(r2)
    tuple path(fasta), path(index_files)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    // PL comes in on the sample's meta, so a run that is not Illumina records
    // the right platform instead of a wrong one. It is read from meta rather
    // than params because a single run can mix platforms, and because modules
    // here take their inputs from the channel, not from the pipeline's params.
    def platform = meta.platform ?: 'ILLUMINA'
    def args = task.ext.args ?: ''
    """
    bwa mem \\
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
