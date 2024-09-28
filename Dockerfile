# syntax=docker/dockerfile:1

ARG SDK_VERSION=2.9.4
FROM digitalasset/daml-sdk:${SDK_VERSION}
WORKDIR /Q1
COPY . .
RUN daml test
WORKDIR /Q2
COPY . .
RUN daml test
WORKDIR /Q3
COPY . .
RUN daml test