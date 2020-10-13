FROM httpd:2.4.33-alpine
RUN apk update; \
    apk upgrade;
RUN apk add apache2-ssl
RUN sed -i '/LoadModule rewrite_module/s/^#//g' /usr/local/apache2/conf/httpd.conf

ARG DOMAINNAME
# Copy apache vhost file to proxy php requests to php-fpm container
COPY ${DOMAINNAME}.conf /usr/local/apache2/conf/
RUN echo "Include /usr/local/apache2/conf/${DOMAINNAME}.conf" \
    >> /usr/local/apache2/conf/httpd.conf

