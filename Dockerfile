FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    curl bash git git-lfs ca-certificates sudo \
    ripgrep fd-find jq \
    build-essential pkg-config libssl-dev \
    python3 python3-pip python3-venv \
    nodejs npm \
    wget openssh-client \
    less tree unzip \
    && rm -rf /var/lib/apt/lists/*

ARG USER_UID=501
RUN useradd -m -s /bin/bash -u ${USER_UID} klaus \
    && echo "klaus ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER klaus
WORKDIR /home/klaus

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/klaus/.local/bin:${PATH}"

RUN mkdir -p ~/.ssh \
    && ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null \
    && git config --global user.email "klaus@sandbox" \
    && git config --global user.name "Klaus Sandbox" \
    && git config --global --add url."https://github.com/".insteadOf "git@github.com:" \
    && git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"

ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
