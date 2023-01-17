#!/bin/bash
# Script to deploy a very simple web application.
# The web app has a customizable image and some text.

# Set up apache first.
sudo apt-get update && sudo apt-get dist-upgrade

sudo apt -y -f install apache2
sudo systemctl enable apache2
sudo systemctl start apache2
sudo chown -R ubuntu:ubuntu /var/www/html


echo "Creating /var/www/html/index.html"

cat << EOM > /var/www/html/index.html
<html>
  <head><title>HashiCat Live Demo Build - Meow!</title></head>
  <body>
  <div style="width:800px;margin: 0 auto">

  <!-- BEGIN -->
  <center><img src="http://placekitten.com/600/400"></img></center>
  <center><h2>Meow World!</h2></center>
  Welcome to HashiCat - Live Demo Build.
  <!-- END -->

  </div>
  </body>
</html>
EOM

echo "deploy-app.sh Script Complete."
