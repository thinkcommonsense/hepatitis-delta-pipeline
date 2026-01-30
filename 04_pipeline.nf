nextflow.enable.dsl=2

params.in = "$projectDir/requisites/hepatitis"
params.accession = "M21012"

process DOWNLOAD_REFERENCE {
    input:
    val accession

    output:
    path "${accession}.fasta"

    script:
    """
    esearch -db nucleotide -query "${accession}" | efetch -format fasta > "${accession}.fasta"
    """
}

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
        
        // Download reference
        ref_ch = DOWNLOAD_REFERENCE(params.accession)

        // Mix local files with reference and collect them all
        // We use mix() to combine the streams, then collect() to gather them into a list for COMBINE
        all_fastas = input_ch.mix(ref_ch).collect()
        
        combine_out = COMBINE(all_fastas)
        align_out = ALIGN(combine_out)
        TRIMAL(align_out)
    } else {
        error "Please provide input directory with --in"
    }
}
