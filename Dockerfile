FROM hexpm/elixir:1.12.1-erlang-24.0.1-ubuntu-focal-20210325

RUN apt-get update \
    && apt-get install -y git curl wget \
    && mix local.hex --force \
    && mix local.rebar --force