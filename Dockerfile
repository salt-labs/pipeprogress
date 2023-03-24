##################################################
# Notes for GitHub Actions
#       * Dockerfile instructions: https://git.io/JfGwP
#       * Environment variables: https://git.io/JfGw5
##################################################

#########################
# STAGE: GLOBAL
# Description: Global args for reuse
#########################

ARG PROJECT="pipeprogress"
ARG PROJECT_BIN="pp"
ARG PROJECT_DESC="A command line utility to show progress during pipe operations"
ARG PROJECT_REPO="https://github.com/salt-labs/pipeprogress"
ARG VERSION="0"
ARG TOOLCHAIN="stable"
ARG TARGET="x86_64-unknown-linux-musl"

#########################
# STAGE: BUILD
# Description: Build the app
#########################

FROM docker.io/debian:buster as BUILD

ARG PROJECT
ARG PROJECT_BIN
ARG PROJECT_DESC
ARG PROJECT_REPO
ARG VERSION
ARG TOOLCHAIN
ARG TARGET

ENV DEBIAN_FRONTEND=noninteractive \
       RUST_BACKTRACE=1 \
       PKG_CONFIG_ALLOW_CROSS=1 \
       PKG_CONFIG_ALL_STATIC=1 \
       RUSTFLAGS='-C link-arg=-s' \
       RUST_LOG="info" \
       PATH="/root/.cargo/bin:$PATH"

WORKDIR /

RUN apt update -y \
       && apt upgrade -y \
       && apt install -y \
       --no-install-recommends \
       autoconf \
       automake \
       binutils \
       build-essential \
       ca-certificates \
       clang \
       cmake \
       curl \
       file \
       g++ \
       gcc \
       git \
       gnupg2 \
       jq \
       libasound2 \
       libasound2-dev \
       libgcc-8-dev \
       libgmp-dev \
       libmpc-dev \
       libmpfr-dev \
       libpq-dev \
       libssl-dev \
       libtool \
       make \
       musl-dev \
       musl-tools \
       openssh-client \
       pkgconf \
       tzdata \
       unzip \
       wget \
       xutils-dev \
       zlib1g-dev \
       && apt autoremove -y \
       && apt clean -y \
       && rm -rf /var/lib/apt/lists/*

RUN echo "##### Rustup Init #####" \
       && curl \
       --proto '=https' \
       --tlsv1.2 \
       --output rustup-init \
       https://sh.rustup.rs \
       && chmod +x rustup-init \
       && ./rustup-init \
       -y \
       --profile default \
       --no-modify-path \
       --default-toolchain ${TOOLCHAIN} \
       && rm rustup-init \
       && . ${HOME}/.cargo/env

RUN echo "##### Rustup #####" \
       && rustup target add ${TARGET} \
       --toolchain ${TOOLCHAIN} \
       && rustup show

# Hacky trick to stop the crates being built every
# run when they haven't even been changed by putting the
# crates into a seperate layer.
COPY Cargo.lock .
COPY Cargo.toml .

RUN echo "##### Cargo Cache #####" \
       && mkdir src \
       && echo "fn main() {print!(\"Dummy main\");} // dummy file" > src/main.rs \
       && cargo build \
       --release \
       --target ${TARGET} \
       && rm -f "target/${TARGET}/release/deps/${PROJECT_BIN}"*

ADD . /

RUN echo "##### Cargo Build #####" \
       && cargo build \
       --release \
       --target ${TARGET} \
       --bin ${PROJECT_BIN}

RUN echo "##### Target #####" \
       && ls -lah "/target/${TARGET}/release/" \
       && strip "/target/${TARGET}/release/${PROJECT_BIN}" \
       && ldd "/target/${TARGET}/release/${PROJECT_BIN}" || echo "" \
       && "/target/${TARGET}/release/${PROJECT_BIN}" --help

#########################
# STAGE: RUN
# Description: Run the app
#########################

# Minimal base
FROM gcr.io/distroless/static-debian10 as RUN

# Adds glibc, libssl, openssl
#FROM gcr.io/distroless/base-debian10 as RUN

# Adds libgcc1
#FROM gcr.io/distroless/cc-debian10 as RUN

ARG PROJECT
ARG PROJECT_BIN
ARG PROJECT_DESC
ARG PROJECT_REPO
ARG VERSION
ARG TOOLCHAIN
ARG TARGET

LABEL name="${PROJECT}" \
       maintainer="MAHDTech <MAHDTech@saltlabs.tech>" \
       vendor="Salt Labs" \
       version="${VERSION}" \
       summary="${PROJECT_DESC}" \
       url="${PROJECT_REPO}"

ENV APP=${PROJECT_BIN}

WORKDIR /

COPY --from=BUILD /target/${TARGET}/release/${PROJECT_BIN} /

COPY "LICENSE" "README.md" /

# No shell, no shell expansion
ENTRYPOINT [ "/pp" ]
CMD [ "--help" ]
