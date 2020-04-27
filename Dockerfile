# Define arguments & default values

# Builder stage
FROM golang:1-alpine as builder

# Define arguments & default values for builder stage
ARG KUBE_PROMPT_VERSION=v1.0.10

COPY Dockerfile.packages.builder.txt /etc/apk/packages.txt
RUN apk add --no-cache --update $(grep -v '^#' /etc/apk/packages.txt)

RUN git clone --depth 1 --single-branch -b $KUBE_PROMPT_VERSION https://github.com/c-bata/kube-prompt.git kube-prompt && \
  cd kube-prompt/ && \
  GO111MODULE=on go build . && \
  cp kube-prompt /usr/bin

# Main stage
FROM aroq/toolbox-variant:0.1.51

COPY Dockerfile.packages.txt /etc/apk/packages.txt
RUN apk add --no-cache --update $(grep -v '^#' /etc/apk/packages.txt)

COPY --from=builder /usr/bin/kube-prompt /usr/bin

# Install kubectl
ARG KUBECTL_VERSION=v1.18.0
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    mkdir -p ~/completions && \
    kubectl completion bash > ~/completions/kubectl.bash && \
    echo "source ~/completions/kubectl.bash" >> /etc/profile

# Install kube-ps1
ARG KUBE_PS1_VERSION=0.7.0
RUN curl -L https://github.com/jonmosco/kube-ps1/archive/v${KUBE_PS1_VERSION}.tar.gz | tar xz && \
    mkdir -p ~/k8s-prompt && \
    cp -fR ./kube-ps1-${KUBE_PS1_VERSION}/* ~/k8s-prompt/ && \
    rm -fr ../kube-ps1-${KUBE_PS1_VERSION} && \
    echo "source ~/k8s-prompt/kube-ps1.sh" >> /etc/profile && \
    echo "export PS1='\W \$(kube_ps1)\n> '" >> /etc/profile

# Setup kubectl aliases
RUN rm -fr /tmp/install-utils && \
    echo "alias k=kubectl" >> /etc/profile && \
    echo "alias kns=kubens" >> /etc/profile && \
    echo "complete -o default -F __start_kubectl k" >> /etc/profile

# Install kubectx/kubens
ARG KUBECTX_VERSION=0.8.0
RUN curl -L https://github.com/ahmetb/kubectx/archive/v$KUBECTX_VERSION.tar.gz | \
    tar xz && \
    cd ./kubectx-$KUBECTX_VERSION && \
    mv kubectx kubens /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubectx && \
    chmod +x /usr/local/bin/kubens && \
    cp completion/kubectx.bash ~/completions/ && \
    cp completion/kubens.bash  ~/completions/ && \
    echo "source ~/completions/kubectx.bash" >> /etc/profile && \
    echo "source ~/completions/kubens.bash" >> /etc/profile && \
    cd ../ && \
    rm -fr ./kubectx-$KUBECTX_VERSION

# Install k9s
ARG K9S_VERSION=0.19.3
RUN mkdir -p k9s && \
    curl -L https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_x86_64.tar.gz | \
    tar xz -C k9s && \
    mv k9s/k9s /usr/local/bin && \
    rm -fR k9s

# Install stern
ARG STERN_VERSION=1.11.0
RUN curl -o stern -L https://github.com/wercker/stern/releases/download/${STERN_VERSION}/stern_linux_amd64 && \
    chmod a+x stern && \
    mv stern /usr/local/bin

RUN mkdir -p /toolbox-k8s
COPY tools /toolbox/toolbox-k8s/tools

ENV TOOLBOX_TOOL_DIRS toolbox,/toolbox/toolbox-k8s
ENV VARIANT_CONFIG_CONTEXT toolbox
ENV VARIANT_CONFIG_DIR toolbox

ENTRYPOINT ["/toolbox-k8s/tools/k8s"]
