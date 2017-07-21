
/* 
 * Proof of concept of a RNAseq pipeline implemented with Nextflow
 */ 

 
/*
 * Default pipeline parameters. They can be overriden on the command line eg. 
 * given `params.foo` specify on the run command line `--foo some_value`.  
 */
 
params.reads = "$baseDir/data/ggal/*_{1,2}.fq"
params.transcriptome = "$baseDir/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa"
params.outdir = "results"

log.info """\
         M I N I S A L M O N   P I P E L I N E    
         =====================================
         transcriptome: ${params.transcriptome}
         reads        : ${params.reads}
         outdir       : ${params.outdir}
         """
         .stripIndent()


transcriptome_file = file(params.transcriptome)
 
Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { reads_ch } 
 

process index {
    tag "$transcriptome_file.simpleName"
    
    input:
    file trans from transcriptome_file
     
    output:
    file 'index' into index_ch

    script:       
    """
    salmon index --threads $task.cpus -t $trans -i index
    """
}
 
 
process quant {
    tag "$pair_id"
    publishDir params.outdir, mode: 'copy'
     
    input:
    file index from index_ch
    set pair_id, file(reads) from reads_ch
 
    output:
    file(pair_id) into quant_ch
 
    script:
    """
    salmon quant --threads $task.cpus --libType=U -i index -r $reads -o $pair_id
    """
}
  

 
workflow.onComplete { 
	println ( workflow.success ? "Done!" : "Oops .. something went wrong" )
}
