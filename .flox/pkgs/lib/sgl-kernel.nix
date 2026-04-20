# sglang-kernel 0.4.1 — pre-built CUDA kernel library for SGLang
# (renamed from sgl-kernel at 0.4.x)
# Uses autoPatchelfHook to patch ELF binaries against CUDA runtime libs.
{ python3, cudaPackages, autoPatchelfHook, stdenv, numactl }:

python3.pkgs.buildPythonPackage rec {
  pname = "sglang-kernel";
  version = "0.4.1";
  format = "wheel";

  src = builtins.fetchurl {
    url = "https://files.pythonhosted.org/packages/97/26/d4a84be6587b57d20214cc2ee1e7f41b7e3336df357c45a833f25b1f1abf/sglang_kernel-0.4.1-cp310-abi3-manylinux2014_x86_64.whl";
    sha256 = "01m2gawmlkkafgww2g77r82f5qmgvhly9zi5dv1zzkb48brmvav4";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib                # libstdc++, libgcc_s
    cudaPackages.cuda_cudart        # libcudart.so.12
    cudaPackages.cuda_nvrtc         # libnvrtc.so.12
    cudaPackages.libcublas          # libcublas.so.12, libcublasLt.so.12
    python3.pkgs.torch              # libtorch.so, libc10.so, libc10_cuda.so
    numactl                         # libnuma.so.1 (mscclpp, sm90/common_ops)
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"                  # provided by the NVIDIA driver at runtime
  ];

  # Torch's ninja dependency installs a setup hook that hijacks buildPhase.
  # This is a pre-built wheel — disable ninja/cmake build integration.
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;
  dontUseCmakeConfigure = true;

  propagatedBuildInputs = [
    python3.pkgs.torch
  ];

  # Import requires libcuda.so.1 (NVIDIA driver) — not available in the build sandbox.
  dontCheckRuntimeDeps = true;
  pythonImportsCheck = [ ];
}
