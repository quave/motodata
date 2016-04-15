FROM ruby:2.2.3
MAINTAINER Vladislav K. Synkov

COPY Gemfile /usr/src/app/Gemfile
WORKDIR /usr/src/app
RUN bundle install

CMD bash
# drun --rm -ti -v ~/src/motodata:/usr/src/app vs/motodata
# dbuild -t motodata .
