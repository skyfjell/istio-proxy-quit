FROM alpine:3.17.0

RUN addgroup -S kuser && \
    adduser -S -G kuser kuser && \
    apk add curl jq

WORKDIR /app

COPY main.sh /app/main.sh
RUN chmod 0755 /app/main.sh

USER kuser

ENTRYPOINT ["/app/main.sh"]