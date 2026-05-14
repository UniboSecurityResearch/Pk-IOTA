FROM kathara/base

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      iproute2 \
      net-tools \
      tcpreplay \
      iputils-ping \
      tcpdump \
 && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
