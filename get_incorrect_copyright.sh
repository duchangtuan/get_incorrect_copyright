#!/bin/bash

print_usage () {
    echo "USAGE: ${SCRIPT} [OPTIONS]"
    echo "This script gets the wrong copyright in .c and .h files"
    echo "    -t Perforce_path (Ex: //depot/aus/Advanced_Development/AR/OARv2/main/Object_Audio_Renderer_Imp/Source_Code/)"
    echo "    -s Start_date (EX: 2016/05/26)"
    echo "    -e End_date (EX: now)"
    echo "One example: bash get_incorrect_copyright.sh -t //depot/aus/Advanced_Development/AR/OARv2/main/Object_Audio_Renderer_Imp/Source_Code -s 2016/05/26 -e now"
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
# get the last character of the perforce path
# ${str:a:b} a is the starting point, b is the length
last_char_prefix=${prefix:$i:1}
# make sure the last charactor of perforce path is not '/'
if [ $last_char_prefix == "/" ]; then
    prefix=${prefix:0:$i}
fi

# Sync from p4
#p4 sync -f $prefix/...

# split the perforce path, the list seperator is '/'
code_folders=(${prefix//\// })
# get the last element of the coder_folders, that is, the direct folder name of perforce path
code_folder=${code_folders[${#code_folder[@]} - 1]}
code_folder_length=${#code_folder}

code_files=$(find $code_folder -regex ".*\.\(c\|h\)")

echo " "
echo "Files that has incorrect copyright year"
echo " "

for file in $code_files
do
    # cut out the common part of the perforce path and local path 
    perforce_path_c_h=$prefix"/"${file:${code_folder_length}+1:${#file}}

    # construct the p4 changes command
    updated=$(p4 changes $perforce_path_c_h@${start_time},@${end_time})
    if [ "$updated" ];
    then
        #First find if there is 'copyright' word in the file
        #Because some of the files don't have copyright word.
        grep_copyright=$(grep 'copyright' $file)
        if [ -n "$grep_copyright" ];
        then
            grep_2016=$(grep '2016' $file)
            if [ -z "$grep_2016" ];
            then
                changelist=$(p4 changes -m 2 $file)
                line_number=$(echo $changelist | grep -o 'Change' | wc -l)
                if [ $line_number -ne 1 ];
                then 
                    # get the two latest changelist
                    changelist=$(echo $changelist | grep -o '[0-9]\{7\}')
                    changelist1=${changelist:0:7}
                    changelist2=${changelist:8:7} 
                    # diff the two changelists. Because sometimes, maybe one changelist that merge from other perforce path,
                    # cause there is no differnce between the two changelists.
                    diff=$(p4 diff $perforce_path_c_h@$changelist1 $perforce_path_c_h@$changelist2 2>/dev/null)
                    have_diff=$(echo $diff | grep '>')
                    if [ -n "$have_diff" ];
                    then
                        echo $perforce_path_c_h
                    fi                    
                fi
            fi
        fi
    fi
done
