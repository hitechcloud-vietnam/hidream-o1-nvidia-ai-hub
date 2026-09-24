# HiDream-O1-Image NVIDIA AI Hub Image

Thin container around HiDream's official inference server for running `HiDream-ai/HiDream-O1-Image` and `HiDream-ai/HiDream-O1-Image-Dev-2604` on NVIDIA GPU.

Goals:
- no on-device Docker build of the runtime during Spark AI Hub install
- ARM64 CUDA 13 image suitable for DGX Spark
- HiDream's own pipeline and samplers, so text-to-image, instruction editing and multi-image subject personalization all work as HiDream ships them

This image:
- installs CUDA 13 PyTorch wheels for ARM64 and HiDream's requirements
- contains HiDream's official code (`HiDream-ai/HiDream-O1-Image`, dev branch, pinned commit, MIT license)
- runs PyTorch SDPA attention instead of flash-attn (no ARM64 CUDA 13 wheel), using the switch HiDream's README documents
- does not contain model weights; point `HIDREAM_MODEL_PATH` at a checkpoint directory

Run:

```bash
docker run --gpus all -p 7860:7860 \
  -v /path/to/HiDream-O1-Image-Dev-2604:/models/hidream:ro \
  -e HIDREAM_MODEL_PATH=/models/hidream \
  -e HIDREAM_MODEL_TYPE=dev \
  ghcr.io/waxacabytes/hidream-o1-spark-ai-hub:latest
```

Use `HIDREAM_MODEL_TYPE=full` with the `HiDream-O1-Image` checkpoint.

Interface (HiDream's `app.py`):
- `GET /` web UI
- `POST /api/generate/start` with JSON `prompt`, `mode` (`t2i`, `edit` with exactly one image, `subject` with two or more), `width`, `height`, `seed`, `refs_b64` (base64 images); returns `job_id`
- `GET /api/generate/stream/<job_id>` server-sent events: progress previews, then `{"type": "done", "image": "<base64 PNG>"}`

Sampling follows HiDream's code: the full model runs 50 steps at guidance 5.0, shift 3.0; Dev models run 28 steps with guidance off.

Upstream references:
- Code: https://github.com/HiDream-ai/HiDream-O1-Image
- Model: https://huggingface.co/HiDream-ai/HiDream-O1-Image
- Model: https://huggingface.co/HiDream-ai/HiDream-O1-Image-Dev-2604
