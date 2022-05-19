ARG TAG
ARG VERSION
ARG BUILD_DATE
ARG ARCH
ARG REMOTE_TAG

FROM thethingsnetwork/lorawan-stack:${REMOTE_TAG}

ARG TAG
ARG VERSION
ARG BUILD_DATE
ARG ARCH
ARG REMOTE_TAG

# Image metadata
LABEL maintainer="Xose Pérez <xose.perez@gmail.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=${BUILD_DATE}
LABEL org.label-schema.name="The Things Stack LoRaWAN Network Server"
LABEL org.label-schema.description="The Things Stack LoRaWAN Network Server"
LABEL org.label-schema.version="${VERSION} based on ${REMOTE_TAG}"
LABEL org.label-schema.vcs-type="Git"
LABEL org.label-schema.vcs-url="https://github.com/xoseperez/the-things-stack-docker"
LABEL org.label-schema.vcs-ref=${TAG}
LABEL org.label-schema.arch=${ARCH}
LABEL org.label-schema.license="Apache 2.0"

USER root:root

# Certificate creation tools
RUN apk --update --no-cache add openssl jq
ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssl_linux-${ARCH} /usr/bin/cfssl
ADD https://github.com/cloudflare/cfssl/releases/download/1.2.0/cfssljson_linux-${ARCH} /usr/bin/cfssljson
RUN chmod +x /usr/bin/cfssl*

# Data folder
RUN mkdir /srv/data
RUN chmod 777 /srv/data
VOLUME [ "/srv/data" ]

WORKDIR /home/thethings

# Runner code
COPY runner/* .
RUN chown thethings:thethings /home/thethings/*
RUN chmod +x /home/thethings/*.sh

# Wait tool
ENV WAIT_VERSION 2.9.0
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait

USER thethings:thethings

ENTRYPOINT [ "./entrypoint.sh" ]
