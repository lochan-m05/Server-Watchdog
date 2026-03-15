
FROM alpine:3.14

WORKDIR /home/Watchdog

RUN apk add --no-cache bash jq curl util-linux procps

COPY . /home/Watchdog
RUN chmod +x main.sh

CCMD ["bash", "maih.sh"]