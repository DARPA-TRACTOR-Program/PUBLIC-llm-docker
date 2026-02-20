# © 2026 Massachusetts Institute of Technology
# MIT License

# -------------------------------------------
# Build Translator
# -------------------------------------------
# https://hub.docker.com/_/rust
# bookworm: Debian 12
FROM python:3.11-slim

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 

# ENV OLLAMA_HOST=host.docker.internal:11434

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.

# Install libclang-dev because bindgen needs it.
# Avoid s3_wrapper.py -> naive.py -> cmake -> bindgen runtime error:
#   Unable to find libclang: "couldn't find any valid shared libraries matching: ['libclang.so', 'libclang-*.so', 'libclang.so.*', 'libclang-*.so.*'], set the `LIBCLANG_PATH` environment variable to a path where one of these files can be found (invalid: [])"
#   note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
#   Traceback (most recent call last):
#     File "/app/naive.py", line 341, in <module>
#     File "/app/naive.py", line 337, in main
#     File "/app/naive.py", line 246, in do_translation
#     File "/app/naive.py", line 135, in prompt_for_first_attempt
#     File "/app/naive.py", line 113, in run_bindgen
#       proc = subprocess.run(["bindgen", "--disable-header-comment", "--no-layout-tests", "--no-doc-comments",
#              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#     File "/usr/local/lib/python3.11/subprocess.py", line 571, in run
#       raise CalledProcessError(retcode, process.args,
RUN apt-get update && apt-get --no-install-recommends install -y \
    build-essential \
    llvm \
    clang \
    libclang-dev \
    cmake \
    libssl-dev \
    pkg-config \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Rust stable 
ENV RUSTUP_HOME=/opt/rust/rustup
ENV CARGO_HOME=/opt/rust/cargo
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH=/opt/rust/cargo/bin:$PATH

# Install bindgen to fix s3_wrapper.py -> naive.py runtime error:
#   Traceback (most recent call last):
#     File "/app/naive.py", line 344, in <module>
#     File "/app/naive.py", line 340, in main
#     File "/app/naive.py", line 249, in do_translation
#     File "/app/naive.py", line 138, in prompt_for_first_attempt
#     File "/app/naive.py", line 116, in run_bindgen
#       proc = subprocess.run(["bindgen", "--disable-header-comment", "--no-layout-tests", "--no-doc-comments",
#              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#   ...
#   FileNotFoundError: [Errno 2] No such file or directory: 'bindgen'
RUN cargo install bindgen-cli

WORKDIR /app

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

COPY requirements.txt .
# Install python dependencies for ollama
RUN python -m pip install -r requirements.txt

# Copy the source code into the container.
COPY naive.py .
COPY cmake_commands.sh .

# Run the application.
# ENTRYPOINT ["python3", "/app/naive.py"]

# -------------------------------------------
# Run Translator
# -------------------------------------------
# ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# # Set the working directory
WORKDIR /s3_wrapper

# Copy the Python script
COPY s3_wrapper.py .

# Non-root user
RUN useradd -m wrapper && chown -R wrapper:wrapper /s3_wrapper
USER wrapper

# Define the command to run the script
CMD ["python", "s3_wrapper.py"]

