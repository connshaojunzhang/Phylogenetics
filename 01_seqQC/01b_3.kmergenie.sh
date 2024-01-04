#!/usr/bin/bash
dir_seq=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02b_Pre-decontamination
dir_out=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02c_kmer_survey
if [[ ! -d ${dir_out} ]];then mkdir -p ${dir_out};fi

NP=8
NM=50
NT=$[$(ls -lh ${dir_seq}/*_decontamination | wc -l)]

tmp_fifofile="/tmp/$$.fifo"
trap "exec 9>&-;exec 9<&-;exit 0" 2
mkfifo ${tmp_fifofile}
exec 9<>${tmp_fifofile}
rm ${tmp_fifofile}
for ((i=1;i<=${NT};i++));do echo >&9;done

summary=${dir_out}/summary_kmergenie.txt
touch ${summary}
echo -e "Species\tBestK\tpredictedSize" >> ${summary}

for seq_dir in ${dir_seq}/*_decontamination;do
	read -u9 
	{

	out_name=$(basename ${seq_dir} _decontamination)
	output=${dir_out}/${out_name}_diploid
	if [[ ! -d ${output} ]];then mkdir -p ${output};fi
	cd ${output} &&
	ls ${seq_dir}/${out_name}_clean_1.fq ${dir_genome}/${out_name}_clean_2.fq > fq_list.txt
	# echo -e "\n==========================\n Running genome survey for ${out_name} .....\n==========================\n"
	# echo -e "\n==========================\n Running genome survey for ${out_name} with second round.....\n==========================\n"
	# kmergenie fq_list.txt -o ${out_put}/${out_name} \
	# 	--diploid \
	# 	-l 21 \
	# 	-k 101 \
	# 	-s 10 \
	# 	-t ${NP} \
	# 	--debug
	echo -e "\n==========================\n Genome survey for ${out_name} is started ! please wait... \n==========================\n"
	kmergenie fq_list.txt -o ${output}/${out_name} \
		--diploid \
		-l 70 \
		-k 200 \
		-s 10 \
		-t ${NP} \
		--debug
	bestK=$(sed -n '/<p><h2>/p' ${out_name}_report.html | awk -F '[:<]' '{print $4}') &&
	preSize=$[$(sed -n '/<p><h4>/p' ${out_name}_report.html | awk -F ' ' '{print $4}')/1000000] &&
	echo -e "${out_name}\t${bestK}\t${preSize}" >> ${summary}
	echo -e "\n==========================\n Genome survey for ${out_name} has been completed !! \n==========================\n"
	
	echo >&9
	} &
done
wait
echo -e "\n==========================\n Genome survey for all samples has been completed !! \n==========================\n"