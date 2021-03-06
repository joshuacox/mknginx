FROM debian:stretch
MAINTAINER Josh Cox <josh 'at' webhosting.coop>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
#ENV NGINX_VERSION 1.9.9-1~jessie
#apt-get install -y ca-certificates nginx=${NGINX_VERSION} && \

RUN apt-get -qq update ; \
apt-get -qqy dist-upgrade ; \
apt-get -qqy --no-install-recommends install locales \
git sudo procps ca-certificates wget pwgen supervisor; \
apt-get install -y ca-certificates nginx && \
echo 'en_US.ISO-8859-15 ISO-8859-15'>>/etc/locale.gen ; \
echo 'en_US ISO-8859-1'>>/etc/locale.gen ; \
echo 'en_US.UTF-8 UTF-8'>>/etc/locale.gen ; \
locale-gen ; \
apt-get -y autoremove ; \
apt-get clean ; \
rm -Rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
