FROM httpd:2.4-alpine

# Installer les modules nécessaires
RUN apk add --no-cache \
    apache2-utils

# Copier la configuration Apache
COPY apache/vhost.conf /usr/local/apache2/conf/extra/vhost.conf

# Activer les modules nécessaires
RUN echo "LoadModule proxy_module modules/mod_proxy.so" >> /usr/local/apache2/conf/httpd.conf && \
    echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so" >> /usr/local/apache2/conf/httpd.conf && \
    echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /usr/local/apache2/conf/httpd.conf && \
    echo "Include conf/extra/vhost.conf" >> /usr/local/apache2/conf/httpd.conf

EXPOSE 80

CMD ["httpd-foreground"]
