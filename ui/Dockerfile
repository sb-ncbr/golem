FROM ubuntu AS build

RUN apt-get update
RUN apt-get install -y curl git unzip python3
RUN git clone https://github.com/flutter/flutter.git
ENV PATH="/flutter/bin:${PATH}"

RUN flutter doctor

RUN flutter config --enable-web

COPY . /app
WORKDIR /app
RUN flutter clean
RUN flutter build web

EXPOSE 5000

ENTRYPOINT [ "/app/startup.sh" ]