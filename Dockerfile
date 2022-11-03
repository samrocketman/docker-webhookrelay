ARG base=alpine
FROM ${base}

RUN set -ex; \
  # Prerequisites
  apk add --no-cache build-base; \
  # Directory structure and permissions
  mkdir -p base/bin base/usr/bin base/tmp base/var/tmp base/etc base/home/nonroot base/sbin base/root; \
  chmod 700 /root; \
  chown root:root /root; \
  chmod 1777 base/tmp base/var/tmp; \
  chown 65532:65532 base/home/nonroot; \
  chmod 750 base/home/nonroot; \
  # UID and GID
  echo 'root:x:0:' > /base/etc/group; \
  echo 'nonroot:x:65532:' >> /base/etc/group; \
  echo 'root:x:0:0:root:/root:/sbin/nologin' > /base/etc/passwd; \
  echo 'nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin' >> /base/etc/passwd; \
  # init binary
  wget -O base/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_"`uname -m`"; \
  chmod 755 base/bin/dumb-init; \
  # nologin binary
  echo 'int main() { return 1; }' > nologin.c; \
  gcc -Os -no-pie -static -std=gnu99 -s -Wall -Werror -o base/sbin/nologin nologin.c; \
  echo "Minimal Container version $VERSION" > /etc/issue


RUN set -ex; \
  arch="`uname -m`"; \
  if [ "$arch" = x86_64 ]; then \
    wget -O base/bin/relay https://storage.googleapis.com/webhookrelay/downloads/relay-linux-amd64; \
  elif [ "$arch" = aarch64 ]; then \
    wget -O base/bin/relay https://storage.googleapis.com/webhookrelay/downloads/relay-linux-aarch64; \
  else \
    echo "Could not find binary for arch $arch" >&2; \
    exit 1; \
  fi; \
  chmod 755 base/bin/relay

RUN set -ex; \
  wget -O base/bin/bash https://github.com/robxu9/bash-static/releases/download/5.1.016-1.2.3/bash-linux-"`uname -m`"; \
  chmod 755 base/bin/bash; \
  ln -fs ../../bin/bash base/usr/bin/bash

# Pull TLS certificates, timezone info, and minimal linked libraries from amazon.
FROM amazonlinux:2
RUN set -ex; \
  mkdir -p base/usr/bin base/etc base/usr/share base/lib64; \
  cp -r /etc/ssl /etc/pki base/etc/; \
  cp -r /usr/share/zoneinfo base/usr/share/; \
  cp -r /lib64/libc[-.]* /lib64/libpthread* /lib64/ld-* base/lib64/; \
  cp -r /etc/ld.so* base/etc/



FROM scratch
COPY --from=0 /base/ /
COPY --from=1 /base/ /
ENTRYPOINT ["/bin/dumb-init", "--"]
USER nonroot
ENV HOME=/home/nonroot USER=nonroot LD_LIBRARY_PATH=/lib64 PATH=/bin:/sbin:/usr/bin:/usr/sbin
WORKDIR /home/nonroot
CMD ["/bin/bash", "-exc", "exec relay forward -b \"${RELAY_BUCKET}\""]
