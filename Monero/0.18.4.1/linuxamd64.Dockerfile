# Set base image
FROM debian:bookworm-slim

# Set necessary environment variables for the current Monero version and hash
ENV FILE=monero-linux-x64-v0.18.4.1.tar.bz2
ENV FILE_CHECKSUM=702ccb799c24160c0c76676d7a5b21a7e3432be47294d20e0a75451592f591b2

# Set SHELL options per https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get -y --no-install-recommends install bzip2 ca-certificates wget curl \
    && apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/*

# Download specified Monero tar.gz and verify downloaded binary against hardcoded checksum
RUN wget -qO $FILE https://downloads.getmonero.org/cli/$FILE && \
    echo "$FILE_CHECKSUM $FILE" | sha256sum -c - 

# Extract and set permissions on Monero binaries
RUN mkdir -p extracted && \
    tar -jxvf $FILE -C /extracted && \
    find /extracted/ -type f -print0 | xargs -0 chmod a+x && \
    find /extracted/ -type f -print0 | xargs -0 mv -t /usr/local/bin/ && \
    rm -rf extracted && rm $FILE

# Copy notifier script
COPY ./scripts /scripts/
RUN find /scripts/ -type f -print0 | xargs -0 chmod a+x

# Create monero user
RUN adduser --system --group --disabled-password monero && \
	mkdir -p /wallet /home/monero/.bitmonero && \
	chown -R monero:monero /home/monero/.bitmonero && \
	chown -R monero:monero /home/monero && \
	chown -R monero:monero /wallet

# Specify necessary volumes
VOLUME /home/monero/.bitmonero
VOLUME /wallet

# Expose p2p, RPC, and ZMQ ports
EXPOSE 18080
EXPOSE 18081
EXPOSE 18082

# Switch to user monero
USER monero
ENV HOME=/home/monero
