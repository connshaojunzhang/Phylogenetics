#!/usr/bin/python
import re
import argparse
import sys

# read the blast 
def filter_fastq(input_file, output_file):
    with open(input_file, 'r') as in_file, open(output_file, 'w') as out_file:
        while True:
            # Read four lines at a time
            header=in_file.readline().strip()
            seq=in_file.readline().strip()
            plus=in_file.readline().strip()
            qual=in_file.readline().strip()

            if header and seq and plus and qual:
                if re.match('@', header) and len(seq) == len(qual):
                    # Write the sequence to the output file
                    out_file.write(header + '\n' + seq + '\n' + plus + '\n' + qual + '\n')
            else:
                continue
    

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description='Check fastq file and make filters.')
    parser.add_argument('--input', '-i',
            help='The fastq file you want to check.')
    parser.add_argument('--output', '-o', 
    		help='Output directory and file name.')
    args=parser.parse_args()
    filter_fastq(args.input, args.output)
    print("completed!!!")







