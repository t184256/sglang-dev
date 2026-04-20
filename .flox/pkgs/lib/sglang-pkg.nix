# SGLang post-DFlash (2026-04-15 commit 43925d1) — built from git source.
# Pure Python package; setuptools-scm needs SETUPTOOLS_SCM_PRETEND_VERSION.
# Source lives in python/ subdirectory of the monorepo.
{ python3, sgl-kernel, flashinfer-python, xgrammar }:

python3.pkgs.buildPythonPackage rec {
  pname = "sglang";
  version = "0.5.10.post0";
  pyproject = true;

  src = builtins.fetchTarball {
    url = "https://github.com/sgl-project/sglang/archive/43925d179d7a4a43f700d97a302882fc63d8c618.tar.gz";
    sha256 = "sha256-LYP3J39n8BKav1sMHD1YccpL1gH5ftPFiGIqbGLMaY8=";
  };

  # Python package lives in python/ subdirectory of the monorepo.
  preConfigure = "cd python";

  # Tell setuptools-scm the version (no .git in fetchTarball).
  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  nativeBuildInputs = with python3.pkgs; [
    setuptools
    setuptools-scm
    wheel
  ];

  # Strip ALL Requires-Dist metadata — many deps are not in nixpkgs and are
  # either lazily imported or provided by our explicit propagatedBuildInputs.
  pythonRemoveDeps = true;

  propagatedBuildInputs = [
    # ── Custom CUDA packages ──────────────────────────────────────────
    sgl-kernel  # now sglang-kernel 0.4.1
    flashinfer-python
    xgrammar

    # ── Core ML ───────────────────────────────────────────────────────
    python3.pkgs.torch
    python3.pkgs.torchvision
    python3.pkgs.numpy
    python3.pkgs.scipy
    python3.pkgs.einops
    python3.pkgs.transformers
    python3.pkgs.tokenizers
    python3.pkgs.sentencepiece
    python3.pkgs.tiktoken
    python3.pkgs.safetensors
    python3.pkgs.huggingface-hub
    python3.pkgs.datasets

    # ── Serving ───────────────────────────────────────────────────────
    python3.pkgs.fastapi
    python3.pkgs.uvicorn
    python3.pkgs.uvloop
    python3.pkgs.aiohttp
    python3.pkgs.requests
    python3.pkgs.python-multipart
    python3.pkgs.prometheus-client

    # ── Serialization / RPC ───────────────────────────────────────────
    python3.pkgs.pydantic
    python3.pkgs.orjson
    python3.pkgs.msgspec
    python3.pkgs.msgpack
    python3.pkgs.pyzmq
    python3.pkgs.protobuf
    python3.pkgs.grpcio

    # ── Structured output / constrained decoding ─────────────────────
    python3.pkgs.outlines
    python3.pkgs.lark
    python3.pkgs.interegular
    python3.pkgs.jsonschema
    python3.pkgs.partial-json-parser

    # ── Quantization / compilation ─────────────────────────────────
    python3.pkgs.compressed-tensors
    python3.pkgs.torchao
    python3.pkgs.depyf

    # ── Utilities ─────────────────────────────────────────────────────
    python3.pkgs.cloudpickle
    python3.pkgs.pillow
    python3.pkgs.tqdm
    python3.pkgs.psutil
    python3.pkgs.packaging
    python3.pkgs.pyyaml
    python3.pkgs.openai
    python3.pkgs.setproctitle
    python3.pkgs.pybase64
    python3.pkgs.ipython
    python3.pkgs.ninja
    python3.pkgs.nvidia-ml-py
    python3.pkgs.gguf
    python3.pkgs.cuda-bindings
    python3.pkgs.soundfile  # streaming ASR endpoint (added post-0.5.10)

    # ── OpenAI Responses API ─────────────────────────────────────────
    python3.pkgs.openai-harmony
  ];

  pythonImportsCheck = [ "sglang" ];
}
