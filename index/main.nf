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
