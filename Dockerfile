FROM thethingsnetwork/lorawan-stack:3.13.2

USER root:root
RUN apk --update --no-cache add openssl jq

ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl_linux-arm /usr/bin/cfssl
ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssljson_linux-arm /usr/bin/cfssljson
RUN chmod +x /usr/bin/cfssl*

RUN mkdir /srv/data
RUN chmod 777 /srv/data
VOLUME [ "/srv/data" ]

WORKDIR /home/thethings

COPY ttn-lw-stack-docker.yml.template ./ttn-lw-stack-docker.yml.template
COPY entrypoint.sh ./entrypoint.sh
COPY balena.sh ./balena.sh
RUN chmod +x ./entrypoint.sh
RUN chown thethings:thethings /home/thethings/*

ENTRYPOINT [ "./entrypoint.sh" ]

USER thethings:thethings