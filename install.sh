#!/bin/bash
#sudo adduser --system --quiet --shell=/bin/bash --home=/opt/flectra --gecos 'flectra' --group flectra
OS_NAME=$(lsb_release -cs)
usuario=$USER
DIR_PATH=$(pwd)
PROJECT_NAME=flectra2
PORT=7169
PATHBASE=/opt/$PROJECT_NAME
PATH_LOG=$PATHBASE/log
VERSION=master
PATHREPOS=$PATHBASE/$VERSION/extra-addons


sudo adduser --system --quiet --shell=/bin/bash --home=$PATHBASE --gecos 'FLECTRA' --group $usuario
sudo adduser $usuario sudo

#sudo mkdir /etc/flectra && mkdir /var/log/flectra/
sudo mkdir $PATHBASE
sudo mkdir $PATHBASE/$VERSION
sudo mkdir $PATHREPOS
sudo mkdir $PATH_LOG
cd $PATHBASE

sudo git clone --depth=1 --branch=2.0 https://gitlab.com/flectra-hq/flectra.git $PATHBASE/$VERSION/flectra

sudo apt-get update && apt-get upgrade -y && apt-get install postgresql postgresql-server-dev-12 build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev  libxml2-dev libxslt1-dev libjpeg-dev -y
sudo service postgresql restart

#sudo su - postgres -c "createuser -s flectra"
sudo su - postgres -c "createuser -s $usuario"

#sudo chown flectra:flectra /opt/flectra/ -R && sudo chown flectra:flectra /var/log/flectra/ -R && cd /opt/flectra/flectra && sudo pip3 install -r requirements.txt

#sudo npm install -g less less-plugin-clean-css rtlcss -y
sudo apt-get -y install python3 python3-pip python3-setuptools htop
sudo pip3 install virtualenv
# FIX wkhtml* dependencie Ubuntu Server 18.04
sudo apt-get -y install libxrender1

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

#cd /tmp && wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb && sudo gdebi -n wkhtmltox_0.12.5-1.bionic_amd64.deb && rm wkhtmltox_0.12.5-1.bionic_amd64.deb
#sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin/ && sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin/
# Download & install WKHTMLTOPDF
sudo rm $PATHBASE/wkhtmltox*.deb

if [[ "`getconf LONG_BIT`" == "32" ]];

then
	sudo wget $wk32
else
	sudo wget $wk64
fi

sudo dpkg -i --force-depends wkhtmltox_0.12.5-1*.deb
sudo apt-get -f -y install
sudo ln -s /usr/local/bin/wkhtml* /usr/bin
sudo rm $PATHBASE/wkhtmltox*.deb
sudo apt-get -f -y install

#sudo su - postgres -c "createuser -s flectra"
sudo su - postgres -c "createuser -s $usuario"

# install python requirements file (Odoo)
sudo rm -rf $PATHBASE/$VERSION/venv
sudo mkdir $PATHBASE/$VERSION/venv
sudo chown -R $usuario: $PATHBASE/$VERSION/venv
virtualenv -q -p python3 $PATHBASE/$VERSION/venv
sed -i '/libsass/d' $PATHBASE/$VERSION/flectra/requirements.txt
$PATHBASE/$VERSION/venv/bin/pip3 install libsass vobject qrcode num2words
$PATHBASE/$VERSION/venv/bin/pip3 install -r $PATHBASE/$VERSION/flectra/requirements.txt


cd $DIR_PATH

sudo mkdir $PATHBASE/config
sudo rm $PATHBASE/config/$PROJECT_NAME.conf
sudo touch $PATHBASE/config/$PROJECT_NAME.conf
echo "
[options]
; This is the password that allows database operations:
admin_passwd = marlboro
db_host = False
db_port = False
;db_user =
;db_password =
data_dir = $PATHBASE/data
logfile= $PATH_LOG/$PROJECT_NAME-server.log
############# addons path ######################################
addons_path =
    $PATHREPOS,
;    $PATHREPOS/backend_theme,
;    $PATHREPOS_OCA/web,
    $PATHBASE/$VERSION/flectra/addons
#################################################################
xmlrpc_port = $PORT
dbfilter = iplusfl
logrotate = True
limit_time_real = 6000
limit_time_cpu = 6000
" | sudo tee --append $PATHBASE/config/$PROJECT_NAME.conf

sudo rm /etc/systemd/system/$PROJECT_NAME.service
sudo touch /etc/systemd/system/$PROJECT_NAME.service
sudo chmod +x /etc/systemd/system/$PROJECT_NAME.service
echo "
[Unit]
Description=$PROJECT_NAME
After=postgresql.service
[Service]
Type=simple
User=$usuario
ExecStart=$PATHBASE/$VERSION/venv/bin/python $PATHBASE/$VERSION/flectra/flectra-bin --config $PATHBASE/config/$PROJECT_NAME.conf
[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/$PROJECT_NAME.service
sudo systemctl daemon-reload
sudo systemctl enable $PROJECT_NAME.service
sudo systemctl start $PROJECT_NAME

sudo chown -R $usuario: $PATHBASE

echo "$PROJECT_NAME $VERSION Installation has finished!! ;) by dyangga.com"
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access from: http://$IP:$PORT  or http://localhost:$PORT"



#sudo su - flectra -c "/opt/flectra/flectra/flectra-bin --addons-path=/opt/flectra/flectra/addons -s --stop-after-init"
#sudo mv /opt/flectra/.flectrarc /etc/flectra/flectra.conf
#sudo sed -i "s,^\(logfile = \).*,\1"/var/log/flectra/flectra-server.log"," /etc/flectra/flectra.conf
#sudo sed -i "s,^\(logrotate = \).*,\1"True"," /etc/flectra/flectra.conf
#sudo sed -i "s,^\(proxy_mode = \).*,\1"True"," /etc/flectra/flectra.conf
#sudo cp /opt/flectra/flectra/debian/init /etc/init.d/flectra && chmod +x /etc/init.d/flectra
#sudo ln -s /opt/flectra/flectra/flectra-bin /usr/bin/flectra
#sudo update-rc.d -f flectra start 20 2 3 4 5 .
#sudo service flectra restart
