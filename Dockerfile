FROM hexpm/elixir:1.11.4-erlang-23.2.7.1-ubuntu-focal-20210325

RUN apt-get update \
    && apt-get install -y git curl wget \
    && mix local.hex --force \
    && mix local.rebar --force