# SGLang 0.5.9 — all GPU architectures (SM75–SM120) — AVX2
# CUDA 12.8 — Requires NVIDIA driver 550+
# Custom PyTorch built from source (all SMs + AVX2)
{ }:
let
  allCapabilities = [ "7.5" "8.0" "8.6" "8.9" "9.0" "10.0" "12.0" ];

  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0182a361324364ae3f436a63005877674cf45efb.tar.gz";
    sha256 = "1i04bclcxsqhk172wvj74fcgk2sd7037mi9bgxp7jdx42886bl6h";
  }) {
    system = platform;
    config = {
      allowUnfree = true;
      cudaSupport = true;
      cudaCapabilities = allCapabilities;
    };
    overlays = [ (final: prev: { cudaPackages = final.cudaPackages_12_8; }) ];
  };
  inherit (nixpkgs_pinned) lib;

  # ── Variant-specific configuration ──────────────────────────────────
  variantName = "sglang-python312-cuda12_8-all-avx2";
  cpuISA = (import ./lib/cpu-isa.nix).avx2;
  platform = "x86_64-linux";

  # ── Custom Python package set with from-source torch ────────────────
  python312Custom = nixpkgs_pinned.python312.override {
    packageOverrides = self: super: {
      torch = import ./lib/custom-torch.nix {
        inherit lib cpuISA platform;
        torchBase = super.torch;
        gpuTargets = allCapabilities;
        smTag = "all";
        cudaVersionTag = "cuda12_8";
      };
    };
  };

  cudaPackages = nixpkgs_pinned.cudaPackages;
  autoPatchelfHook = nixpkgs_pinned.autoPatchelfHook;
  stdenv = nixpkgs_pinned.stdenv;

  # ── Build custom CUDA packages ──────────────────────────────────────
  sgl-kernel = import ./lib/sgl-kernel.nix {
    python3 = python312Custom;
    inherit cudaPackages autoPatchelfHook stdenv;
    inherit (nixpkgs_pinned) numactl;
  };

  flashinferPkgs = import ./lib/flashinfer.nix {
    python3 = python312Custom;
    inherit cudaPackages autoPatchelfHook stdenv;
  };

  xgrammar = import ./lib/xgrammar.nix {
    python3 = python312Custom;
    inherit autoPatchelfHook stdenv;
  };

  # ── Compose SGLang ──────────────────────────────────────────────────
  sglang = import ./lib/sglang-pkg.nix {
    python3 = python312Custom;
    inherit sgl-kernel xgrammar;
    inherit (flashinferPkgs) flashinfer-python;
  };

in
  sglang.overrideAttrs (oldAttrs: {
    pname = variantName;
    requiredSystemFeatures = [ "big-parallel" ];
    meta = oldAttrs.meta // {
      description = "SGLang 0.5.9 for all NVIDIA GPUs SM75-SM120 [CUDA 12.8, custom PyTorch AVX2]";
      platforms = [ platform ];
    };
  })
