#!/bin/bash
custom_echo () {
    echo "--------------------------------- $@"
}
install () {
    custom_echo echo "INSTALLING $@"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq --fix-missing --allow-unauthenticated $@
}

VENV_LOCATION = "$HOME/.pgadmin4"
PG_IP = ${1:-0.0.0.0}  
PG_PORT = ${2:-5050}

#python
install libpq-dev
install python3
install python3-dev
install python3-venv
install python3-pip

#pgadmin
custom_echo "CREATING VENV FOR PGADMIN"
python3 -m venv $VENV_LOCATION
. pgadmin4/bin/activate
pip install --upgrade pip
pip install wheel
pip install setuptools --upgrade
echo "Downloading PgAdmin..."
wget -q https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v2.1/pip/pgadmin4-2.1-py2.py3-none-any.whl
pip install pgadmin4-2.1-py2.py3-none-any.whl
sudo rm pgadmin4-2.1-py2.py3-none-any.whl
deactivate

custom_echo "CONFIGURING PGADMIN"
sudo echo "SERVER_MODE = False" >> $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/config_local.py
sudo echo "DEFAULT_SERVER = '$PG_IP'" >> $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/config_local.py
sudo echo "DEFAULT_SERVER_PORT = $PG_PORT" >> $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/config_local.py
sudo sed -i -e '1i#!/usr/bin/env python\' $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/pgAdmin4.py
sudo chmod +x  $VENV_LOCATION/lib/python3.5/site-packages/pgadmin4/pgAdmin4.py

custom_echo "CREATING THE SERVICE"

sudo echo '
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

echo -e "All done! Go to:\n\thttp://$PG_IP:$PG_PORT"
