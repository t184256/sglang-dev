# Builds custom PyTorch from source with SM-specific GPU targeting and CPU ISA flags.
# Used inside packageOverrides to replace torch across the entire Python package set.
#
# Arguments:
#   lib:                nixpkgs lib
#   torchBase:          the original python3XXPackages.torch (from `super` in packageOverrides)
#   smCapability:       GPU arch in dotted format, e.g., "9.0" (single-SM shorthand)
#   gpuTargets:         list of GPU archs, e.g., [ "8.0" "9.0" ] (defaults to [ smCapability ])
#   smTag:              override pname tag, e.g., "all" (defaults to "sm<digits>" from smCapability)
#   cpuISA:             CPU ISA record from cpu-isa.nix (e.g., { name = "avx512"; flags = [...]; })
#   platform:           "x86_64-linux" or "aarch64-linux"
#   extraPreConfigure:  additional shell commands for preConfigure (e.g., "export USE_CUDNN=0")
#   cudaVersionTag:     tag for pname differentiation (e.g., "cuda12_9", "cuda12_8")
{ lib, torchBase, smCapability ? null, gpuTargets ? [ smCapability ], smTag ? null, cpuISA, platform, extraPreConfigure ? "", cudaVersionTag ? "cuda12_8" }:

let
  effectiveSmTag = if smTag != null then smTag
    else "sm${builtins.replaceStrings ["."] [""] smCapability}";
in

(torchBase.override {
  cudaSupport = true;
  inherit gpuTargets;
}).overrideAttrs (oldAttrs: {
  pname = "pytorch-custom-${cudaVersionTag}-${effectiveSmTag}-${cpuISA.name}";

  passthru = oldAttrs.passthru // {
    gpuArch = if smCapability != null then smCapability else gpuTargets;
    blasProvider = "cublas";
    inherit (cpuISA) name;
  };

  ninjaFlags = [ "-j16" ];
  requiredSystemFeatures = [ "big-parallel" ];

  preConfigure = (oldAttrs.preConfigure or "") + ''
    export CXXFLAGS="${lib.concatStringsSep " " cpuISA.flags} $CXXFLAGS"
    export CFLAGS="${lib.concatStringsSep " " cpuISA.flags} $CFLAGS"
    export MAX_JOBS=16
  '' + extraPreConfigure;

  meta = oldAttrs.meta // {
    platforms = [ platform ];
  };
})
