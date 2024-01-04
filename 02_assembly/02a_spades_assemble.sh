#!/usr/bin/bash
dir_seq=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/01_Pre_assemble/02b_Pre-decontamination
dir_out=$HOME/data1/sjzhang/01_Nematodes/01_Ascaridoidea/02_Spades_assemble
if [[ ! -d ${dir_out} ]];then mkdir -p ${dir_out};fi

source /usr/local/anaconda3/bin/activate assembles
NP=40
NM=250
# NT=$[$(ls -lh ${dir_seq}/*_decontamination | wc -l)]
NT=3
tmp_fifoflie="/tmp/$$.fifo"
trap "exec 9>&-;exec 9<&-;exit 0" 2
mkfifo ${tmp_fifoflie}
exec 9<>${tmp_fifoflie}
rm ${tmp_fifoflie}
for ((i=1;i<=${NT};i++));do echo >&9;done

for seq_dir in ${dir_seq}/*_decontamination;do
	read -u9
	{

	out_name=$(basename ${file} _decontamination)
	output=${dir_out}/${out_name}_spades
	if [[ ! -d ${output} ]];then mkdir -p ${output};fi
	echo -e "\n==========================\n Spades assemble for ${out_name} is started ! please wait... \n==========================\n"
	spades.py \
		 -1 ${seq_dir}/${out_name}_clean_1.fq \
		 -2 ${seq_dir}/${out_name}_clean_2.fq \
		 --careful \
		 -m ${NM} \
		 -o ${output}
	cp ${output}/scaffolds.fasta ${dir_out}/${out_name}_scaffolds.fasta &&
	cd ${dir_out} && time rm -r ./${out_name}_spades &&
	echo -e "\n==========================\n Spades assemble for ${out_name} is completed !! \n==========================\n"

	echo >&9
	} &
done
wait
conda deactivate
echo -e "\n==========================\n All genomes has been completed !! \n==========================\n"
