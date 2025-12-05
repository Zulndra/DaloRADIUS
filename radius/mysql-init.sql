-- Grant permission untuk radiususer dari any host
GRANT ALL PRIVILEGES ON radius.* TO 'radiususer'@'%' IDENTIFIED BY 'radiuspass';
FLUSH PRIVILEGES;
