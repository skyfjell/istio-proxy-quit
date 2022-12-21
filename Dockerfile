FROM alpine:3.17.0

RUN addgroup -S proxyquit -g 1337 && \
    adduser -S -g 1337 -u 1337 proxyquit && \
    apk add curl jq

WORKDIR /app

COPY main.sh /app/main.sh
RUN chmod 0755 /app/main.sh

USER proxyquit

ENTRYPOINT ["/app/main.sh"]
