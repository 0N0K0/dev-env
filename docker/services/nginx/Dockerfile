FROM nginx:alpine

# Copy dynamic nginx configuration
COPY ./docker/services/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Create web directory
RUN mkdir -p /var/www/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
