# SGLang 0.5.10 — high-performance LLM serving engine
# Pure Python wheel that composes all custom CUDA packages + nixpkgs dependencies.
#
# SGLang declares ~60 Requires-Dist entries, many of which are not in nixpkgs
# (nvidia-cutlass-dsl, quack-kernels, etc.).
# We use pythonRemoveDeps to strip ALL dependency metadata from the wheel, then
# explicitly provide the deps needed for core LLM serving in propagatedBuildInputs.
{ python3, sgl-kernel, flashinfer-python, xgrammar }:

python3.pkgs.buildPythonPackage rec {
  pname = "sglang";
  version = "0.5.10";
  format = "wheel";

  src = builtins.fetchurl {
    url = "https://files.pythonhosted.org/packages/1f/ee/f7a946162ed538f47a1c5542f93410e5bf9a0c4ca6021d4000e6f9b87f7d/sglang-0.5.10-py3-none-any.whl";
    sha256 = "0xj0xd6vrv5snc4apqkqyd8y86ig46jvq9p5zqqqib3xsnjmb25c";
  };

  # Strip ALL Requires-Dist metadata — many deps are not in nixpkgs and are
  # either lazily imported or provided by our explicit propagatedBuildInputs.
  pythonRemoveDeps = true;

  # The ninja Python package installs a setup hook that hijacks buildPhase.
  # This is a pre-built wheel — disable ninja/cmake build integration.
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;
  dontUseCmakeConfigure = true;

  propagatedBuildInputs = [
    # ── Custom CUDA packages ──────────────────────────────────────────
    sgl-kernel  # now sglang-kernel 0.4.x
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

    # ── OpenAI Responses API ─────────────────────────────────────────
    python3.pkgs.openai-harmony
  ];

  pythonImportsCheck = [ "sglang" ];
}
