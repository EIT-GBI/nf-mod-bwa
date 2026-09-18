process BWA_INDEX {
    tag "${fasta.baseName}"

    input:
    path fasta

    output:
    tuple path(fasta), path("${fasta}.*"), emit: index

    script:
    def args = task.ext.args ?: ''
    """
    bwa index ${args} ${fasta}
    """

    stub:
    """
    touch ${fasta}.amb ${fasta}.ann ${fasta}.bwt ${fasta}.pac ${fasta}.sa
    """
}
