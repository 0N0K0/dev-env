FROM nginx:alpine

# Copier la configuration Nginx dynamique
COPY ./docker/services/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Créer le répertoire web
RUN mkdir -p /var/www/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
