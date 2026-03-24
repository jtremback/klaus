# Klaus — Sandboxed Claude Code

You are running inside a Klaus sandbox — a Docker container with `--dangerously-skip-permissions`.
You have `sudo` access inside this container. The project directory is mounted read-write.

## Missing tools

If you need a tool that isn't installed, install it now to unblock yourself:

```bash
# Debian packages
sudo apt-get update && sudo apt-get install -y <package>

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Python packages
pip3 install --break-system-packages <package>

# Node packages
npm install -g <package>
```

After installing, also add it to the `Klausfile` in the project root so it's pre-installed next time.

## Klausfile

The `Klausfile` lives in the project root. It uses Dockerfile syntax to pre-install tools into the container image. Just write `RUN`, `ENV`, etc. instructions.

Everything runs as the `klaus` user (which has passwordless sudo), so use `sudo` for system-level commands — same as in a live session.

Example:

```dockerfile
RUN sudo apt-get update && sudo apt-get install -y postgresql-client
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/klaus/.cargo/bin:${PATH}"
RUN pip3 install --break-system-packages numpy pandas cvxpy
```

When you edit the Klausfile, the changes take effect on the next `klaus` invocation (the container is rebuilt). For the current session, install tools directly as described above.
