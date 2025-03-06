FROM crystallang/crystal:latest-alpine

RUN apk add --no-cache libjpeg-turbo-dev libjpeg-turbo

COPY . /workspace

WORKDIR /workspace

CMD crystal spec