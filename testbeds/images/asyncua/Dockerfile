FROM kathara/base

ENV PIP_BREAK_SYSTEM_PACKAGES=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      iproute2 \
      net-tools \
      python3 \
      python3-pip \
      openssl \
 && python3 -m pip install --break-system-packages \
      asyncua \
      cryptography \
 && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
