# syntax=docker/dockerfile:1.7

ARG CUDA_VERSION=13.0.2
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu24.04

ARG FORGE_REPO=https://github.com/Haoming02/sd-webui-forge-classic.git
ARG FORGE_BRANCH=neo
ARG FORGE_COMMIT=3a5eafb7d3c37028b17815f86c745737cc86e909

ARG CIVITAI_HELPER_REPO=https://github.com/zixaphir/Stable-Diffusion-Webui-Civitai-Helper.git
ARG CIVITAI_HELPER_COMMIT=93ca8af62c7c287bdb676e9aa82dce8c15c72d7e
ARG ADETAILER_REPO=https://github.com/Bing-su/adetailer.git
ARG ADETAILER_COMMIT=3a599f5d4607d8f9d8b9fc5a15526197418dae1a
ARG WAI_SELECTOR_REPO=https://github.com/lanner0403/WAI-NSFW-illustrious-character-select.git
ARG WAI_SELECTOR_COMMIT=17caff0d763db34bbaa93f32b07a1a6c08ce60d4

ARG TORCH_INDEX=cu130
ARG TORCH_VERSION=2.12.0
ARG TORCHVISION_VERSION=0.27.0
ARG SAGE_REPO=https://github.com/thu-ml/SageAttention.git
ARG SAGE_TAG=v2.2.0
ARG SAGE_MAX_JOBS=8

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_PYTHON_DOWNLOADS=automatic \
    UV_NO_CACHE=1 \
    TORCH_INDEX_URL=https://download.pytorch.org/whl/${TORCH_INDEX} \
    VIRTUAL_ENV=/opt/forge-neo/venv \
    PATH=/opt/forge-neo/venv/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PYTHON=/opt/forge-neo/venv/bin/python3.13 \
    TORCH_CUDA_ARCH_LIST=8.9 \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    GRADIO_ANALYTICS_ENABLED=False \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN apt-get update && apt-get install -y --no-install-recommends \
        aria2 \
        build-essential \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        git-lfs \
        libgl1 \
        libglib2.0-0 \
        libgoogle-perftools4 \
        libgomp1 \
        libsm6 \
        libtcmalloc-minimal4 \
        libxext6 \
        libxrender1 \
        ninja-build \
        openssh-client \
        pkg-config \
        rsync \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/forge-neo

RUN git clone --branch "${FORGE_BRANCH}" --depth 1 --filter blob:none "${FORGE_REPO}" . \
    && git fetch --depth 1 origin "${FORGE_COMMIT}" \
    && git reset --hard "${FORGE_COMMIT}" \
    && rm -rf .git

RUN mkdir -p extensions \
    && git clone --depth 1 "${CIVITAI_HELPER_REPO}" extensions/Stable-Diffusion-Webui-Civitai-Helper \
    && git -C extensions/Stable-Diffusion-Webui-Civitai-Helper fetch --depth 1 origin "${CIVITAI_HELPER_COMMIT}" \
    && git -C extensions/Stable-Diffusion-Webui-Civitai-Helper reset --hard "${CIVITAI_HELPER_COMMIT}" \
    && rm -rf extensions/Stable-Diffusion-Webui-Civitai-Helper/.git \
    && git clone --depth 1 "${ADETAILER_REPO}" extensions/adetailer \
    && git -C extensions/adetailer fetch --depth 1 origin "${ADETAILER_COMMIT}" \
    && git -C extensions/adetailer reset --hard "${ADETAILER_COMMIT}" \
    && rm -rf extensions/adetailer/.git \
    && git clone --depth 1 "${WAI_SELECTOR_REPO}" extensions/WAI-NSFW-illustrious-character-select \
    && git -C extensions/WAI-NSFW-illustrious-character-select fetch --depth 1 origin "${WAI_SELECTOR_COMMIT}" \
    && git -C extensions/WAI-NSFW-illustrious-character-select reset --hard "${WAI_SELECTOR_COMMIT}" \
    && rm -rf extensions/WAI-NSFW-illustrious-character-select/.git

RUN uv venv "${VIRTUAL_ENV}" --python 3.13 --seed \
    && uv pip install --upgrade pip wheel setuptools packaging==26.0

RUN uv pip install \
        "torch==${TORCH_VERSION}+${TORCH_INDEX}" \
        "torchvision==${TORCHVISION_VERSION}+${TORCH_INDEX}" \
        --index-url "${TORCH_INDEX_URL}"

RUN grep -v -E '^torch([[:space:]]*$|[<=>].*)' requirements.txt > /tmp/requirements-no-torch.txt \
    && uv pip install -r /tmp/requirements-no-torch.txt \
    && uv pip install \
        gradio==4.40.0 \
        gradio_rangeslider==0.0.8 \
        hf_transfer \
        jupyterlab \
        modal \
        "ultralytics>=8.3.75" \
        "mediapipe>=0.10.30" \
        "rich>=13.0.0" \
    && rm -f /tmp/requirements-no-torch.txt

RUN uv pip install triton==3.6.0 \
    && git clone --depth 1 --branch "${SAGE_TAG}" "${SAGE_REPO}" /tmp/SageAttention \
    && cd /tmp/SageAttention \
    && EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS="${SAGE_MAX_JOBS}" uv pip install --no-build-isolation . \
    && rm -rf /tmp/SageAttention

COPY scripts/start-forge.sh /usr/local/bin/start-forge
RUN chmod +x /usr/local/bin/start-forge \
    && mkdir -p /data/models/Stable-diffusion /data/models/Lora /data/models/VAE /data/models/embeddings /data/output /data/config /data/tmp/gradio \
    && python -c "import sys, importlib.metadata as m; print(sys.version); print('torch', m.version('torch')); print('sageattention', m.version('sageattention'))"

WORKDIR /opt/forge-neo
EXPOSE 7860 8888
CMD ["start-forge"]
