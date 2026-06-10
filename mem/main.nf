process BWA_MEM {
    tag "${sample}"

    input:
    tuple val(sample), path(r1), path(r2)
    tuple path(fasta), path(index_files)

    output:
    tuple val(sample), path("${sample}.sam"), emit: sam

    script:
    def args = task.ext.args ?: ''
    """
    bwa mem \\
        ${args} \\
        -t ${task.cpus} \\
        ${fasta} \\
        ${r1} \\
        ${r2} \\
        > ${sample}.sam
    """
}
