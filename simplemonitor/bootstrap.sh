#/bin/bash
date
apt update
apt upgrade -y
apt install -y  inetutils-ping python3-pip dnsutils
date
/usr/local/bin/python -m pip install --upgrade pip
pip install simplemonitor;
date
cd /config/simplemonitor/
echo "Doing config test"
simplemonitor -vf /config/simplemonitor/monitor.ini -t
date
echo "Forcing pyOpenSSL upgrade"
pip install pyOpenSSL --upgrade
date
echo "Running Simple Monitor"
simplemonitor -vf /config/simplemonitor/monitor.ini

# Should see bootstrap output in Nomad job's stdout
# Should see simplemonitor's output in Nomad job's stderr