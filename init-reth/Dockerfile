FROM google/cloud-sdk:latest

COPY fetch-snapshot.sh /usr/local/bin/fetch-snapshot.sh
RUN chmod +x /usr/local/bin/fetch-snapshot.sh

RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y ca-certificates tzdata aria2 curl zstd lz4 \
        && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/usr/local/bin/fetch-snapshot.sh" ]
