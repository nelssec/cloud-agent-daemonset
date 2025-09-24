# Qualys Cloud Agent - Universal Multi-Architecture Build
# Single image containing all packages for deployment anywhere

ARG BASE_IMAGE=art-hq.intranet.qualys.com:5006/secure/oraclelinux:8-slim
ARG VERSION=1.0.0

FROM ${BASE_IMAGE}

ARG VERSION

LABEL maintainer="anelson@qualys.com" \
      description="Qualys Cloud Agent for Kubernetes - Universal Image" \
      version="${VERSION}" \
      vendor="Qualys Inc."

# Install minimal required packages
RUN set -eux; \
    if command -v dnf >/dev/null 2>&1; then \
        dnf update -y && \
        dnf install -y --setopt=install_weak_deps=False \
            systemd \
            procps-ng \
            findutils && \
        dnf clean all; \
    elif command -v microdnf >/dev/null 2>&1; then \
        microdnf update && \
        microdnf install -y \
            systemd \
            procps-ng \
            findutils && \
        microdnf clean all; \
    else \
        yum update -y && \
        yum install -y \
            systemd \
            procps-ng \
            findutils && \
        yum clean all; \
    fi; \
    rm -rf /var/cache/* /tmp/* /var/log/* \
           /usr/share/doc /usr/share/man /usr/share/info \
           /usr/share/licenses /usr/share/locale/*; \
    mkdir -p /opt/qualys /tmp/qualys-work; \
    printf '#!/bin/sh\ntest -d /opt/qualys && ls /opt/qualys/*.rpm >/dev/null 2>&1 && echo "OK"\n' > /usr/local/bin/healthcheck; \
    chmod +x /usr/local/bin/healthcheck

# Copy all packages for universal deployment
COPY packages/qualys-cloud-agent*.rpm packages/qualys-cloud-agent*.deb /opt/qualys/

# Set permissions and validate
RUN chmod 644 /opt/qualys/* && \
    chown -R root:root /opt/qualys && \
    echo "Packages included:" && \
    ls -lh /opt/qualys/ && \
    if [ -z "$(ls -A /opt/qualys/)" ]; then \
        echo "ERROR: No packages found in image"; \
        exit 1; \
    fi

WORKDIR /opt/qualys

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["/usr/local/bin/healthcheck"]

USER root

ENTRYPOINT ["sleep"]
CMD ["infinity"]
