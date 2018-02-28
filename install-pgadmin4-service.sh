#!/bin/bash

PG_IP=${1:-0.0.0.0}  
PG_PORT=${2:-5050}
VENV_LOCATION=${3:-"$HOME/.pgadmin4"}
PG_VERSION=${4:-2.1}

install () {
    echo "Installing $@"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq --fix-missing --allow-unauthenticated $@ > /dev/null 2>&1
}

install libpq-dev
install python3
install python3-dev
install python3-venv
install python3-pip

echo "Creating the virtual env..."
python3 -m venv $VENV_LOCATION
. $VENV_LOCATION/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install wheel > /dev/null 2>&1
pip install setuptools --upgrade > /dev/null 2>&1
echo "Downloading PgAdmin 4-$PG_VERSION..."
wget -q https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v$PG_VERSION/pip/pgadmin4-$PG_VERSION-py2.py3-none-any.whl
echo "Installing..."
pip install pgadmin4-$PG_VERSION-py2.py3-none-any.whl > /dev/null 2>&1
sudo rm pgadmin4-$PG_VERSION-py2.py3-none-any.whl
deactivate

echo "Configuring..."
sudo echo "SERVER_MODE = False" >> $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/config_local.py
sudo echo "DEFAULT_SERVER = '$PG_IP'" >> $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/config_local.py
sudo echo "DEFAULT_SERVER_PORT = $PG_PORT" >> $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/config_local.py
sudo sed -i -e '1i#!/usr/bin/env python\' $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/pgAdmin4.py
sudo chmod +x  $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/pgAdmin4.py

echo "Creating the service..."

sudo -u root echo '
[Unit]
Description=Pgadmin4 Service
After=network.target
 
[Service]
User= root
Group= root
WorkingDirectory=$VENV_LOCATION
Environment="PATH=$VENV_LOCATION/bin"
ExecStart="$VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/pgAdmin4.py"
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/pgadmin4.service

sudo -u root systemctl daemon-reload
sudo -u root systemctl enable pgadmin4
sudo -u root systemctl start pgadmin4

echo -e "\nAll done! Go to:\n\thttp://$PG_IP:$PG_PORT"
