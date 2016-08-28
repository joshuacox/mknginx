.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

build: NAME TAG builddocker

# run a  container temporarily to grab the config directory
temp: rm build runtemp

prod: NGINX_DATADIR rm build runprod

next: grab rmtemp prod

runtemp: IP TAG NAME
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-p $(IP):80:80 \
	-p $(IP):443:443 \
	-t $(TAG)

runprod: IP TAG NAME
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	echo " the nginx data dir is $(NGINX_DATADIR)"
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-p $(IP):80:80 \
	-p $(IP):443:443 \
	--net=host \
	-v $(NGINX_DATADIR)/etc/nginx:/etc/nginx \
	-v $(NGINX_DATADIR)/html:/usr/share/nginx/html \
	-v "$(NGINX_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-t $(TAG)

builddocker:
	/usr/bin/time -v docker build -t `cat TAG` .

kill:
	-@docker kill `cat cid`
	-@docker kill `cat genCID`
	-@docker kill `cat letsencryptCID`

rm-image:
	-@docker rm `cat cid`
	-@rm cid
	-@docker rm `cat genCID`
	-@rm genCID
	-@docker rm `cat letsencryptCID`
	-@rm letsencryptCID

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

EMAIL:
	@while [ -z "$$EMAIL" ]; do \
		read -r -p "Enter the name you wish to associate with this container [EMAIL]: " EMAIL; echo "$$EMAIL">>EMAIL; cat EMAIL; \
	done ;

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

SITENAME:
	@while [ -z "$$SITENAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [SITENAME]: " SITENAME; echo "$$SITENAME">>SITENAME; cat SITENAME; \
	done ;

DOMAIN:
	@while [ -z "$$DOMAIN" ]; do \
		read -r -p "Enter the name you wish to associate with this container [DOMAIN]: " DOMAIN; echo "$$DOMAIN">>DOMAIN; cat DOMAIN; \
	done ;

IP:
	@while [ -z "$$IP" ]; do \
		read -r -p "Enter the name you wish to associate with this container [IP]: " IP; echo "$$IP">>IP; cat IP; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the name you wish to associate with this container [PORT]: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

rmall: rm

grab: grabnginxdir

grabnginxdir: NGINX_DATADIR
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	mkdir -p $(NGINX_DATADIR)/etc
	docker cp `cat cid`:/usr/share/nginx/html - |sudo tar -C $(NGINX_DATADIR)/ -pxvf -
	docker cp `cat cid`:/etc/nginx - |sudo tar -C $(NGINX_DATADIR)/etc -pxvf -

NGINX_DATADIR:
	@while [ -z "$$NGINX_DATADIR" ]; do \
		read -r -p "Enter the destination of the nginx data directory you wish to associate with this container [NGINX_DATADIR]: " NGINX_DATADIR; echo "$$NGINX_DATADIR">>NGINX_DATADIR; cat NGINX_DATADIR; \
	done ;

proxy: cid genCID letsencryptCID

cid: IP NAME
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval NAME := $(shell cat NAME))
	$(eval IP := $(shell cat IP))
	docker pull nginx
	docker run -d -p $(IP):80:80 -p $(IP):443:443 \
	--name=$(NAME) \
	--cidfile="cid" \
	-v $(NGINX_DATADIR)/etc/nginx/certs:/etc/nginx/certs:ro \
	-v $(NGINX_DATADIR)/etc/nginx/vhost.d:/etc/nginx/vhost.d \
	-v $(NGINX_DATADIR)/etc/nginx/conf.d:/etc/nginx/conf.d \
	-v "$(NGINX_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v $(NGINX_DATADIR)/html:/usr/share/nginx/html \
	nginx

template:
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	@-mkdir -p  $(NGINX_DATADIR)/etc/docker-gen/templates
	curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > $(NGINX_DATADIR)/etc/docker-gen/templates/nginx.tmpl 

genCID:
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval NAME := $(shell cat NAME))
	docker run -d \
	--cidfile="genCID" \
	--name=$(NAME)-gen \
	--volumes-from $(NAME) \
	-v $(NGINX_DATADIR)/etc/docker-gen/templates/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	jwilder/docker-gen -notify-sighup $(NAME) -watch -only-exposed -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

