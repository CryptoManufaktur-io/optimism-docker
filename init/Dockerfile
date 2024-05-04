FROM google/cloud-sdk:latest

COPY fetch-snapshot.sh /usr/local/bin/

RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y ca-certificates tzdata aria2 zstd lz4 \
        && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "fetch-snapshot.sh" ]
