FROM docker.io/library/debian@sha256:366a6da5efcceffbaa19c560a101b97b87a1a9664eeeac8bc3d24395ddbf14f3
RUN apt-get update
RUN mkdir -p /var/cache/apt/archives; packages="build-essential python3 pkg-config libsdl2-dev libsdl2-ttf-dev libfontconfig1-dev libasound2-dev libflac-dev libutf8proc-dev libsqlite3-dev libexpat1-dev zlib1g-dev libjpeg-dev rapidjson-dev libpugixml-dev libportmidi-dev libasio-dev libglm-dev patch"; \
    apt-get --print-uris --yes --no-install-recommends install $packages | \
    awk 'substr($0,1,1)==sprintf("%c",39) {gsub(sprintf("%c",39), "", $1); print $1, $2}'  | \
    xargs -r -n 2 -P 16 sh -c '/usr/lib/apt/apt-helper download-file "$1" "/var/cache/apt/archives/$2"' sh && \
    apt-get install -y --no-download --no-install-recommends $packages && rm -rf /var/lib/apt/lists/*
