FROM nvcr.io/nvidia/cuda:13.0.1-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_PREFER_BINARY=1
ENV HF_HUB_DISABLE_PROGRESS_BARS=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# CUDA 13 PyTorch wheels for ARM64, then HiDream's own requirements
# (requirements.txt on its dev branch) plus python-dotenv, which app.py
# imports but the dev requirements file does not list.
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu130 && \
    pip install --no-cache-dir \
      transformers==4.57.1 \
      diffusers \
      accelerate \
      einops \
      numpy \
      pillow \
      tqdm \
      scipy \
      flask \
      openai \
      python-dotenv

# HiDream's official code, pinned: the dev branch is the one HiDream's model
# table names for HiDream-O1-Image-Dev-2604 (same app.py serves the base model
# with HIDREAM_MODEL_TYPE=full). MIT license.
ARG HIDREAM_REPO=https://github.com/HiDream-ai/HiDream-O1-Image.git
ARG HIDREAM_COMMIT=3237a638a5c2c7be106b0175958f4c0db8c2dfbf
RUN git clone "${HIDREAM_REPO}" /opt/hidream && \
    git -C /opt/hidream checkout "${HIDREAM_COMMIT}" && \
    rm -rf /opt/hidream/.git

WORKDIR /opt/hidream

# flash-attn has no ARM64 CUDA 13 wheel. HiDream's README: without it, change
# models/pipeline.py's "use_flash_attn": True to False (PyTorch SDPA instead).
# FA_VERSION must also be something other than "2"/"3", or
# models/qwen3_vl_transformers.py imports flash_attn unconditionally at load.
RUN sed -i 's/"use_flash_attn": True/"use_flash_attn": False/' models/pipeline.py && \
    grep -q '"use_flash_attn": False' models/pipeline.py && \
    ! grep -q '"use_flash_attn": True' models/pipeline.py
ENV FA_VERSION=none

# app.py reads these; the checkpoint directory is supplied by whoever runs the
# image (a mounted folder, or a derived image that bakes the weights in).
ENV HIDREAM_MODEL_TYPE=dev
ENV HIDREAM_HOST=0.0.0.0
ENV HIDREAM_PORT=7860

EXPOSE 7860

CMD ["python", "app.py"]
