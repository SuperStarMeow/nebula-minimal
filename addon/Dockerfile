ARG BUILD_FROM
FROM ${BUILD_FROM}

# Version bundled into the image; "latest" in the app configuration maps to it.
ARG NEBULA_VERSION=1.11.2

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates curl

COPY scripts/install-nebula.sh scripts/select-nebula.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install-nebula.sh /usr/local/bin/select-nebula.sh \
    && install-nebula.sh "${NEBULA_VERSION}" /usr/local/bin

ENV NEBULA_BUNDLED_VERSION=${NEBULA_VERSION}

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
