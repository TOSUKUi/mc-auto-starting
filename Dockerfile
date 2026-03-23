FROM ruby:3.4.9

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    default-mysql-client \
    nodejs \
    npm \
    git \
    pkg-config \
  && gem install rails -v 8.1.2 --no-document \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
