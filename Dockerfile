FROM thethingsnetwork/lorawan-stack:3.13.2

ARG TAG
ARG BUILD_DATE

# Image metadata
LABEL maintainer="Xose Pérez <xose.perez@gmail.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=${BUILD_DATE}
LABEL org.label-schema.name="The Things Stack LoRaWAN Network Server"
LABEL org.label-schema.description="The Things Stack LoRaWAN Network Server"
LABEL org.label-schema.vcs-type="Git"
LABEL org.label-schema.vcs-url="https://github.com/xoseperez/the-things-stack-docker"
LABEL org.label-schema.vcs-ref=${TAG}
LABEL org.label-schema.license="Apache 2.0"

USER root:root
RUN apk --update --no-cache add openssl jq

ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl_linux-arm /usr/bin/cfssl
ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssljson_linux-arm /usr/bin/cfssljson
RUN chmod +x /usr/bin/cfssl*

RUN mkdir /srv/data
RUN chmod 777 /srv/data
VOLUME [ "/srv/data" ]

WORKDIR /home/thethings

COPY runner/* .
RUN chown thethings:thethings /home/thethings/*

ENTRYPOINT [ "./entrypoint.sh" ]

USER thethings:thethings