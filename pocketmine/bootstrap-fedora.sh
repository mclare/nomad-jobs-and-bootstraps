#!/bin/bash
date
echo " ----- Adding packages ----- "
dnf update -y
dnf install nano screen wget rsync cronie -y
dnf install autoconf automake m4 bzip2 bison g++ git cmake re2c libtool perl openssl-devel xz -y
date

mkdir -p /opt/pocketmine
cd /opt/pocketmine

echo " ----- Installing/updating to the latest version ofPHP ----- " 
wget -O installer.sh https://get.pmmp.io
chmod +x installer.sh
./installer.sh -r

echo " ----- Fetching latest PocketMineMP ----- "
wget -O PocketMine-MP.phar https://github.com/pmmp/PocketMine-MP/releases/latest/download/PocketMine-MP.phar

echo " ----- Fetching latest PocketMineMP start script----- "
wget https://github.com/pmmp/PocketMine-MP/releases/latest/download/start.sh
chmod +x start.sh
date

echo " ----- Copying game data to node ----- "
echo " ----- Copying: Worlds  ----- "
cp -r /common/pocketmine/worlds /opt/pocketmine/
date
echo " ----- Copying: Players  ----- "
cp -r /common/pocketmine/players /opt/pocketmine/
cp /common/pocketmine/ops.txt /opt/pocketmine/
date
echo " ----- Copying: server.properties  ----- "
cp /common/pocketmine/server.properties /opt/pocketmine/
date
echo " ----- Copying: pocketmine.yml  ----- "
cp -r /common/pocketmine/pocketmine.yml /opt/pocketmine/
date
echo " ----- Copying: Plugin config and data  ----- "
rm -f /common/pocketmine/plugins/._*
cp -r /common/pocketmine/plugin* /opt/pocketmine/
date
echo " ----- Copying: Whitelist (Allowed list) ----- "
cp -r /common/pocketmine/white-list.txt /opt/pocketmine/
date
echo " ----- Adding crontabs----- "
crontab /config/pocketmine-mp/crontabs
crond -i
echo " ----- Data copied ----- "
date
echo " ----- Starting Pocketmine ----- "
./start.sh
