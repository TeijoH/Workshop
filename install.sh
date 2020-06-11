#!/bin/sh
yum install -y httpd
service start httpd
chkonfig httpd on
echo "<html><h1>Hello from CICD !</h2></html>" > /var/www/html/index.html
