#!/bin/bash

domain=$1
RED="\033[1;31m"
RESET="\033[0m"
info_path=$domain/info
subdomain_path=$domain/subdomains
waybackurl_path=$domain/waybackurl
nuclei_path=$domain/nuclei
dirsearch_path=$domain/dirsearch
parameter_path=$domain/parameter

if [ ! -d "$domain" ];then
	mkdir $domain

fi


if [ ! -d "$info_path" ];then
	mkdir $info_path

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

echo -e "${RED}[+] Checkin' who it is...${RESET}"
whois $1 > $info_path/whois.txt

echo -e "${RED}[+] Launching subfinder...${RESET}"
subfinder -silent -d $domain > $subdomain_path/found.txt

echo -e "${RED}[+] Launching Assetfinder...${RESET}"
assetfinder $domain |grep $domain >> $subdomain_path/found.txt

cat $subdomain_path/found.txt | grep $domain | sort -u | httprobe -prefer-https | grep https | sed 's/https\?:\/\///'| tee -a $subdomain_path/alive.txt

#param spider
echo -e "${RED}[+] Launching paramscanner...${RESET}"
python3 /root/tools/ParamSpider/paramspider.py -d $domain -q -l high -o $parameter_path/param.txt  --exclude woff,css,js,png,svg,php,jpg;


#echo -e "${RED}[+] Taking screenshots...${RESET}"
#gowitness file -f $subdomain_path/alive.txt -P $screenshot_path --no-http

echo -e "${RED}[+] Checking waybackurls...${RESET}"
cat $subdomain_path/alive.txt | waybackurls > $waybackurl_path/waybackurls.txt
echo -e "${RED}[+] Checking gau...${RESET}"
cat $subdomain_path/alive.txt | gau | cat $waybackurl_path/waybackurls.txt | sort -u >> $waybackurl_path/waybackurls.txt
cat $waybackurl_path/waybackurls.txt | grep "\.js" | uniq | sort > $waybackurl_path/wayback_js.txt
cat $waybackurl_path/waybackurls.txt | grep "\.json" | uniq | sort > $waybackurl_path/wayback_json.txt


echo -e "${RED}[+] Launching Dirsearch...${RESET}"
python3 /root/tools/dirsearch/dirsearch.py -q --force-recursive -x 404,403,500-599 -l $subdomain_path/alive.txt -o $dirsearch_path/dirsearch.txt 

echo -e "${RED}[+] Launching Nuclei it takes sometime...${RESET}"
cat $subdomain_path/alive.txt | httpx -silent | nuclei -silent -t /root/tools/nuclei-templates/ -o $nuclei_path/nuclei.txt
