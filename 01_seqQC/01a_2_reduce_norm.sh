#!/usr/bin/bash
dir_seqs=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02b_Pre-decontamination
dir_out=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02b_Pre-decontamination
if [[ ! -d ${dir_out} ]];then mkdir -p ${dir_out};fi
#if [[ ! -d ${wd}/corrected ]];then mkdir -p ${wd}/corrected;fi
source /usr/local/anaconda3/bin/activate seqqc
cd ${seqdir}
# NP=4
# NM=60
# # NT=$[$(ls -lh ${dir_seqs}/*_1.clean.fq.gz | wc -l)]
# NT=1

# tmp_fifofile="/tmp/$$.fifo"
# trap "exec 9>&-;exec 9<&-;exit 0" 2
# mkfifo ${tmp_fifofile}
# exec 9<>${tmp_fifofile}
# rm ${tmp_fifofile}
# for ((i=1;i<=${NT};i++));do echo >&9;done

for seq_dir in ${dir_seqs}/Porrocaecum_angusticolle_decontamination;do
	# read -u9
	# {

	out_name=$(basename ${seqs} _decontamination)
	out_put=${seq_dir}
	# if [[ ! -d ${out_put} ]];then mkdir -p ${out_put};fi
	echo -e "=========================================\n bbmap filtering of ${out_name} is running.....\n=========================================\n\n"
	cd ${out_put} &&
	clumpify.sh -Xmx6g \
		in1=${seq_dir}/${out_name}_clean_1.fq \
		in2=${seq_dir}/${out_name}_clean_2.fq \
		out1=${out_name}_dedup_1.fq.gz \
		out2=${out_name}_dedup_2.fq.gz \
		pigz \
		dedupe &&
	bbnorm.sh -Xmx6g \
		in1=${out_name}_dedup_1.fq.gz \
		in2=${out_name}_dedup_2.fq.gz \
		out1=${out_name}_nor_1.fq.gz \
		out2=${out_name}_nor_2.fq.gz \
		target=10 \
		min=2 \
		histcol=2 \
		khist=khist.txt \
		peaks=peaks.txt &&

	echo -e "=========================================\n bbmap filtering of ${out_name} is completed, running fastqc now ....\n=========================================\n\n"
	# cd ${out_put} &&
	# fastqc \
	# 	-o ${out_put} \
	# 	-f fastq \
	# 	-t ${NP} \
	# 	${out_name}_1.filter.fq.gz ${out_name}_2.filter.fq.gz
	# echo -e "=========================================\nFastqc for ${out_name} is completed !\n=========================================\n\n"

	# echo >&9
	# } &
done
wait
echo -e "=========================================\nFastp & fastqc are all completed !!!\n=========================================\n\n"

