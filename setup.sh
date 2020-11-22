#!/bin/sh

# upgrade
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# install base deps
sudo apt-get install build-essential git htop iotop nmon lsof screen -y

# install node 10
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash
sudo apt-get install -y nodejs
sudo npm install npm@latest -g

# pm2
sudo npm install -g pm2
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u pi --hp /home/pi

# cncjs
sudo npm install -g cncjs@latest --unsafe-perm
pm2 start $(which cncjs) -- --port 8000 -m /tinyweb:/home/pi/tinyweb
pm2 save
pm2 list

# jscut
git clone https://github.com/tbfleming/jscut.git
cd jscut/js
wget http://api.jscut.org/js/cam-cpp.js
cd ../..

# kiri:moto
git clone https://github.com/GridSpace/grid-apps.git
cd grid-apps
git checkout master
cat package.json | grep -v '"version"' | sed 's/"name"/"version": "99.99.99", "name"/' > package.json.tmp
mv package.json.tmp package.json
npm i
git reset --hard HEAD
sudo npm install -g @gridspace/app-server
echo '{' > app.json
echo '  "apps": [' >> app.json
echo '    {' >> app.json
echo '      "name": "gsapps",' >> app.json
echo '      "script": "'$(which gs-app-server)'",' >> app.json
echo '      "exec_interpreter": "node",' >> app.json
echo '      "cwd": "'$(pwd)'"' >> app.json
echo '    }' >> app.json
echo '  ]' >> app.json
echo '}' >> app.json
pm2 start app.json
pm2 save

# nginx
sudo apt install nginx -y

sudo systemctl enable nginx
sudo systemctl stop nginx

echo 'user www-data;' | sudo tee /etc/nginx/nginx.conf
echo 'worker_processes auto;' | sudo tee -a /etc/nginx/nginx.conf
echo 'pid /run/nginx.pid;' | sudo tee -a /etc/nginx/nginx.conf
echo 'include /etc/nginx/modules-enabled/*.conf;' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo 'events {' | sudo tee -a /etc/nginx/nginx.conf
echo '        worker_connections 768;' | sudo tee -a /etc/nginx/nginx.conf
echo '}' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo 'http {' | sudo tee -a /etc/nginx/nginx.conf
echo '        sendfile on;' | sudo tee -a /etc/nginx/nginx.conf
echo '        tcp_nopush on;' | sudo tee -a /etc/nginx/nginx.conf
echo '        tcp_nodelay on;' | sudo tee -a /etc/nginx/nginx.conf
echo '        keepalive_timeout 65;' | sudo tee -a /etc/nginx/nginx.conf
echo '        types_hash_max_size 2048;' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo '        include /etc/nginx/mime.types;' | sudo tee -a /etc/nginx/nginx.conf
echo '        default_type application/octet-stream;' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo '        access_log /var/log/nginx/access.log;' | sudo tee -a /etc/nginx/nginx.conf
echo '        error_log /var/log/nginx/error.log;' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo '        gzip on;' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo '        upstream jscut {' | sudo tee -a /etc/nginx/nginx.conf
echo '                server 127.0.0.1:8000;' | sudo tee -a /etc/nginx/nginx.conf
echo '        }' | sudo tee -a /etc/nginx/nginx.conf
echo '' | sudo tee -a /etc/nginx/nginx.conf
echo '        server {' | sudo tee -a /etc/nginx/nginx.conf
echo '                location / {' | sudo tee -a /etc/nginx/nginx.conf
echo '                        proxy_pass http://jscut;' | sudo tee -a /etc/nginx/nginx.conf
echo '                }' | sudo tee -a /etc/nginx/nginx.conf
echo '                location /jscut {' | sudo tee -a /etc/nginx/nginx.conf
echo '                        alias /home/pi/jscut;' | sudo tee -a /etc/nginx/nginx.conf
echo '                }' | sudo tee -a /etc/nginx/nginx.conf
echo '                location /kiri {' | sudo tee -a /etc/nginx/nginx.conf
echo '                        return 301 http://$host:8080/kiri;' | sudo tee -a /etc/nginx/nginx.conf
echo '                }' | sudo tee -a /etc/nginx/nginx.conf
echo '        }' | sudo tee -a /etc/nginx/nginx.conf
echo '}' | sudo tee -a /etc/nginx/nginx.conf

sudo systemctl start nginx

echo 'Install done:'
echo ' - http://127.0.0.1: cncjs (control your CNC & run gcode)'
echo ' - http://127.0.0.1/jscut: SVG to CNC GCODE'
echo ' - http://127.0.0.1/kiri: STL to CNC GCODE'
echo ''
echo 'Have fun !'
