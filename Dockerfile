# check=skip=InvalidDefaultArgInFrom
# The upstream version has no default here: docker-bake.hcl is its one source.
# The Things Stack (open source) image, plus a start script that configures it
# from environment variables. Built with docker-bake.hcl, which sets the
# upstream version.

ARG UPSTREAM_VERSION
FROM thethingsnetwork/lorawan-stack:${UPSTREAM_VERSION}

ARG VERSION=dev

USER root:root

# bash and envsubst run the start script, openssl creates the self-signed
# certificates, and jq builds the CLI credentials and the balena API requests.
RUN apk add --no-cache bash gettext-envsubst openssl jq

# Certificates, keys and markers the start script keeps across restarts.
RUN install -d -o thethings -g thethings -m 0750 /srv/data
VOLUME ["/srv/data"]

WORKDIR /home/thethings
COPY runner/ ./
ENV PATH="${PATH}:/home/thethings" \
    IMAGE_VERSION=${VERSION}

USER thethings:thethings

ENTRYPOINT ["bash", "start"]
