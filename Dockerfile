FROM ghcr.io/astral-sh/uv:python3.14-trixie
RUN apt-get update && apt-get install --no-install-recommends -y ffmpeg libturbojpeg0 libgl1 libgphoto2-dev fonts-noto-color-emoji libexif12 libgphoto2-6 libgphoto2-port12 libltdl7 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 999 photobooth \
 && useradd --system --gid 999 --uid 999 --create-home photobooth

WORKDIR /opt/photobooth-app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Omit development dependencies
ENV UV_NO_DEV=1

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
COPY . /opt/photobooth-app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

USER photobooth

EXPOSE 8000

CMD ["uv","run","photobooth"]