#!/bin/bash

#create a function usage() thats prints out the usage of the script
usage() {
    echo "Usage:"
    echo "-h --> help message <--"
    echo "-j --> json output <--"
    echo "-u --> url <--"
    echo "---------------> Example: $0 -u http://www.example.com"
}

#write a function to read a JSON file from a URL and print the results
read_json() {
    #read the JSON file from the URL
    json=$(curl -s $1)
    #print the JSON file and grep the domain name with grep and sed
    echo $json | cut -d ":" -f 2 | tr -d "["\" | tr -d "]}"
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
