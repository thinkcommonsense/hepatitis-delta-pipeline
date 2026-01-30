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
    input:
    path combined_fasta

    output:
    path "aligned.fasta"

    script:
    """
    mafft $combined_fasta > aligned.fasta
    """
}

process TRIMAL {
    publishDir "results", mode: 'copy'

    input:
    path aligned_fasta

    output:
    path "cleaned_aligned.fasta"
    path "report.html"

    script:
    """
    trimal -in $aligned_fasta -out cleaned_aligned.fasta -htmlout report.html -automated1
    """
}

workflow {
    if (params.in) {
        input_ch = Channel.fromPath("${params.in}/*.fasta")
                          .ifEmpty { error "No fasta files found in ${params.in}" }
        
        combine_out = COMBINE(input_ch.collect())
        align_out = ALIGN(combine_out)
        TRIMAL(align_out)
    } else {
        error "Please provide input directory with --in"
    }
}
