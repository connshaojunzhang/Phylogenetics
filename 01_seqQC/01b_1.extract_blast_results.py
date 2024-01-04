#!/usr/bin/python
import re
from collections import defaultdict
from collections import Counter
import argparse
import sys


# read the blast 
def extract_blast(blast_result):
	xmlfile=open(blast_result,"r")
	outfile=open("tiqu_gi.txt","w")
	dict1=defaultdict(list)
	for lines in xmlfile:
		line=lines.strip()
		read_id = re.match('<Iteration_query-def>.*</Iteration_query-def>',line)
		Hit_id = re.match('<Hit_id>.*</Hit_id>',line)
		Hit_def = re.match('<Hit_def>.*</Hit_def>',line)
		if read_id !=None:
			read_id=read_id.group()
			read_id = read_id.split("<")[1].split(">")[1]
			key=read_id
		elif Hit_id !=None:
			Hit_id = Hit_id.group()
			Hit_id = Hit_id.split("<")[1].split(">")[1]
			dict1[key].append(Hit_id)
		elif Hit_def !=None:
			Hit_def = Hit_def.group()
			Hit_def = Hit_def.split("<")[1].split(">")[1]
			dict1[key].append(Hit_def)
	for key in dict1:
		outfile.write(key + "\t" + "\t".join(dict1[key])+"\n")
	tiqu_gi = open("tiqu_gi.txt","r")
	gi2taxid = open("/mnt/data0/dbs/blast_db/03_taxonomy_db/cutted_nucl_gb.accession2taxid","r")
	taxid2name = open("/mnt/data0/dbs/blast_db/03_taxonomy_db/taxidump/names.dmp","r")
	get_name = open("scientific_name.txt","w")
	taxid_name_dict={}
	for lines in taxid2name:
		if "scientific name" in lines:
			line = lines.strip().split("|")
			taxid = line[0].strip()
			name = line[1].strip()
			taxid_name_dict[taxid]=name		
	tiqu_dict=defaultdict(list)
	for lines in tiqu_gi:
		line = lines.strip().split("\t")
		gi = line[1].split("|")[1]
		tiqu_dict[gi].append("\t".join(line))
	gi_taxid_dict={}
	for lines in gi2taxid:
		line = lines.strip().split("\t")
		GI = line[1]
		taxid = line[0]
		gi_taxid_dict[GI]=taxid
	jiaoji=set(tiqu_dict.keys())&set(gi_taxid_dict.keys())
	tax_list=taxid_name_dict.keys()
	#tiqu_gi = open("result.txt","r")
	tiqu_gi = open("tiqu_gi.txt","r")
	for lines in tiqu_gi:
		line = lines.strip().split("\t")
		gi = line[1].split("|")[1]
		if gi in jiaoji:
			taxid=gi_taxid_dict[gi]
			if taxid in tax_list:
				get_name.write("\t".join(line)+"\t"+taxid_name_dict[taxid]+"\n")
	scientific_name=open("scientific_name.txt","r")
	final_result =open("final_result.txt","w")
	name_list_all=[]
	for lines in scientific_name:
		line = lines.strip().split("\t")
		name = line[-1]
		name_list_all.append(name)
	count_result = Counter(name_list_all)
	count_list = list(count_result.items())
	count_list.sort(key=lambda x:x[1],reverse=True)
	final_result.write("Name\tHit_reads\tpercent_of_selected_reads\tpercent_of_all_Hit\n")
	for i in count_list:
		name = i[0]
		number = i[1]
		reads_num = 5000
		percent_of_selected_reads = "%.2f%%"%(100*float(number)/float(reads_num))
		percent_of_all_Hit ="%.2f%%"%(100*float(number)/float(len(name_list_all)))
		final_result.write(name+"\t"+str(number)+"\t"+str(percent_of_selected_reads)+"\t"+str(percent_of_all_Hit)+"\n")

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description='Check contamination in sequencing data by blast: extract and analysis of the blast results.')
    parser.add_argument('--input', '-i',
            help='The blast output outfmt 6 results: e.g., out.xml.')
    args=parser.parse_args()
    extract_blast(args.input)
    print("completed!!!")







