FROM docker:stable

COPY *.sh /usr/local/bin/
RUN apk add --no-cache coreutils jq curl; \
    chmod 755 /usr/local/bin/*.sh;

ENTRYPOINT [ "/usr/local/bin/publish.sh" ]
