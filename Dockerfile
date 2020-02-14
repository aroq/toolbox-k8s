FROM aroq/toolbox-cloud:0.1.5

RUN mkdir -p /toolbox-k8s
ADD tools /toolbox-k8s/tools
ADD variant-lib /toolbox-k8s/variant-lib

ENTRYPOINT ["/toolbox-k8s/tools/kubectl"]

