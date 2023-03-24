# Pipe Progress

## Table of Contents

<!-- TOC -->

- [Pipe Progress](#pipe-progress)
  - [Table of Contents](#table-of-contents)
  - [Status](#status)
  - [Overview](#overview)
  - [Usage](#usage)
    - [Pre-build release](#pre-build-release)
    - [Cargo release](#cargo-release)
    - [From source](#from-source)
  - [Examples](#examples)

<!-- /TOC -->

## Status

| Status                                                                                                               | Description                                 |
| :------------------------------------------------------------------------------------------------------------------- | :------------------------------------------ |
| ![Dependabot](https://api.dependabot.com/badges/status?host=github&repo=salt-labs/pipeprogress&identifier=272124365) | Dependency checker                          |
| ![Rust](https://github.com/salt-labs/pipeprogress/workflows/Rust/badge.svg)                                          | Rust                                        |
| ![Greetings](https://github.com/salt-labs/pipeprogress/workflows/Greetings/badge.svg)                                | Greets new users to the project.            |
| ![Docker](https://github.com/salt-labs/pipeprogress/workflows/Docker/badge.svg)                                      | Testing and building containers |
| ![Labeler](https://github.com/salt-labs/pipeprogress/workflows/Labeler/badge.svg)                                    | Automates label addition to issues and PRs  |
| ![Release](https://github.com/salt-labs/pipeprogress/workflows/Release/badge.svg)                                    | Ships new releases :ship:                   |
| ![Stale](https://github.com/salt-labs/pipeprogress/workflows/Stale/badge.svg)                                        | Checks for Stale issues and PRs             |
| ![Super-Linter](https://github.com/salt-labs/pipeprogress/workflows/Linter/badge.svg)                                | Linting                                     |

## Overview

Pipe Progress is a command-line utility to display progress during long pipe operations.

This utility was created as part of the _amazing_ training course titled **_Hands-On Systems Programming with Rust_** by [Nathan Stocks](https://github.com/cleancut). The course content is available from [Agile perception](https://agileperception.com/hands_on_programming).

## Usage

There are a couple of different methods to running the code from this repository.

### Pre-build release

Download a prebuilt release in your desired architecture and place the binary into your `PATH` before running the following.

```bash
pp --help
```

### Cargo release

[Pipe Progress](https://crates.io/crates/pipeprogress) can be installed using cargo as follows

```bash
cargo install pipeprogress

pp --help
```

### From source

If you want to run from source, you can clone this repository and build with cargo as follows.

```bash
git clone git@github.com:salt-labs/pipeprogress.git

cd pipeprogress

cargo build --release

./target/release/pp --help
```

## Examples

```bash
dd if=/dev/urandom bs=1M count=1024 | pp | dd of=random_data.bin

# Output is as follows; bytes, elapsed time, bps rate
970997760 0:00:06 [6970429b/s]
```
