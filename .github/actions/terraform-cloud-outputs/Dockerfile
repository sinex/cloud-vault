FROM frostedcarbon/tfc-cli:v1.1 AS tfc-cli
FROM alpine:3.16
RUN apk add --update --no-cache ca-certificates
COPY --from=tfc-cli tfc-cli /bin/
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
