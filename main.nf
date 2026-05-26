process BWA_INDEX {
    tag "${fasta.baseName}"

    input:
    path fasta

    output:
    tuple path(fasta), path("${fasta}.*"), emit: index

    script:
    """
    bwa index ${fasta}
    """
}

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

// process BWA_MEM {
//     debug true

//     input:
//     tuple val(sample), path(r1), path(r2)
//     tuple path(reference_fasta), path(reference_index_files)
 
 
//     output:
//     tuple val(sample), val(4)
//     // tuple val(sample), path("${sample}.bam"), emit: bam

//     script:
//     """
//     echo "Running BWA MEM for sample ${sample}"
//     echo "Reference FASTA: ${reference_fasta}"
//     echo "R1: ${r1}"
//     echo "R2: ${r2}"
//     echo "EXTRA ARGS: ${task.ext.args}"
//     """
// }