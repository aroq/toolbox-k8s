FROM aroq/toolbox-cloud:0.1.5

RUN mkdir -p /toolbox-k8s
ADD tools /toolbox-k8s/tools

ENTRYPOINT ["/toolbox-k8s/tools/k8s"]

