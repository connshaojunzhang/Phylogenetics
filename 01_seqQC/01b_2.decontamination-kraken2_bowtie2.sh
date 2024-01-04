#!/usr/bin/bash
dir_seqs=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/01_fastp
dir_out=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02b_Pre-decontamination
if [[ ! -d ${dir_out} ]];then mkdir -p ${dir_out};fi
# kraken2_bacteria_db=$HOME/data0/dbs/Kraken2_db/bacteria
bowtie2_human=$HOME/data0/dbs/Decontamination_db_bowtie/03_humanGRCh37_bowtie2/GRCh37
bowtie2_mouse=$HOME/data0/dbs/Decontamination_db_bowtie/04_mouseGRCm38_bowtie2/GRCm38

# source /usr/local/anaconda3/bin/activate seqqc

NP=20
NM=100
# NT=$[$(ls -lh ${dir_seqs}/*_fastp | wc -l)]
NT=7
tmp_fifofile="/tmp/$$.fifo"
trap "exec 9>&-;exec 9<&-;exit 0" 2
mkfifo ${tmp_fifofile}
exec 9<>${tmp_fifofile}
rm ${tmp_fifofile}
for ((i=1;i<=${NT};i++));do echo >&9;done

for seq_dir in ${dir_seqs}/*_fastp;do
	read -u9
	{

	out_name=$(basename ${seq_dir} _fastp)
	output=${dir_out}/${out_name}_decontamination
	if [[ ! -d ${output} ]];then mkdir -p ${output};fi
	cd ${output} &&
	# echo -e "\n==========================\n Now staring the classification against to bactiria and viral database for ${out_name}.....\n==========================\n"
	# kraken2 \
	# 		--db ${kraken2_bacteria_db} \
	# 		--paired \
	# 		--threads ${NP} \
	# 		--use-names \
	# 		--report ${out_name}.kraken2 \
	# 		--report-zero-counts \
	# 		--classified-out ${out_name}_conta#.fq \
	# 		--unclassified-out ${out_name}_deconta#.fq \
	# 		${seq_dir}/${out_name}_1.filter.fq.gz ${seq_dir}/${out_name}_2.filter.fq.gz

	# echo -e "\n==========================\n Pre-decontamination for ${out_name} is completed !!\n==========================\n"
	echo -e "\n==========================\n 01. Start bowtie2 alignment to human containimation for ${out_name}...\n==========================\n"
	bowtie2 -x ${bowtie2_human} \
			-1 ${seq_dir}/${out_name}_1.filter.fq.gz \
			-2 ${seq_dir}/${out_name}_2.filter.fq.gz \
			-S ${out_name}_possibleConta2human.sam \
			--un-conc ${out_name}_dehuman.bam \
			--threads ${NP}
	samtools sort -n -@${NP} ${out_name}_dehuman.1.bam -o ${out_name}_dehuman_sorted.1.bam 
	samtools sort -n -@${NP} ${out_name}_dehuman.2.bam -o ${out_name}_dehuman_sorted.2.bam
	bedtools bamtofastq -i ${out_name}_dehuman_sorted.1.bam \
						-fq ${out_name}_dehuman_1.fq 
	bedtools bamtofastq -i ${out_name}_dehuman_sorted.2.bam \
						-fq ${out_name}_dehuman_2.fq 
	echo -e "\n==========================\n 02. Start bowtie2 alignment to mouse containimation for ${out_name}...\n==========================\n"
	bowtie2 -x ${bowtie2_mouse} \
			-1 ${out_name}_dehuman_1.fq  \
			-2 ${out_name}_dehuman_2.fq  \
			-S ${out_name}_possibleConta2hu_mouse.sam \
			--un-conc ${out_name}_clean.bam \
			--threads ${NP}
	samtools sort -n -@${NP} ${out_name}_clean.1.bam -o ${out_name}_clean_sorted.1.bam 
	samtools sort -n -@${NP} ${out_name}_clean.2.bam -o ${out_name}_clean_sorted.2.bam
	bedtools bamtofastq -i ${out_name}_clean_sorted.1.bam \
						-fq ${out_name}_clean_1.fq 
	bedtools bamtofastq -i ${out_name}_clean_sorted.2.bam \
						-fq ${out_name}_clean_2.fq
	rm *.sam *.bam &&
	echo -e "\n==========================\n 02. Bowtie2 alignment to human & mouse for ${out_name} has been completed !!\n==========================\n"

	echo >&9	
	} &
done
wait
echo -e "\n==========================\n Completed all data !!\n==========================\n"
# conda deactivate
