# syntax=docker/dockerfile:1.4
# Use the Ubuntu 24.04 devcontainer base image with AMD64 architecture
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:ubuntu24.04

##############################
# Define build arguments and set defaults
##############################
ARG JAVA_VERSION=17
ARG NODE_VERSION=16.20.0
ARG GO_VERSION=1.23.8

# Propagate these versions as environment variables so they are available at runtime
ENV JAVA_VERSION=${JAVA_VERSION}
ENV NODE_VERSION=${NODE_VERSION}
ENV GO_VERSION=${GO_VERSION}

##############################
# Install prerequisites for Docker installation
##############################
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*

##############################
# Set up Docker's official GPG key and repository
##############################
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

##############################
# Install Docker Engine, Docker CLI, containerd, and Docker Compose plugin
##############################
RUN apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Optional: Add the default user (assumed as 'vscode') to the docker group so docker commands work without sudo
ARG USERNAME=vscode
RUN usermod -aG docker ${USERNAME}

##############################
# Install Amazon Corretto ${JAVA_VERSION} (Java)
##############################
RUN apt-get update && apt-get install -y wget gnupg && \
    mkdir -p /usr/share/keyrings && \
    wget -qO- https://apt.corretto.aws/corretto.key | gpg --dearmor | tee /usr/share/keyrings/corretto.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/corretto.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list && \
    apt-get update && \
    apt-get install -y java-${JAVA_VERSION}-amazon-corretto-jdk && \
    rm -rf /var/lib/apt/lists/*

##############################
# Install nvm and Node.js v${NODE_VERSION} using nvm
##############################
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# Install Node.js with nvm; note the version comes from the NODE_VERSION env variable.
RUN bash -c "source $NVM_DIR/nvm.sh && nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION}"
# Update PATH so that the installed Node.js binary is available globally
ENV PATH=$NVM_DIR/versions/node/v${NODE_VERSION}/bin:$PATH

##############################
# Install Golang v${GO_VERSION}
##############################
RUN set -eux; \
    curl -fSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o "go${GO_VERSION}.linux-amd64.tar.gz"; \
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"; \
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
# Add Go binary directory to PATH
ENV PATH="/usr/local/go/bin:${PATH}"


##############################
# Install Socat
##############################
RUN apt-get update && apt-get install -y socat


# Run entrypoint script to set up the environment
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
