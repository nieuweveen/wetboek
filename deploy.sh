# Deployment script voor VPS
#!/bin/bash

# Installeer dependencies
sudo apt update
sudo apt install python3-pip nginx -y
pip3 install mkdocs-material

# Build de site
mkdocs build

# Copy naar nginx directory
sudo cp -r site/* /var/www/html/

# Nginx configuratie met SSL redirect
sudo tee /etc/nginx/sites-available/nieuweveen << EOF
server {
    listen 80;
    server_name wetboek.nieuweveen.com www.wetboek.nieuweveen.com;
    
    # Redirect alle HTTP naar HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name wetboek.nieuweveen.com www.wetboek.nieuweveen.com;
    
    root /var/www/html;
    index index.html;
    
    # SSL configuratie (wordt automatisch ingevuld door certbot)
    ssl_certificate /etc/letsencrypt/live/wetboek.nieuweveen.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/wetboek.nieuweveen.com/privkey.pem;
    
    # SSL security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        application/atom+xml
        application/geo+json
        application/javascript
        application/x-javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rdf+xml
        application/rss+xml
        application/xhtml+xml
        application/xml
        font/eot
        font/otf
        font/ttf
        image/svg+xml
        text/css
        text/javascript
        text/plain
        text/xml;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Disable default nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Enable site
sudo ln -sf /etc/nginx/sites-available/nieuweveen /etc/nginx/sites-enabled/

# Test nginx config
sudo nginx -t

# Install certbot
sudo apt install snapd -y
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# Temporarily start nginx without SSL for certificate generation
sudo systemctl start nginx

echo "=== SSL Certificate Setup ==="
echo "Vervang 'wetboek.nieuweveen.com' door je echte domein voordat je dit script uitvoert!"
echo "Voer het volgende commando uit om SSL te configureren:"
echo "sudo certbot --nginx -d wetboek.nieuweveen.com -d www.wetboek.nieuweveen.com --agree-tos --no-eff-email"

# Automatic renewal setup
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo tee -a /etc/crontab

echo "=== Deployment Complete ==="
echo "Site is beschikbaar op: https://wetboek.nieuweveen.com"
echo "Vergeet niet je domein aan te passen in het script!"
