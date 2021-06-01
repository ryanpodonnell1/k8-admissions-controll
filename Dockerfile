FROM golang:1.16 as build
WORKDIR /app
COPY . /app
RUN GOARCH=amd64 CGO_ENABLED=0 GOOS=linux go build -o api .

# RUN openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/ssl/certs/key.pem \
#     -out /etc/ssl/certs/cert.pem -days 365 -subj "/C=US/ST=MN/L=Minneapolis/O=TGRC/CN=validator.tgrccloudsecurity.svc/SAN=" && \
#     chmod 644 /etc/ssl/certs/cert.pem && chmod 600 /etc/ssl/certs/key.pem


FROM scratch
COPY --from=build /app/api /bin/api
COPY ./certs/  /etc/ssl/certs/


EXPOSE 8080

ENTRYPOINT ["/bin/api"]
