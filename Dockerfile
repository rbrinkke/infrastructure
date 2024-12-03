# Gebruik het officiële Nginx image als basis
FROM nginx:latest

# Kopieer de aangepaste configuratie naar de container (optioneel)
# COPY nginx.conf /etc/nginx/nginx.conf

# Stel de werkdirectory in
WORKDIR /usr/share/nginx/html

# Kopieer statische bestanden naar de container (optioneel)
# COPY . /usr/share/nginx/html

# Exposeer poort 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

