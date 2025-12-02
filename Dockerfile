FROM buildpack-deps:bullseye

RUN apt-get update
RUN curl -L https://github.com/postmodern/ruby-install/releases/download/v0.10.1/ruby-install-0.10.1.tar.gz -O
RUN tar -xvzf ruby-install-0.10.1.tar.gz
RUN cd ruby-install-0.10.1 && make install
RUN mkdir -p /github/workspace
RUN ruby-install --rubies-dir /github/workspace 3.4.6 -- --disable-install-rdoc LDFLAGS="-s"