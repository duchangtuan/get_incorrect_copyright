#!/bin/bash

print_usage () {
    echo "USAGE: ${SCRIPT} [OPTIONS]"
    echo "This script gets the wrong copyright in .c and .h files"
    echo "    -t Perforce_path (Ex: //depot/aus/aaa/bbb/)"
    echo "    -s Start_date (EX: 2016/05/26)"
    echo "    -e End_date (EX: now)"
    echo "One example: bash get_incorrect_copyright.sh -t //depot/aus/aaa/bbb -s 2016/05/26 -e now"
}

while getopts ":t:s:e:h" OPT; do
    case ${OPT} in
        t)
            perforce_path="${OPTARG}"; 
            ;;
        s)
            start_time="${OPTARG}"; 
            ;;
        e)
            end_time="${OPTARG}"; 
            ;;
        h)
            print_usage
            exit 0
            ;;
        *)
            print_usage
            exit 1 
            ;;
    esac
done

if [ -z "${perforce_path}" ] || [ -z "${start_time}" ] || [ -z "${end_time}" ]; then
    print_usage
    exit 0
fi

prefix=$perforce_path
i=$((${#prefix} - 1))
last_char_prefix=${prefix:$i:1}
if [ $last_char_prefix == "/" ]; then
    prefix=${prefix:0:$i}
fi

# Sync from p4
p4 sync -f $prefix/...

code_folders=(${prefix//\// })
code_folder=${code_folders[${#code_folder[@]} - 1]}
code_folder_length=${#code_folder}

h_c_files=$(find $code_folder -regex ".*\.\(c\|\h\)")

echo "Files that has incorrect copyright year"
echo " "

for file in $h_c_files
do
    # cut out the common part of the perforce path and local path 
    perforce_path_c_h=$prefix"/"${file:${code_folder_length}+1:${#file}}

    # construct the p4 changes command
    updated=$(p4 changes $perforce_path_c_h@${start_time},@${end_time})
    if [ "$updated" ];
    then
        #echo $updated
        grep_2016=$(grep '2016' $file)
        if [ -z "$grep_2016" ];
        then
            echo $perforce_path_c_h
        fi
    fi
done
