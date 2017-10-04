FROM scratch

ENV K8S_SERVICE_LOCAL_HOST 0.0.0.0
ENV K8S_SERVICE_LOCAL_PORT 8080
ENV K8S_SERVICE_LOG_LEVEL 0

EXPOSE $K8S_SERVICE_LOCAL_PORT

COPY certs /etc/ssl/certs/
COPY bin/linux-amd64/k8s-service /

CMD ["/k8s-service"]