#!/bin/bash

#create a function usage() thats prints out the usage of the script
usage() {
    echo "Usage:"
    echo "-h --> help message <--"
    echo "-j --> json output <--"
    echo "-u --> url <--"
    echo "-d --> TLDs <--"
    echo "---------------> Example: $0 -u http://www.example.com"
}
#read a JSON file from a URL and print the results
read_json() {
    #read the JSON file from the URL
    json=$(curl -s $1)
    #print the JSON file and grep the domain name with grep and sed
    echo $json | tr -d "{"\" | tr -s ":[" "+" | tr -s "]," "+" | tr -s "+" "\n"  > file.txt
    add_ip > pre-domains.txt
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

grep_domains(){
    #valid DOMAIN regex
    VALID_DOMAIN="^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"
    
    while IFS= read -r line; do #IFS set the null String that prevents leading or trailling whitespace from being trimmed
        if [[ $line =~  IP ]]; then
            continue
        else
            domain=$(echo $line | cut -d ' ' -f3)
            if [[ $domain =~ $VALID_DOMAIN ]]; then
                domain_clear=$(echo $domain | cut -d '.' -f1)
                echo "DOMAIN: $domain_clear"
            else
                tld=$(echo $domain | cut -d '.' -f2)
                echo "TLDs: $tld"
                continue
            fi
        fi
    done < pre-domains.txt
}

VALID_ARGUMENTS=${#}

if [[ "$VALID_ARGUMENTS" -eq 0 ]]; then
   usage
   exit 1
fi

while getopts :u:j:d:h opt; do
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
        d) #TLDs
            JSON=${OPTARG}
            read_json $JSON
            grep_domains
        ;;                   
        *) # end of arguments , allways when an argument is not recognized
            printf "Invalid Option: $1.\n"
            usage        
        ;;
    esac
done
#end of script