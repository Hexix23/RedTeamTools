#!/bin/bash

#create a function usage() thats prints out the usage of the script
usage() {
    echo "Usage:"
    echo "-h --> help message <--"
    echo "-j --> json output <--"
    echo "-u --> url <--"
    echo "-d --> domain <--"
    echo "---------------> Example: $0 -u http://www.example.com"
}
#write a function to read a JSON file from a URL and print the results
read_json() {
    #read the JSON file from the URL
    json=$(curl -s $1)
    #print the JSON file and grep the domain name with grep and sed
    echo $json | tr -d "{"\" | tr -s ":[" "+" | tr -s "]," "+" | tr -s "+" "\n"  > file.txt
    add_ip
}

#add the string "IP:" to the beginning of each line with a digit
add_ip() {
    #valid IP address regex
    VALID_IP_ADDRESS="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    #read the file
    while read line; do
        #if the line has a $VALID_IP_ADDRESS, add the string "IP:" to the beginning of the line
        if [[ $line =~ $VALID_IP_ADDRESS ]]; then #if the line has a digit at the beginning of the line
            echo "IP: $line"
            #reset the counter
            count=0
        else
            #if last char is } then finish the loop
            if [[ $line == "}" ]]; then
                break
            fi
            echo "--> $count $line"
            count=$(($count+1))
        fi
    done < file.txt
}

VALID_ARGUMENTS=${#}

if [[ "$VALID_ARGUMENTS" -eq 0 ]]; then
   usage
   exit 1
fi

while getopts :u:j:h opt; do
    case ${opt} in
        h) #help
            usage
            exit 0
        ;;
        u) #url
            URL=${OPTARG}
            curl $URL
        ;;
        j) #json
            JSON=${OPTARG}
            read_json $JSON
        ;;        
        *) # end of arguments , allways when an argument is not recognized
            printf "Invalid Option: $1.\n"
            usage        
        ;;
    esac
done
#end of script