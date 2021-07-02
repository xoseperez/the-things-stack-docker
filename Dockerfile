FROM thethingsnetwork/lorawan-stack:3.13.2

USER root:root
RUN apk --update --no-cache add openssl jq

ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl_linux-arm /usr/bin/cfssl
ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssljson_linux-arm /usr/bin/cfssljson
RUN chmod +x /usr/bin/cfssl*

RUN mkdir /srv/data
RUN chmod 777 /srv/data
VOLUME [ "/srv/data" ]

COPY ttn-lw-stack-docker.yml.template /home/thethings/ttn-lw-stack-docker.yml.template
COPY entrypoint.sh /home/thethings/entrypoint.sh
RUN chown thethings:thethings /home/thethings/*
RUN chmod +x /home/thethings/entrypoint.sh

ENTRYPOINT [ "/home/thethings/entrypoint.sh" ]

USER thethings:thethings