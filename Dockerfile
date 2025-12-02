FROM buildpack-deps:bullseye

RUN apt-get update
RUN curl -L https://github.com/postmodern/chruby/releases/download/v0.3.9/chruby-0.3.9.tar.gz -O
RUN tar -xvzf chruby-0.3.9.tar.gz
RUN cd chruby-0.3.9 && ./scripts/setup.sh
RUN mkdir -p /opt/rubies
RUN curl -L https://github.com/Shopify/cibuildgem/releases/download/ruby-builder/ruby-3.4.7.zip -O
RUN unzip ruby-3.4.7.zip -d /opt/rubies
RUN echo "source /usr/local/share/chruby/chruby.sh" >> ~/.bashrc
RUN echo "chruby 3.4.7" >> ~/.bashrc
