# syntax=docker/dockerfile:1

ARG SDK_VERSION=2.9.5
FROM digitalasset/daml-sdk:${SDK_VERSION}
WORKDIR /Q1
COPY ./Q1 .
RUN daml test
WORKDIR /Q2
COPY ./Q2 .
RUN daml test
WORKDIR /Q3
COPY ./Q3 .
RUN daml test