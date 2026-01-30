nextflow.enable.dsl=2

params.in = "$projectDir/requisites/hepatitis"

process COMBINE {
    input:
    path fastas

    output:
    path "combined.fasta"

    script:
    """
    cat $fastas > combined.fasta
    """
}

process ALIGN {
    publishDir "results", mode: 'copy'

    input:
    path combined_fasta

    output:
    path "aligned.fasta"

    script:
    """
    mafft $combined_fasta > aligned.fasta
    """
}

workflow {
    if (params.in) {
        input_ch = Channel.fromPath("${params.in}/*.fasta")
                          .ifEmpty { error "No fasta files found in ${params.in}" }
        
        combine_out = COMBINE(input_ch.collect())
        ALIGN(combine_out)
    } else {
        error "Please provide input directory with --in"
    }
}
