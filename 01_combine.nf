nextflow.enable.dsl=2

params.in = "$projectDir/requisites/hepatitis"

process COMBINE {
    publishDir "results", mode: 'copy'

    input:
    path fastas

    output:
    path "combined.fasta"

    script:
    """
    cat $fastas > combined.fasta
    """
}

workflow {
    if (params.in) {
        // Create a channel from the input pattern
        // We assume the user provides a directory path
        input_ch = Channel.fromPath("${params.in}/*.fasta")
                          .ifEmpty { error "No fasta files found in ${params.in}" }
        
        COMBINE(input_ch.collect())
    } else {
        error "Please provide input directory with --in"
    }
}
