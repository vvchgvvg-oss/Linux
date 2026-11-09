FROM nginx:1.27-alpine
RUN apk add --no-cache apache2-utils
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/secure-gateway
RUN chmod 0755 /usr/local/bin/secure-gateway
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/secure-gateway"]
