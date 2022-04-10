#!/bin/bash

#create a function usage() thats prints out the usage of the script
usage() {
    echo "Usage:"
    echo "-h --> help message <--"
    echo "-j --> json output <--"
    echo "-u --> url <--"
    echo "-d --> TLDs: "
    echo "       ------> SONAR"
    echo "       ------> ASSETFINDER"
    echo "-A --> ALL { GO FOR A COFFEE }: "
    echo "       ------> SONAR"
    echo "       ------> ASSETFINDER"
    echo "       ------> SUBSCAN { BRUTE FORCE } ---- YOU WILL NEED TO SPECIFY YOUR OWN ROUTES DIRECTORY" 
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
                echo "$domain_clear" >> tlds.txt
            else
                tld=$(echo $domain | cut -d '.' -f2)
                echo "$tld" >> tlds.txt
                continue
            fi
        fi
    done < pre-domains.txt
    
    cat tlds.txt | sort | uniq > tlds-final.txt
    
    while IFS= read -r line; do
        subdomains=$(curl -s https://sonar.omnisint.io/all/$line)
        echo "$subdomains" | tr -d "{"\" | tr -s ":[" "+" | tr -s "]," "+" | tr -s "+" "\n"  > subdomains.txt
        cat subdomains.txt | sort | uniq > subdomains-final.txt 
    done < tlds-final.txt

    while IFS= read -r line; do
        assetfinder $line -subs-only > assetfinder.txt
        cat assetfinder.txt | sort | uniq > assetfinder-final.txt
    done < tlds-final.txt

    #remove all the files created
    rm tlds.txt && rm file.txt && rm pre-domains.txt && rm subdomains.txt && rm assetfinder.txt
}
allScan(){
    #valid DOMAIN regex
    VALID_DOMAIN="^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"

    while IFS= read -r line; do #IFS set the null String that prevents leading or trailling whitespace from being trimmed
        if [[ $line =~  IP ]]; then
            continue
        else
            domain=$(echo $line | cut -d ' ' -f3)
            if [[ $domain =~ $VALID_DOMAIN ]]; then
                domain_clear=$(echo $domain | cut -d '.' -f1)
                echo "$domain_clear" >> tlds.txt
            else
                tld=$(echo $domain | cut -d '.' -f2)
                echo "$tld" >> tlds.txt
                continue
            fi
        fi
    done < pre-domains.txt
    
    cat tlds.txt | sort | uniq > tlds-final.txt
    
    while IFS= read -r line; do
        subdomains=$(curl -s https://sonar.omnisint.io/all/$line)
        echo "$subdomains" | tr -d "{"\" | tr -s ":[" "+" | tr -s "]," "+" | tr -s "+" "\n"  > subdomains.txt
        cat subdomains.txt | sort | uniq > subdomains-final.txt 
    done < tlds-final.txt

    while IFS= read -r line; do
        assetfinder $line -subs-only > assetfinder.txt
        cat assetfinder.txt | sort | uniq > assetfinder-final.txt
    done < tlds-final.txt

    #################################################
    cat assetfinder-final.txt >> brute.txt
    cat subdomains-final.txt >> brute.txt
    cat brute.txt | sort | uniq > brute-final.txt
    
    while IFS= read -r line; do
        if [[ $line =~ $VALID_DOMAIN ]]; then
            echo "$line" >> clear-brutedomain.txt
        else
            #tld=$(echo $line | cut -d '.' -f1)
            echo "$tld" >> clear-brutedomain.txt
            continue
        fi
    done < brute-final.txt
    cat clear-brutedomain.txt | sort | uniq > clear-brutedomain-final.txt
    #################################################

    ##### NEED TO SWITCHS THIS FIELDS #####
    SUBSCAN_DIRECTORY = /home/kali/Documents/subscan
    DIRECTORY_FILE = /home/kali/Documents/RedTeamTools/Asset\ Recognition/IPs\ and\ Domains
    ##### NEED TO SWITCHS THIS FIELDS #####

    #NEW BRUTE FORCE MODULE
    while IFS= read -r line; do
        echo "Subdomain Brute Force: $line"
        cd $SUBSCAN_DIRECTORY && python3 subscan.py -f sub.txt $line >> $DIRECTORY_FILE/brutedomain.txt
        cd $DIRECTORY_FILE
        cat brutedomain.txt | sort | uniq > FINAL.txt
    done < clear-brutedomain-final.txt
    
    #remove all the files created
    rm tlds.txt && rm file.txt && rm pre-domains.txt && rm subdomains.txt && rm assetfinder.txt && brute.txt && clear-brutedomain.txt && clear-brutedomain-final.txt
}

VALID_ARGUMENTS=${#}

if [[ "$VALID_ARGUMENTS" -eq 0 ]]; then
   usage
   exit 1
fi

while getopts :u:j:d:A:h opt; do
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
        A) #ALL
            JSON=${OPTARG}
            read_json $JSON
            allScan
        ;;                
        *) # end of arguments , allways when an argument is not recognized
            printf "Invalid Option: $1.\n"
            usage        
        ;;
    esac
done
#end of script