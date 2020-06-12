#!/bin/sh
yum update -y
yum install httpd -y
service httpd start
chkonfig httpd on
echo "<html><h1>Hello from CICD !</h2></html>" > /var/www/html/index.html
