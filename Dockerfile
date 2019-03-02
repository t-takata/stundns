FROM ruby:2.5

WORKDIR /usr/src/app

COPY Gemfile ./
RUN bundle install
COPY stundns.rb ./

CMD []
ENTRYPOINT ["./stundns.rb"]
