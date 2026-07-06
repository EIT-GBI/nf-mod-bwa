process BWA_MEM {
    tag "${meta.id}"
    
    // publishDir "${params.outdir}/bam", mode: 'link', pattern: "*.sorted.bam"

    input:
    tuple val(meta), path(r1), path(r2)
    tuple path(fasta), path(index_files)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    bwa mem \\
        ${args} \\        
        -R "@RG\\tID:${meta.id}\\tSM:${meta.id}\\tPL:ILLUMINA\\tLB:${meta.id}" \\
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
