# Stage 1 – builder: install dependencies and project with uv
FROM ghcr.io/astral-sh/uv:python3.14-trixie AS builder

WORKDIR /opt/photobooth-app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Omit development dependencies
ENV UV_NO_DEV=1

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project

COPY . /opt/photobooth-app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen

# Stage 2 – runtime: slim image with only what's needed to run
FROM python:3.14-slim-trixie

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ffmpeg \
        fonts-noto-color-emoji \
        libexif12 \
        libgl1 \
        libgphoto2-6 \
        libgphoto2-port12 \
        libltdl7 \
        libturbojpeg0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/photobooth-app

# Copy the installed application from the builder
COPY --from=builder /opt/photobooth-app /opt/photobooth-app

# Put the venv on PATH so we can run the entrypoint directly
ENV PATH="/opt/photobooth-app/.venv/bin:$PATH"

EXPOSE 8000

LABEL org.opencontainers.image.source="https://github.com/photobooth-app/photobooth-app" \
      org.opencontainers.image.description="Photobooth app written in Python supporting DSLR, picamera2 and webcameras" \
      org.opencontainers.image.licenses="MIT"

CMD ["photobooth"]
