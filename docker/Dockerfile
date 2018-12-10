FROM alpine:3.8
ENV ADDITIONAL_COMMAND=true
RUN apk add --update --no-cache openssh-client expect bash grep && rm -rf /var/cache/apk/*
COPY ./*.sh /var/
CMD bash /var/run.sh
