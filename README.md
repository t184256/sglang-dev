# SGLang Custom Build Environment

Per-architecture SGLang builds with pre-built CUDA kernel wheels, custom source-built PyTorch, and FlashAttention-3 via FlashInfer. Built with Flox + Nix.

## CUDA Compatibility

| CUDA Version | Minimum Driver |
|-------------|---------------|
| 12.8 | 550+ |

- **Forward compatibility**: CUDA 12.x builds work with any driver that supports the target CUDA version or later
- **No cross-major compatibility**: CUDA 12.x builds are **not** compatible with CUDA 11.x or 13.x runtimes
- **Check your driver**: Run `nvidia-smi` — the "CUDA Version" in the top-right shows the maximum CUDA version your driver supports

```bash
# Verify your driver supports CUDA 12.8
nvidia-smi
# Look for "CUDA Version: 12.8" or higher in the output
```

## Overview

Standard SGLang installation via pip pulls generic wheels and a pre-built PyTorch binary. This project creates **per-SM builds** with a **custom-built PyTorch** and pre-built CUDA kernel packages, resulting in:

- **Pre-built CUDA kernel wheels** — sgl-kernel, FlashInfer, and xgrammar installed as pre-compiled wheels with `autoPatchelfHook` for CUDA runtime linking
- **Custom source-built PyTorch** — Built from source with SM-specific GPU targeting and CPU ISA optimization flags
- **FlashAttention-3 via FlashInfer** — Three-wheel composition (cubin + jit-cache + python) providing FlashAttention-3 kernels
- **Structured output via xgrammar** — C++ grammar engine for constrained generation
- **Per-architecture deployment** — Install exactly what your hardware needs

## Version Matrix

