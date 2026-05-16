#!/usr/bin/env bash
set -euo pipefail

FORGE_DIR="${FORGE_DIR:-/opt/forge-neo}"
DATA_DIR="${DATA_DIR:-/data}"
FORGE_PORT="${FORGE_PORT:-7860}"

export LD_PRELOAD="${LD_PRELOAD:-/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4}"
export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-1}"
export GRADIO_ANALYTICS_ENABLED="${GRADIO_ANALYTICS_ENABLED:-False}"
export GRADIO_TEMP_DIR="${GRADIO_TEMP_DIR:-${DATA_DIR}/tmp/gradio}"
export PYTORCH_CUDA_ALLOC_CONF="${PYTORCH_CUDA_ALLOC_CONF:-expandable_segments:True}"
export TORCH_COMMAND="${TORCH_COMMAND:-echo torch-preinstalled}"
export SAGE_PACKAGE="${SAGE_PACKAGE:-sageattention-preinstalled}"

mkdir -p \
    "${DATA_DIR}/models/Stable-diffusion" \
    "${DATA_DIR}/models/Lora" \
    "${DATA_DIR}/models/VAE" \
    "${DATA_DIR}/models/embeddings" \
    "${DATA_DIR}/output" \
    "${DATA_DIR}/config" \
    "${DATA_DIR}/tmp/gradio"

replace_with_symlink() {
    local target="$1"
    local link="$2"

    if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${target}" ]; then
        return
    fi

    rm -rf "${link}"
    ln -s "${target}" "${link}"
}

replace_with_symlink "${DATA_DIR}/models" "${FORGE_DIR}/models"
replace_with_symlink "${DATA_DIR}/output" "${FORGE_DIR}/output"

for file in config.json ui-config.json styles.csv user.css; do
    ln -sfn "${DATA_DIR}/config/${file}" "${FORGE_DIR}/${file}"
done

exec python -u "${FORGE_DIR}/launch.py" \
    --listen \
    --port "${FORGE_PORT}" \
    --api \
    --enable-insecure-extension-access \
    --skip-install \
    --skip-python-version-check \
    --skip-torch-cuda-test \
    --skip-version-check \
    --skip-prepare-environment \
    --uv \
    --sage \
    --cuda-malloc \
    --model-ref "${DATA_DIR}/models" \
    "$@"