letsencryptCID:
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval NAME := $(shell cat NAME))
	--cidfile="cid" \
	docker run -d \
	--name=$(NAME)-letsencrypt \
	--cidfile="letsencryptCID" \
	-e "NGINX_DOCKER_GEN_CONTAINER=$(NAME)-gen" \
	--volumes-from $(NAME) \
	-v $(NGINX_DATADIR)/etc/nginx/certs:/etc/nginx/certs:rw \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	jrcs/letsencrypt-nginx-proxy-companion

test: letstestCID

letstestCID:
	@while [ -z "$$HOSTNAME" ]; do \
		read -r -p "Enter the destination of the nginx data directory you wish to associate with this container [HOSTNAME]: " HOSTNAME; echo "$$HOSTNAME"; \
	done ;
	docker run -d \
	--cidfile="letstestCID" \
	-e "VIRTUAL_HOST=$$HOSTNAME" \
	-e "LETSENCRYPT_HOST=$$HOSTNAME" \
	-e "LETSENCRYPT_EMAIL=webmaster@$$HOSTNAME" \
	tutum/apache-php


cert:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval IP := $(shell cat IP))
	read -r -p "Enter the destination of the nginx data directory you wish to associate with this container [HOSTNAME]: " HOSTNAME; echo "$$HOSTNAME" >$(TMP)/HOSTNAME; \
	read -r -p "Enter the destination of the nginx data directory you wish to associate with this container [EMAIL]: " EMAIL; echo "$$EMAIL" > $(TMP)/EMAIL; \
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	docker run -it --rm -p $(IP):443:443 -p $(IP):80:80 --name certbot \
	-v "$(NGINX_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v "$(NGINX_DATADIR)/var/lib/letsencrypt:/var/lib/letsencrypt" \
	quay.io/letsencrypt/letsencrypt:latest auth --standalone -n -d "`cat $(TMP)/HOSTNAME`" --agree-tos --email "`cat $(TMP)/EMAIL`"
	rm -Rf $(TMP)

renew:
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval IP := $(shell cat IP))
	docker run -it --rm -p $(IP):443:443 -p $(IP):80:80 --name certbot \
	-v "$(NGINX_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v "$(NGINX_DATADIR)/var/lib/letsencrypt:/var/lib/letsencrypt" \
	quay.io/letsencrypt/letsencrypt:latest renew

site: SITENAME DOMAIN IP PORT NGINX_DATADIR
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval PORT := $(shell cat PORT))
	$(eval IP := $(shell cat IP))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval SITENAME := $(shell cat SITENAME))
	echo $(PORT)
	echo $(SITENAME)
	echo $(DOMAIN)
	cp site.template $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_PORT/$(PORT)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_IP/$(IP)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_DOMAIN/$(DOMAIN)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	sed -i "s/REPLACEME_SITENAME/$(SITENAME)/g" $(TMP)/$(SITENAME).$(DOMAIN)
	cat $(TMP)/$(SITENAME).$(DOMAIN)
	sudo cp $(TMP)/$(SITENAME).$(DOMAIN) $(NGINX_DATADIR)/etc/nginx/sites-available/
	cd $(NGINX_DATADIR)/etc/nginx/sites-enabled/ ; \
	sudo rm -f $(SITENAME).$(DOMAIN)  ; \
	sudo ln -s ../sites-available/$(SITENAME).$(DOMAIN) ./
	ls -lh $(NGINX_DATADIR)/etc/nginx/sites-enabled/ 
	rm -Rf $(TMP)

sitecert: EMAIL SITENAME DOMAIN
	$(eval NGINX_DATADIR := $(shell cat NGINX_DATADIR))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval EMAIL := $(shell cat EMAIL))
	$(eval SITENAME := $(shell cat SITENAME))
	$(eval IP := $(shell cat IP))
	docker run -it --rm -p $(IP):443:443 -p $(IP):80:80 --name certbot \
	-v "$(NGINX_DATADIR)/etc/letsencrypt:/etc/letsencrypt" \
	-v "$(NGINX_DATADIR)/var/lib/letsencrypt:/var/lib/letsencrypt" \
	quay.io/letsencrypt/letsencrypt:latest auth --standalone -n -d "$(SITENAME).$(DOMAIN)" --agree-tos --email "$(EMAIL)"

nusite: cleansite site

cleansite:
	-@rm SITENAME
	-@rm PORT
	-@rm DOMAIN
	-@rm IP
