FROM alpine:3

ARG USER=rover
RUN addgroup -S $USER && adduser -S -G $USER $USER

ENV ARCH="x86_64-unknown-linux-musl"
ENV ROVER_VERSION="v0.1.5"
ENV ROVER_CHECKSUM="7c5ee024cdd80eb3f642e806d6923e92d413e6aec20c5e2bfa5d7f8fc943849a"
ENV ROVER_TARBALL="rover-${ROVER_VERSION}-${ARCH}.tar.gz"

WORKDIR /opt/rover/$ROVER_VERSION

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN wget -q https://github.com/apollographql/rover/releases/download/${ROVER_VERSION}/${ROVER_TARBALL} \
 && tar xf $ROVER_TARBALL --strip-components 1 \
 && ([ "$(sha256sum -b ./rover | cut -d ' ' -f1)" = "$ROVER_CHECKSUM" ] || (echo "!!! FATAL ERROR: ROVER EXECUTABLE CHECKSUM VALIDATION FAILED !!!" && exit 1)) \
 && rm $ROVER_TARBALL \
 && chmod 755 ./rover

ARG BUILD_TIMESTAMP
ARG VERSION
ENV BUILD_TIMESTAMP=$BUILD_TIMESTAMP VERSION=$VERSION
LABEL build-timestamp=$BUILD_TIMESTAMP version=$VERSION

COPY --chown=$USER:$USER ./run.sh ./run.sh

USER $USER:$USER

CMD ["./run.sh"]
