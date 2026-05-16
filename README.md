# Forge-Neo Modal Image

Private image-builder repo for Forge-Neo on Modal.

The workflow publishes:

```text
ghcr.io/anqipudding/forge-neo-modal-deploy:latest
```

The image bakes in:

- Haoming02 `sd-webui-forge-classic`, branch `neo`, pinned to `3a5eafb7d3c37028b17815f86c745737cc86e909`
- Python 3.13 via `uv`
- PyTorch `2.12.0+cu130` and torchvision `0.27.0+cu130`
- SageAttention from `thu-ml/SageAttention` tag `v2.2.0`, compiled for L40S/Ada `sm_89`
- JupyterLab and common terminal download tools
- These extensions only:
  - `zixaphir/Stable-Diffusion-Webui-Civitai-Helper`
  - `Bing-su/adetailer`
  - `lanner0403/WAI-NSFW-illustrious-character-select`

`start-forge` launches Forge with `--sage --cuda-malloc` and points models to `/data/models`.

The Docker source stays in this private repo; the image is labeled against the public deploy-only repo so other Modal accounts can pull the public package without seeing the build files.
