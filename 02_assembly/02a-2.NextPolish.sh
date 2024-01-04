#!/usr/bin/bash
dir_genome=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/02_Spades_assemble
dir_output=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/02_a_nextpolish
dir_seq=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02b_Pre-decontamination
if [[ ! -d ${dir_output} ]];then mkdir -p ${dir_output};fi

source /usr/local/anaconda3/bin/activate nextpolish
NP=20
NM=16
NT=2

tmp_fifofile="/tmp/$$.fifo"
trap "exec 9>&-;exec 9<&-;exit 0" 2
mkfifo ${tmp_fifofile}
exec 9<>${tmp_fifofile}
rm ${tmp_fifofile}
for ((i=1;i<=${NT};i++));do echo >&9;done

cd ${dir_output}
for genomes in ${dir_genome}/*_scaffolds.fasta;do
	read -u9
	{

	out_name=$(basename ${genomes} _scaffolds.fasta)
	output=${dir_output}/${out_name}_polish
	if [[ ! -d ${output} ]];then mkdir -p ${output};fi
	cd ${output} &&

	echo -e "\n=====================================\n Polishing with 2round, started at \n$(date) \n=====================================\n"
	round=2
	NP=20
	read1=${dir_seq}/${out_name}_decontamination/${out_name}_clean_1.fq
	read2=${dir_seq}/${out_name}_decontamination/${out_name}_clean_2.fq
	input=${genomes}
	for ((j=1;j<=${round};j++));do
		echo -e "\n=====================================\n Round ${j}::Step1-1: index genome and alignment with bwa started at: \n$(date) \n=====================================\n"
		
		bwa index ${genomes};
		bwa mem -t ${NP} ${input} ${read1} ${read2} | samtools view --threads $[${NP}/2] -F 0x4 -b - | samtools fixmate -m --threads $[${NP}/2] - - | samtools sort -m 4g --threads $[${NP}/2] - | samtools markdup --threads $[${NP}/2] -r - sgs.sort.bam &&
		## index the bam and genome files
		samtools index -@ ${threads} sgs.sort.bam;
		samtools faidx ${input} &&
		
		echo -e "\n=====================================\nRound ${j}::Step1-2: 1st polishing for ${out_name} started at: \n$(date) \n=====================================\n"
		python /usr/local/anaconda3/envs/nextpolish/share/nextpolish-1.4.1/lib/nextpolish1.py \
			-g ${input} -t 1 -p ${NP} -s sgs.sort.bam > genome.polishtemp.fa;
		input=genome.polishtemp.fa;

		echo -e "\n=====================================\nRound ${j}::Step 2: 2nd polishing for ${out_name} started at: \n$(date) \n=====================================\n"
		bwa index ${input};
		bwa mem -t ${NP} ${input} ${read1} ${read2} | samtools view --threads $[${NP}/2] -F 0x4 -b - | samtools fixmate -m --threads $[${NP}/2]  - - | samtools sort -m 4g --threads 5 -|samtools markdup --threads $[${NP}/2] -r - sgs.sort.bam &&
		samtools index -@ ${NP} sgs.sort.bam;
		samtools faidx ${input};
		   #polish genome file
		python /usr/local/anaconda3/envs/nextpolish/share/nextpolish-1.4.1/lib/nextpolish1.py \
			-g ${input} -t 2 -p ${NP} -s sgs.sort.bam > genome.nextpolish.fa;
		input=genome.nextpolish.fa;
	done

	echo >&9
	} &
done
wait 
conda deactivate &&
echo -e "\n==========================\n Completed Pilon polishing for all !!\n==========================\n"
