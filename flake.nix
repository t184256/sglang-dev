{
  description = "SGLang inference engine and model packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
    in
    {
      packages.${system} = {
        sglang-python312-cuda12_8-all-avx2 =
          import ./.flox/pkgs/sglang-python312-cuda12_8-all-avx2.nix {};
        phi-4-mini-instruct-fp8-sglang =
          import ./.flox/pkgs/phi-4-mini-instruct-fp8-sglang.nix { inherit pkgs; };
      };
    };
}
