nextflow.enable.dsl=2
//download fasta from ncbi using accession number
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
// combinig process. 
process COMBINE {
    input:
    path fastas

    output:
    path "combined.fasta"
// don't know if this is a standard 
    script:
    """
    cat $fastas > combined.fasta
    """
}
// alignment
process ALIGN {
    input:
    path combined_fasta

    output:
    path "aligned.fasta"
// mafft can be annoying. Be careful!
    script:
    """
    mafft $combined_fasta > aligned.fasta
    """
}
// again, trimal tool is something that need care
process TRIMAL {
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

        // Mix and collect
        all_fastas = input_ch.mix(ref_ch).collect()
        
        combine_out = COMBINE(all_fastas)
        align_out = ALIGN(combine_out)
        TRIMAL(align_out)
    } else {
        error "Please provide input directory with --in"
    }
}
