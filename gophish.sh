#!/usr/bin/env bash
# Version         : 3.0
# Created date    : 12/09/2019
# Last update     : 07/05/2022
# Author          : rarely.seen
# Description     : Automated script to install gophish with letsencrypt
# Note            : 09/20/20 - gophish admin password is not longer static. Added function to grab the temporary password for the initial login. You will be prompted to change the password as you login


if [ "$EUID" -ne 0 ]
  then echo "\e[1m" "\e[31m[*] Script must be run as root"
  exit
fi


### Colors
red=`tput setaf 1`;
green=`tput setaf 2`;
yellow=`tput setaf 3`;
blue=`tput setaf 5`;
magenta=`tput setaf 4`;
cyan=`tput setaf 6`;
bold=`tput bold`;
clear=`tput sgr0`;

banner() {
cat <<EOF
${blue}${bold}

                       _      _       _     
                      | |    (_)     | |    
   __ _   ___   _ __  | |__   _  ___ | |__  
  / _\` | / _ \ | '_ \ | '_ \ | |/ __|| '_ \ 
 | (_| || (_) || |_) || | | || |\__ \| | | |
  \__, | \___/ | .__/ |_| |_||_||___/|_| |_|
   __/ |       | |             [pentest.01]         
  |___/        |_|                          
        /|
       / |   /|        in God i trust
   <===  |=== | --------------------------------
       \ |   \|
        \|
${clear}
EOF

}

usage() {
  local ec=0

  if [ $# -ge 2 ] ; 
    then
    ec="$1" ; shift
    printf "%s\n\n" "$*" >&2
  fi

  banner
  cat <<EOF

A quick Bash script to install GoPhish server. 

${bold}Usage: ${blue}./$(basename $0) [-r <rid name>] [-e] [-s] [-d <domain name> ] [-c] [-h]${clear}

One shot to set up:
  - Gophish Server (Email Phishing Ver.)
  - Gophish Server (SMS Phishing Ver.)
  - SSL Cert for Phishing Domain (LetsEncrypt)

Options:
  -e        Setup Email Phishing Gophish Server
  -s        Setup SMS Phishing Gophish Server
  -r <rid name>      Configure custom "rid=" parameter for landing page (e.g., https://example.com?rid={{.RID}})
         If not specified, the default value would be "secure_id="
  -d <domain name>      SSL cert for phishing domain
         ${red}[WARNING] Configure 'A' record before running the script${clear}
  -c        Cleanup for a fresh install
  -h                 This help menu

Examples:
  ./$(basename $0) -e               Setup Email Phishing Gophish
  ./$(basename $0) -s               Setup SMS Phishing Gophish
  ./$(basename $0) -r <rid name> -e          Setup Email Phishing Gophish + Your choice of rid
  ./$(basename $0) -r <rid name> -s       Setup SMS Phishing Gophish + Your choice of rid
  ./$(basename $0) -d <domain name>       Configure SSL cert for your phishing Domain
  ./$(basename $0) -e -d <domain name>       Email Phishing Gophish + SSL cert for Phishing Domain
  ./$(basename $0) -r <rid name> -e -d <domain name>  Email Phishing Gophish + SSL cert + rid 

EOF

exit $ec
 
}

### Exit
exit_error() {
   usage
   exit 1
}


echo
sleep 4


### Initial Update & Dependency Check
dependencyCheck() {
   ### Update Sources
   echo "${blue}${bold}[*] Updating source lists...${clear}"
   hwclock --hctosys 
   apt update ; apt-get -y upgrade ; apt-get -y dist-upgrade ; apt-get -y autoremove ; apt-get -y autoclean ; echo
   
   echo
   sleep 4
   
    echo "${blue}${bold}[*] Creating a gophish folder: /opt/gophish${clear}"
    mkdir -p /opt/gophish

   echo
   sleep 4
   
   ### Checking/Installing unzip
   unzip=$(which unzip)

   if [[ $unzip ]];
     then
      echo "${green}${bold}[+] Unzip already installed${clear}"
   else
      echo "${blue}${bold}[*] Installing unzip...${clear}"
      apt-get install unzip -y
   fi

   echo
   sleep 4

   ### Checking/Installing go
   gocheck=$(which go)

   if [[ $gocheck ]];
     then
      echo "${green}${bold}[+] Golang already installed${clear}"
   else
      echo "${blue}${bold}[*] Installing Golang...${clear}"
      apt install golang-go -y
   fi
   
   echo
   sleep 4

   ### Checking/Installing git
   gitcheck=$(which git)

   if [[ $gitcheck ]];
     then
      echo "${green}${bold}[+] Git already installed${clear}"
   else
      echo "${blue}${bold}[*] Installing Git...${clear}"
      apt-get install git -y
   fi

   echo
   sleep 4
   
   ### Checking/Installing Apache2
   a2check=$(which apache2)

   if [[ $a2check ]];
     then
      echo "${green}${bold}[+] Apache2 already installed${clear}"
   else
      echo "${blue}${bold}[*] Installing Apache...${clear}"
      apt install apache2 -y && 
      systemctl reload apache2
   fi
   
   echo
   sleep 4

   ### Checking/Installing pip (*Needed to install Twilio lib)
   pipcheck=$(which pip)

   if [[ $pipcheck ]];
     then
      echo "${green}${bold}[+] Pip already installed${clear}"
   else
      echo "${blue}${bold}[*] Installing pip...${clear}"
      apt-get install python3-pip -y
      
   fi

}

echo
sleep 4

### Setup Email Version Gophish
setupEmail() {
   ### Cleaning Port 80
   fuser -k -s -n tcp 80
   
   ### Deleting Previous Gophish Source (*Need to be removed to update new rid)
   rm -rf /opt/gophish/

   echo
   sleep 4

   ### Installing GoPhish v0.11.0
   if [ -d /opt/gophish/.git ]; then
      echo -e "${blue}${bold}[*] Updating Gophish."
      cd /opt/gophish; git pull
      echo
    else
      echo -e "${blue}${bold}[*] Downloading Gophish...${clear}"
      git clone https://github.com/gophish/gophish.git /opt/gophish
      echo
   fi

   echo
   sleep 2

      # Stripping X-Gophish 
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/email_request_test.go
      echo
      sleep 2
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/maillog.go
      echo
      sleep 2
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/maillog_test.go
      echo
      sleep 2
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/email_request.go
      echo
      sleep 2
   # Stripping X-Gophish-Signature
      sed -i 's/X-Gophish-Signature/X-Signature/g' /opt/gophish/webhook/webhook.go
      echo
      sleep 2
   # Changing servername
      sed -i 's/const ServerName = "gophish"/const ServerName = "IGNORE"/' /opt/gophish/config/config.go
      echo
      sleep 2
   # Changing rid value
      #sed -i 's/const RecipientParameter = "rid"/const RecipientParameter = "keyname"/g' /opt/gophish/models/campaign.go
      echo
      sleep 2
   # Downloading external files
      wget https://raw.githubusercontent.com/pentest01/gophish-extension/main/phish.go -P /opt/gophish/ >/dev/null 2>&1
      sleep 2
      wget https://raw.githubusercontent.com/pentest01/gophish-extension/main/404.html -P /opt/gophish/ >/dev/null 2>&1
      echo
      sleep 2
   # Deleting phish.go
      rm /opt/gophish/controllers/phish.go
      sleep 2
   # Copying in custom 404 handler
      mv /opt/gophish/phish.go /opt/gophish/controllers/phish.go
      sleep 2
      mv /opt/gophish/404.html /opt/gophish/templates/
      echo
      sleep 2

   if [ "$rid" != "" ]
     then
      echo "${blue}${bold}[*] Updating \"rid\" to \"$rid\"${clear}"
      sed -i 's!rid!'$rid'!g' /opt/gophish/models/campaign.go
      ridConfirm=$(cat /opt/gophish/models/campaign.go | grep $rid)
      echo "${blue}${bold}[*] Confirmation: $ridConfirm (campaign.go)${clear}"
    fi

   echo
   sleep 4

  cd /opt/gophish && go build
  
  echo "${blue}${bold}[*] Changing ip...${clear}"
  sed -i 's/127.0.0.1/0.0.0.0/g' /opt/gophish/config.json &&
  sed -i 's/0.0.0.0/127.0.0.1/g' /opt/gophish/config.json && cd
  
  echo
  sleep 2
   
  echo "${blue}${bold}[*] Creating a gophish log folder: /var/log/gophish${clear}"
  mkdir -p /var/log/gophish &&

 ### Start Script Setup	
  useradd -r gophish
  wget https://raw.githubusercontent.com/pentest01/gophish.service/main/gophish.service -P /etc/systemd/system/ &&
  chown -R gophish:gophish /opt/gophish/ /var/log/gophish/ &&
  setcap cap_net_bind_service=+ep /opt/gophish/gophish &&
  systemctl daemon-reload &&
  systemctl start gophish 

}

setupSMS() {
   ### Cleaning Port 80
   fuser -k -s -n tcp 80

   ### Deleting Previous Gophish Source (*Need to be removed to update new rid)
   rm -rf /opt/gophish/
   
   echo
   sleep 4

    ### Installing GoPhish v0.11.0
      if [ -d /opt/gophish/.git ]; then
      echo -e "${blue}${bold}[*] Updating Gophish."
      cd /opt/gophish; git pull
      echo
    else
      echo -e "${blue}${bold}[*] Downloading Gophish...${clear}"
      git clone https://github.com/gophish/gophish.git /opt/gophish
      echo
   fi
   echo
   sleep 2

      # Stripping X-Gophish 
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/email_request_test.go
      echo
      sleep 2
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/maillog.go
      echo
      sleep 2
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/maillog_test.go
      echo
      sleep 2
      sed -i 's/X-Gophish-Contact/X-Contact/g' /opt/gophish/models/email_request.go
      echo
      sleep 2
   # Stripping X-Gophish-Signature
      sed -i 's/X-Gophish-Signature/X-Signature/g' /opt/gophish/webhook/webhook.go
      echo
      sleep 2
   # Changing servername
      sed -i 's/const ServerName = "gophish"/const ServerName = "IGNORE"/' /opt/gophish/config/config.go
      echo
      sleep 2
   # Changing rid value
      #sed -i 's/const RecipientParameter = "rid"/const RecipientParameter = "keyname"/g' /opt/gophish/models/campaign.go
   #   echo
  #    sleep 2
   # Downloading external files
      wget https://raw.githubusercontent.com/pentest01/gophish-extension/main/phish.go -P /opt/gophish/ >/dev/null 2>&1
      sleep 2
      wget https://raw.githubusercontent.com/pentest01/gophish-extension/main/404.html -P /opt/gophish/ >/dev/null 2>&1
      echo
      sleep 2
   # Deleting phish.go
      rm /opt/gophish/controllers/phish.go
      sleep 2
   # Copying in custom 404 handler
      mv /opt/gophish/phish.go /opt/gophish/controllers/phish.go
      sleep 2
      mv /opt/gophish/404.html /opt/gophish/templates/
      echo
      sleep 2


   if [ "$rid" != "" ]
     then
      echo "${blue}${bold}[*] Updating \"rid\" to \"$rid\"${clear}"
      sed -i 's!rid!'$rid'!g' /opt/gophish/models/campaign.go
      ridConfirm=$(cat /opt/gophish/models/campaign.go | grep $rid)
      echo "${blue}${bold}[*] Confirmation: $ridConfirm (campaign.go)${clear}"
    fi

   echo
   sleep 4

   cd /opt/gophish && go build
  
   echo "${blue}${bold}[*] Changing ip...${clear}"
   sed -i 's/127.0.0.1/0.0.0.0/g' /opt/gophish/config.json &&
   sed -i 's/0.0.0.0/127.0.0.1/g' /opt/gophish/config.json && 
  
   echo
   sleep 2
   
   echo "${blue}${bold}[*] Creating a gophish log folder: /var/log/gophish${clear}"
   mkdir -p /var/log/gophish &&

   ### Getting gosmish.py (Author: fals3s3t)
   echo "${blue}${bold}[*] Pulling gosmish.py to: /opt/gophish...${clear}"
   wget https://raw.githubusercontent.com/pentest01/gosmish/master/gosmish.py -P /opt/gophish/gosmish.py >/dev/null 2>&1 &&
   chmod +x /opt/gophish/gosmish.py

   ### Installing Twilio
   twilow=$(which twilio)

   if [[ $twilio ]];
     then
      echo "${green}${bold}[+] Twilio already installed...${clear}"
   else
      echo "${blue}${bold}[*] Installing Twilio...${clear}"
      pip install -q  twilio
   fi

   echo
   sleep 4
   
   echo "${blue}${bold}[*] Installing and configuring Postfix for SMS SMTP blackhole...${clear}"
   name=$(hostname)
   echo "postfix    postfix/mailname string sms.sms " | debconf-set-selections
   echo "postfix postfix/main_mailer_type string 'Local Only'" | debconf-set-selections
   apt-get -y  install postfix
   apt-get -y  install postfix-pcre

   sed -i  "/myhostname/c\myhostname = $name" /etc/postfix/main.cf
   echo 'virtual_alias_maps = pcre:/etc/postfix/virtual' >> /etc/postfix/main.cf
   echo '/.*/                        nonexist' > /etc/postfix/virtual
   service postfix stop &&
   service postfix start &&

   ### Start Script Setup  
  useradd -r gophish
  cp /home/ubuntu/gophish/gophish_service /etc/systemd/system/gophish.service &&
  chown -R gophish:gophish /opt/gophish/ /var/log/gophish/
  setcap cap_net_bind_service=+ep /opt/gophish/gophish
  systemctl daemon-reload
  systemctl start gophish
  
}


### Setup SSL Cert
letsEncrypt() {
   ### Clearning Port 80
   fuser -k -s -n tcp 80 
      
   ### Installing certbot-auto
  certbot=$(which certbot)

	if [[ $certbot ]];
	  then
	   echo "${green}${bold}[+] Certbot already installed${clear}"
	else
	   echo "${blue}${bold}[*] Installing Certbot...${clear}"
	   apt-get install certbot -y >/dev/null 2>&1
	fi

echo 

   ### Installing SSL Cert 
   echo "${blue}${bold}[*] Installing SSL Cert for $domain...${clear}"
   
   ### Stopping apache2
   systemctl stop apache2
   ### Manual
   #./certbot-auto certonly -d $domain --manual --preferred-challenges dns -m example@gmail.com --agree-tos && 
   ### Auto
   certbot certonly --non-interactive --agree-tos --email example@gmail.com --standalone --preferred-challenges dns -d $domain &&

   echo "${blue}${bold}[*] Configuring New SSL cert for $domain...${clear}" &&
   wget https://raw.githubusercontent.com/pentest01/gophish.service/main/gophish-ssl.conf -P /etc/apache2/sites-available/ >/dev/null 2>&1
   cp /etc/letsencrypt/live/$domain/privkey.pem /opt/gophish/privkey.pem &&
   cp /etc/letsencrypt/live/$domain/fullchain.pem /opt/gophish/fullchain.pem &&
   sed -i 's/false/true/g' /opt/gophish/config.json &&
   sed -i 's/:80/8443/g' /opt/gophish/config.json &&
   sed -i 's/ssl-cert-snakeoil.pem/fullchain.pem/g' /etc/apache2/sites-available/gophish-ssl.conf &&
   sed -i 's/ssl-cert-snakeoil.key/privkey.pem/g' /etc/apache2/sites-available/gophish-ssl.conf &&
   sed -i 's/example.key/privkey.pem/g' /opt/gophish/config.json &&
   sed -i 's/gophish_admin.crt/fullchain.pem/g' /opt/gophish/config.json &&
   sed -i 's/gophish_admin.key/privkey.pem/g' /opt/gophish/config.json &&
   mkdir -p /opt/gophish/static/endpoint &&
   printf "User-agent: *\nDisallow: /" > /opt/gophish/static/endpoint/robots.txt &&
   echo "${green}${bold}[+] Check if the cert is correctly installed: https://$domain/robots.txt${clear}"
}

gophishStart() {
   service=$(ls /etc/systemd/system/gophish.service 2>/dev/null)
   
   if [[ $service ]];
     then
      sleep 1
      systemctl restart gophish && systemctl restart apache2
      #ipAddr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1)
      ipAddr=$(curl ifconfig.io 2>/dev/null)
      pass=$(cat /var/log/gophish/gophish.log | grep 'Please login with' | cut -d '"' -f 4 | cut -d ' ' -f 10 | tail -n 1)
      echo "${green}${bold}[+] Gophish Started: https://$ipAddr:3333 - [Login] Username: admin, Temporary Password: $pass${clear}"
      echo "${green}${bold}[+] Configure 000-default.conf && automatically renew ssl{clear}"
   else
      exit 1
   fi
}

cleanUp() {
   echo "${green}${bold}Cleaning...1...2...3...${clear}"
   systemctl stop gophish 2>/dev/null
   deluser gophish 2>/dev/null
   rm -rf /opt/gophish/ 2>/dev/null
   rm /etc/systemd/system/gophish.service 2>/dev/null
   rm /etc/letsencrypt/keys/* 2>/dev/null
   rm /etc/letsencrypt/csr/* 2>/dev/null
   rm -rf /etc/letsencrypt/archive/* 2>/dev/null
   rm -rf /etc/letsencrypt/live/* 2>/dev/null
   rm -rf /etc/letsencrypt/renewal/* 2>/dev/null
   echo "${green}${bold}[+] Done!${clear}"
}

domain=''
rid=''

while getopts ":r:esd:ch" opt; do
   case "${opt}" in
      r)
         rid=$OPTARG ;;
      e)
         banner
         dependencyCheck
         setupEmail
         gophishStart ;;
      s)
         banner
         dependencyCheck
         setupSMS
         gophishStart ;;
      d) 
         domain=${OPTARG} 
         letsEncrypt && 
         gophishStart ;;
      c)
         cleanUp ;;
      h | * ) 
         exit_error ;;
      :) 
         echo "${red}${bold}[-] Error: -${OPTARG} requires an argument (e.g., -r page_id or -d gogophish.com)${clear}" 1>&2
         exit 1;;
   esac
done

if [[ $# -eq 0 ]];
  then
   exit_error
fi
