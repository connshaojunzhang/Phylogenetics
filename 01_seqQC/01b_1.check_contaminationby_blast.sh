#!/usr/bin/bash
dir_seqs=${HOME}/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/01_fastp
dir_out=${HOME}/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02a_check_contamination
if [[ ! -d ${dir_out} ]];then mkdir -p ${dir_out};fi
blastdb_nt=$HOME/data0/dbs/blast_db/02_NR-nt_db/nt
analyze_blast=$HOME/data1/sjzhang/01_Nematodes/00_Scripts/01_Genome/01b_1.extract_blast_results.py

NP=10
NM=100
NT=10

tmp_fifofile="/tmp/$$.fifo"
trap "exec 9>&-;exec 9<&-;exit 0" 2
mkfifo ${tmp_fifofile}
exec 9<>${tmp_fifofile}
rm ${tmp_fifofile}
for ((i=1;i<=${NT};i++));do echo >&9;done

# randomly extract 5000 reads (5000*4=20000 lines in fq.gz file) for blast analysis
read_num=5000

for seq_dir in ${dir_seqs}/*_fastp;do
	read -u9
	{

	out_name=$(basename ${seq_dir} _fastp)
	output=${dir_out}/${out_name}_check.conta
	if [[ ! -d ${output} ]];then mkdir -p ${output};fi
	cd ${output} &&
	zcat ${seq_dir}/${out_name}_1.filter.fq.gz | head -n 20000 | awk '{if(NR%4==1){print ">"$1}else if(NR%4==2){print $0}}' | sed 's/@//g' >> ${out_name}_selected.fa &&
	zcat ${seq_dir}/${out_name}_2.filter.fq.gz | head -n 20000 | awk '{if(NR%4==1){print ">"$1}else if(NR%4==2){print $0}}' | sed 's/@//g' >> ${out_name}_selected.fa &&
	echo -e "\n==========================\n Now staring the blast for ${out_name} agianst nr_db.....\n==========================\n"
	blastn -query ${out_name}_selected.fa -out out.xml \
		   -max_target_seqs 1 \
		   -outfmt 5 \
		   -db ${blastdb_nt} \
		   -num_threads ${NP} \
		   -evalue 1e-5
	echo -e "\n==========================\n Blast for ${out_name} agianst nr_db is completed !!\n==========================\n"
	echo -e "\n==========================\n Analysing the blast results !!\n==========================\n"
	cd ${output} &&
	python ${analyze_blast} -i out.xml &&
	echo -e "\n==========================\n Analysing the blast results for ${out_name} is completed !!\n==========================\n"

	echo >&9	
	} &
done
wait
echo -e "\n==========================\n Completed all data !!\n==========================\n"