| Component | Version | Notes |
|-----------|---------|-------|
| SGLang | 0.5.9 | Pure Python wheel with `pythonRemoveDeps` |
| PyTorch | 2.9.1 | Custom source build (SM + ISA targeting) |
| sgl-kernel | 0.3.21 | Pre-built CUDA kernel library |
| FlashInfer | 0.6.5 | Three-wheel composition (cubin, jit-cache, python) |
| xgrammar | 0.1.27 | C++ structured output engine |
| CUDA Toolkit | 12.8 | Via `cudaPackages_12_8` (driver 550+) |
| Python | 3.12 | Via nixpkgs |
| Nixpkgs | [`0182a36`](https://github.com/NixOS/nixpkgs/tree/0182a361324364ae3f436a63005877674cf45efb) | Pinned revision |

## Build Matrix

| SM | Architecture | GPUs | AVX2 | AVX-512 |
|----|-------------|------|------|---------|
| SM61 | Pascal | P40, GTX 1080 Ti | `sm61-avx2` | `sm61-avx512` |
| SM75 | Turing | T4, RTX 2080 Ti | `sm75-avx2` | `sm75-avx512` |
| SM80 | Ampere DC | A100, A30 | `sm80-avx2` | `sm80-avx512` |
| SM86 | Ampere | RTX 3090, A40 | `sm86-avx2` | `sm86-avx512` |
| SM89 | Ada Lovelace | RTX 4090, L4, L40 | `sm89-avx2` | `sm89-avx512` |
| SM90 | Hopper | H100, H200, L40S | `sm90-avx2` | `sm90-avx512` |
| SM100 | Blackwell DC | B100, B200, GB200 | `sm100-avx2` | `sm100-avx512` |
| SM120 | Blackwell | RTX 5090, RTX PRO 6000 | `sm120-avx2` | `sm120-avx512` |
| **all** | **SM61–SM120** | **P40 through RTX 5090** | `all-avx2` | `all-avx512` |

Variant names are prefixed with `sglang-python312-cuda12_8-`.

### Total: 18 variants (8 SMs x 2 ISAs + 2 fat "all" variants, all Python 3.12)

## Quick Start

```bash
# Build a variant (H100/H200 + AVX-512)
flox build sglang-python312-cuda12_8-sm90-avx512

# Or build the universal "all" variant (works on any GPU from P40 to RTX 5090)
flox build sglang-python312-cuda12_8-all-avx2

# The output is in result-<variant-name>/
# Test it
./result-sglang-python312-cuda12_8-sm90-avx512/bin/python -c "import sglang; print(sglang.__version__)"

# Check GPU support
./result-sglang-python312-cuda12_8-sm90-avx512/bin/python -c "import torch; print(torch.cuda.is_available())"

# Launch an SGLang server
./result-sglang-python312-cuda12_8-sm90-avx512/bin/python -m sglang.launch_server \
  --model-path meta-llama/Llama-3.1-8B-Instruct \
  --port 30000
```

## Variant Selection Guide

### Step 1: Choose your GPU

| GPU | SM |
|-----|----|
| P40, GTX 1080 Ti | SM61 |
| T4, RTX 2080 Ti | SM75 |
| A100, A30 | SM80 |
| RTX 3090, A40 | SM86 |
| RTX 4090, L4, L40 | SM89 |
| H100, H200, L40S | SM90 |
| B100, B200, GB200 | SM100 |
| RTX 5090, RTX PRO 6000 | SM120 |

### Or use the universal "all" variant

Use `all-avx2` or `all-avx512` for development, testing, or multi-GPU-type clusters. These variants compile PyTorch with all SM architectures (6.1–12.0) so the same binary works on any GPU from P40 to RTX 5090. The tradeoff is cuDNN is disabled (SM61 inclusion requires it) and build time is ~8x longer than single-SM variants.

### Step 2: Choose your CPU ISA

- **avx512** — Skylake-SP, Cascade Lake, Ice Lake and newer (datacenter standard)
- **avx2** — Haswell+, any modern x86_64 (broadest compatibility)

## Naming Convention

```
sglang-python312-cuda{12_8}-sm{XX}-{isa}
sglang-python312-cuda{12_8}-all-{isa}
```

The Python version, CUDA minor version, SM architecture (or `all`), and CPU ISA are all encoded in the name.

## Build Architecture

SGLang builds use a **wheel-composition** approach — unlike vLLM which builds everything from source, SGLang composes pre-built CUDA kernel wheels with a custom-built PyTorch:

- **`packageOverrides`** — `python312.override { packageOverrides }` creates a custom Python package set where `torch` is built from source with SM-specific GPU targeting and CPU ISA flags
- **Pre-built wheels + `autoPatchelfHook`** — sgl-kernel, FlashInfer jit-cache, and xgrammar ship as pre-compiled wheels; `autoPatchelfHook` patches their ELF binaries against the custom torch and CUDA runtime libraries
- **`pythonRemoveDeps`** — SGLang declares ~60 `Requires-Dist` entries, many of which are not in nixpkgs (apache-tvm-ffi, nvidia-cutlass-dsl, quack-kernels, openai-harmony, etc.); all dependency metadata is stripped and needed deps are explicitly provided via `propagatedBuildInputs`
- **Shared helpers in `.flox/pkgs/lib/`** — CPU ISA definitions, custom PyTorch builder, and individual CUDA package expressions are shared across all variant files

## Package Structure

```
.flox/pkgs/
├── lib/
│   ├── cpu-isa.nix          # CPU ISA flag definitions (avx, avx2, avx512, etc.)
│   ├── custom-torch.nix     # Custom PyTorch builder with .override + .overrideAttrs
│   ├── flashinfer.nix       # FlashInfer three-wheel composition
│   ├── sgl-kernel.nix       # sgl-kernel CUDA kernel library
│   ├── sglang-pkg.nix       # SGLang wheel with pythonRemoveDeps
│   └── xgrammar.nix         # xgrammar structured output engine
├── sglang-python312-cuda12_8-all-avx2.nix     # All SMs (SM61–SM120) + AVX2, no cuDNN
├── sglang-python312-cuda12_8-all-avx512.nix   # All SMs (SM61–SM120) + AVX-512, no cuDNN
├── sglang-python312-cuda12_8-sm61-avx2.nix    # SM61 + AVX2 variant
├── sglang-python312-cuda12_8-sm61-avx512.nix  # SM61 + AVX-512 variant
├── ...                                         # SM75, SM80, SM86, SM89, SM100, SM120
├── sglang-python312-cuda12_8-sm90-avx2.nix    # SM90 + AVX2 variant
└── sglang-python312-cuda12_8-sm90-avx512.nix  # SM90 + AVX-512 variant
```

## Dependency Graph

```
sglang-python312-cuda12_8-sm90-avx512        (variant entry point)
├── sglang 0.5.9                              (pure Python wheel, pythonRemoveDeps)
│   ├── sgl-kernel 0.3.21                     (pre-built CUDA kernels, autoPatchelf)
│   │   ├── cuda_cudart, cuda_nvrtc, libcublas
│   │   ├── numactl                           (libnuma.so for mscclpp)
│   │   └── custom torch
│   ├── flashinfer-python 0.6.5               (pure Python frontend)
│   │   ├── flashinfer-cubin 0.6.5            (9262 .cubin files, pure Python)
│   │   └── flashinfer-jit-cache 0.6.5+cu128  (compiled .so, autoPatchelf)
│   │       ├── cuda_cudart, cuda_nvrtc, libcublas
│   │       └── custom torch
│   ├── xgrammar 0.1.27                       (C++ only, libstdc++, no CUDA)
│   └── ~30 nixpkgs Python deps               (transformers, fastapi, etc.)
└── custom torch (PyTorch 2.9.1 from source)
    ├── gpuTargets = [ "9.0" ]                (SM90 CUDA kernels)
    └── CXXFLAGS = -mavx512f -mavx512dq ...   (CPU ISA optimization)
```

## Build Requirements

- ~30GB disk space per variant (PyTorch source build + CUDA deps)
- 16GB+ RAM recommended for CUDA builds
- Builds use `requiredSystemFeatures = [ "big-parallel" ]`
- CUDA compilation capped at 16 jobs via `ninjaFlags = [ "-j16" ]` and `MAX_JOBS=16`

## Build Notes

- **SM61 (Pascal)**: Uses `USE_CUDNN=0` — cuDNN 9.11+ dropped support for SM < 7.5
- **"all" variants**: Also use `USE_CUDNN=0` because SM61 is included; cuDNN is not needed for LLM inference (SGLang uses FlashInfer/sgl-kernel for attention). Build time is ~8x longer than single-SM variants since PyTorch compiles CUDA kernels for all 8 SM architectures
- **sgl-kernel**: `autoPatchelfHook` needs `cuda_nvrtc` and `numactl` — discovered via runtime audit of `libnvrtc.so.12` and `libnuma.so.1` dependencies in the mscclpp and sm90/common_ops shared objects
- **FlashInfer**: Split into three wheels — `flashinfer-cubin` (9262 `.cubin` files, pure Python), `flashinfer-jit-cache` (compiled `.so` extensions, needs autoPatchelf against CUDA runtime), and `flashinfer-python` (pure Python frontend that propagates both)
- **FlashInfer JIT at runtime**: FlashInfer may attempt JIT compilation at runtime; set `FLASHINFER_JIT_DIR` to a writable path since the Nix store is read-only
- **xgrammar**: C++ extensions only (`libstdc++`), no CUDA linkage at the `.so` level — simpler autoPatchelf with just `stdenv.cc.cc.lib`
- **pythonRemoveDeps**: SGLang declares ~60 dependencies, many not available in nixpkgs (apache-tvm-ffi, nvidia-cutlass-dsl, quack-kernels, openai-harmony, etc.); all `Requires-Dist` metadata is stripped and the ~30 deps needed for core LLM serving are explicitly listed in `propagatedBuildInputs`

## Branch Strategy

| Branch | SGLang Version | Nixpkgs Pin | PyTorch | Python | Status |
|--------|---------------|-------------|---------|--------|--------|
| `main` | 0.5.9 | `0182a36` | 2.9.1 (source) | 3.12 | Current stable |

## License

Build configuration: MIT
SGLang: Apache 2.0
