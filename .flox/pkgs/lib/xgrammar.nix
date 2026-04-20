# xgrammar 0.1.33 — structured output grammar engine (C++ extensions)
# Uses autoPatchelfHook for compiled shared objects.
{ python3, autoPatchelfHook, stdenv }:

python3.pkgs.buildPythonPackage rec {
  pname = "xgrammar";
  version = "0.1.33";
  format = "wheel";

  src = builtins.fetchurl {
    url = "https://files.pythonhosted.org/packages/f0/a8/672833a3cff027253793aa999401d8364896ebf396967e475c7a878b895f/xgrammar-0.1.33-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
    sha256 = "sha256-UrjqpTMoKg77CDXbaZiucuezx4ddelLjYP/r/5t4wwo=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib   # libstdc++
  ];

  # Torch's ninja dependency installs a setup hook that hijacks buildPhase.
  # This is a pre-built wheel — disable ninja/cmake build integration.
  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;
  dontUseCmakeConfigure = true;

  propagatedBuildInputs = [
    python3.pkgs.torch
    python3.pkgs.pydantic          # imported at top level by structural_tag.py
  ];

  # Import pulls in transformers, pydantic, etc. — provided by sglang at runtime.
  pythonImportsCheck = [ ];
}
