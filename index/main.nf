process BWA_INDEX {
    tag "${fasta.baseName}"

    input:
    path fasta

    output:
    tuple path(fasta), path("${fasta}.*"), emit: index

    script:
    // bwa picks an algorithm from the reference size on its own; set
    // params.alignment.index_algorithm only to force 'bwtsw' or 'is'.
    def algo_opt = params.alignment?.index_algorithm != null ? "-a ${params.alignment.index_algorithm}" : ''
    def args = task.ext.args ?: ''
    """
    bwa index ${algo_opt} ${args} ${fasta}
    """

    stub:
    """
    touch ${fasta}.amb ${fasta}.ann ${fasta}.bwt ${fasta}.pac ${fasta}.sa
    """
}
