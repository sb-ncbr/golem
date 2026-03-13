# build
FROM ubuntu AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Pin Flutter to a specific version for reproducible builds
RUN git clone --depth 1 --branch 3.41.0 https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

RUN flutter config --enable-web \
    && flutter precache --web

WORKDIR /app

COPY . .

RUN flutter clean && flutter build web --release

# runtime
FROM python:3.13-slim

WORKDIR /app

COPY --from=build /app/build/web ./build/web
COPY startup.sh .
RUN chmod +x /app/startup.sh

EXPOSE 3000
ENTRYPOINT [ "/app/startup.sh" ]