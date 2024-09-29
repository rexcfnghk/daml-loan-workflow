# Daml Loan Worflow ![CI Status](https://github.com/rexcfnghk/daml-loan-workflow/actions/workflows/docker-image.yml/badge.svg)

A demonstration on modelling a loan workflow. The repository is split into three subfolders [Q1], [Q2], and [Q3].

[Q1]: ./Q1/
[Q2]: ./Q2/
[Q3]: ./Q3/

## Development Quick Start

### Building from source

You need to have [Daml] installed.

[Daml]: https://docs.daml.com

Change directory to the question folder you would like to build. We will use [Q1] as an example.

```bash
cd ./Q1
daml build
```

This will build you Daml code once.

### Testing

Each subfolder contains tests written with Daml Script. They can run using

```bash
cd ./Q1
daml test
```

### Containerisation

A [Dockerfile] is also provided to run the tests under all subfolders. This is used in the [GitHub action] for continuous integration.

[Dockerfile]: ./Dockerfile
[GitHub action]: ./.github/docker-image.yml

## Design Decisions

TBD
