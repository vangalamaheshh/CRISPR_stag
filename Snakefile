# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

from collections import defaultdict

file_info = defaultdict(dict)

with open("metasheet.csv", "r") as fh:
    next(fh)
    for line in fh:
        info = line.strip().split(",")
        file_info[info[0]] = {"barcode": info[1].upper(), "universal_primer": info[2].upper(), "input_file": info[3], "lib_type": info[4]}

lib_info = {
    "Human_A": "/zfs/cores/mbcf/mbcf-storage/devel/umv/ref_files/human/Homo_sapiens/CRISPR/Gecko/Human_GeCKOv2_Library_A_09Mar2015",
    "Human_B": "/zfs/cores/mbcf/mbcf-storage/devel/umv/ref_files/human/Homo_sapiens/CRISPR/Gecko/Human_GeCKOv2_Library_B_09Mar2015"
};

def get_file_names( wildcards ):
    file_list = []
    for sample in file_info.keys():
        file_list.extend( ["analysis/demultiplex/full_seq/" + sample + "/" + sample + ".fastq.gz","analysis/demultiplex/sgRNA/" + sample + "/" + sample + ".fastq.gz"] )
    return file_list

def csv2fa( wildcards ):
    fa_list = []
    for lib in lib_info.keys():
        fa_list.append( lib_info[lib] + ".fa" )
        fa_list.append( lib_info[lib] + ".nodups.fa" )
    return fa_list

def bowtie_index_paths( wildcards ):
    bowtie_index_paths=[]
    for lib in lib_info.keys():
        bowtie_index_paths.append( lib_info[lib] + "_bowtie_index/" )
    return bowtie_index_paths

rule target:
    input:
        get_file_names
#        csv2fa,
#        bowtie_index_paths,
#        expand( "analysis/bowtie_align/{sample}.bowtie.out", sample=file_info.keys() ),
#        "analysis/align_report.csv"

rule demultiplex:
    input:
        lambda wildcards: "concat_per_sample_fastq/" + file_info[wildcards.sample]["input_file"]
    output:
        out_file_20_bases="analysis/demultiplex/sgRNA/{sample}/{sample}.fastq.gz",
        out_file_full_seq="analysis/demultiplex/full_seq/{sample}/{sample}.fastq.gz"
    params:
        universal_primer=lambda wildcards: file_info[wildcards.sample]["universal_primer"],
        barcode=lambda wildcards: file_info[wildcards.sample]["barcode"]
    shell:
        "zcat {input} | perl CRISPR_stag/scripts/fetch_stag_seqs.pl --out_file_20_bases {output.out_file_20_bases} --out_file_full_seq {output.out_file_full_seq} --universal_primer {params.universal_primer} --barcode {params.barcode}"

rule csv_to_fasta:
    input:
        "{file}.csv"
    output:
        "{file}.fa"
    shell:
        "sed -ne \"2,$ p\" {input} | gawk 'BEGIN {{OFS=\";\"}}{{print \">\"$1,$2,$3; print $3; }}' 1>{output}"


rule remove_dups:
    input:
        "{file}.fa"
    output:
        "{file}.nodups.fa"
    log:
        "{file}.nodups.log"
    shell:
        "perl CRISPR_stag/scripts/remove_dups_and_revComps.pl --ref_fasta {input} 1>{output} 2>{log}"

rule create_bowtie_index:
    input:
        ref_fa_file="{file_path}.nodups.fa"
    output:
        index_dir="{file_path}_bowtie_index/"
    shell:
        "/zfs/cores/mbcf/mbcf-storage/devel/umv/software/bowtie/bowtie-1.0.1/bowtie-build {input.ref_fa_file} {output.index_dir}/crispr"


rule bowtie_align:
    input:
        bowtie_index= lambda wildcards: lib_info[file_info[wildcards.sample]["lib_type"]] + "_bowtie_index",
        fastq_file="analysis/demultiplex/sgRNA/{sample}/{sample}.fastq.gz"
    output:
        "analysis/bowtie_align/{sample}.bowtie.out"
    log:
        "analysis/bowtie_align/{sample}.bowtie.log"
    threads: 8
    shell:
        "zcat {input.fastq_file} | /zfs/cores/mbcf/mbcf-storage/devel/umv/software/bowtie/bowtie-1.0.1/bowtie -n 0 -l 20 -m 1 -S -p {threads} {input.bowtie_index}/crispr - 1>{output} 2>{log}" 
        
rule bowtie_report:
    input:
        bowtie_out_files=expand( "analysis/bowtie_align/{sample}.bowtie.out", sample=file_info.keys() ),
        ref_fa_files=lambda wildcards: [ lib_info[file] + ".nodups.fa" for file in lib_info.keys() ]    
    output:
        "analysis/align_report.csv"
    run:
        file_list = ' -b '.join( input.bowtie_out_files )
        ref_list = ' -r '.join( input.ref_fa_files )
        shell( "perl CRISPR_stag/scripts/get_bowtie_counts.pl -r {ref_list} -b {file_list} 1>{output}" )
        













