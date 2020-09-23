FROM golang:1.15-alpine
WORKDIR /go/src/app
COPY ./code .
COPY ./lib /usr/local/go/src/lib
RUN go install .
CMD ["/go/bin/control-plane"]
