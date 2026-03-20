# Phi-4-mini-instruct FP8-TORCHAO (SGLang-compatible)
#
# Same weights as phi-4-mini-instruct-fp8-hf but with tokenizer_config.json
# patched: tokenizer_class "TokenizersBackend" -> "PreTrainedTokenizerFast".
# SGLang 0.5.9 ships transformers 4.57.6 which doesn't recognize
# TokenizersBackend (added in transformers 4.58).
#
# Remove this package once SGLang ships transformers >=4.58.
{ pkgs }:

let
  buildMeta = builtins.fromJSON (builtins.readFile ../../build-meta/phi-4-mini-instruct-fp8-sglang.json);
  slug = "microsoft--Phi-4-mini-instruct-FP8-TORCHAO";
  snapshotId = "b63ecd840bb9835f35e6d884d47810c4deec89dc";

  part0 = pkgs.fetchurl {
    url = "https://github.com/flox/sglang-dev/releases/download/models-v1/phi4-mini-fp8-sglang.tar.partaa";
    hash = "sha256-Ou+6KrlQHMHzNA6sGq0R17zQgVpwCdlJ1OGUOKP/9Rk=";
  };
  part1 = pkgs.fetchurl {
    url = "https://github.com/flox/sglang-dev/releases/download/models-v1/phi4-mini-fp8-sglang.tar.partab";
    hash = "sha256-zwfbrCaYMach8UglI1lEFgCFez+m2f9GFWqB/W8n+cc=";
  };
  part2 = pkgs.fetchurl {
    url = "https://github.com/flox/sglang-dev/releases/download/models-v1/phi4-mini-fp8-sglang.tar.partac";
    hash = "sha256-3yIXgXEaNJntCBCnwhjm5TtKFAY8buRxz9fR8qgTAn8=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "phi-4-mini-instruct-fp8-sglang";
  version = "1.0.0+${buildMeta.git_rev_short}";
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.jq ];
  dontBuild = true;
  installPhase = ''
    _snap="$out/share/models/hub/models--${slug}/snapshots/${snapshotId}"
    mkdir -p "$_snap"
    cat ${part0} ${part1} ${part2} | tar xf - -C "$_snap"
    mkdir -p "$out/share/models/hub/models--${slug}/refs"
    echo -n "${snapshotId}" > "$out/share/models/hub/models--${slug}/refs/main"

    # Patch tokenizer_class for SGLang compatibility
    _tc="$_snap/tokenizer_config.json"
    if [ -f "$_tc" ] && grep -q '"TokenizersBackend"' "$_tc"; then
      jq '.tokenizer_class = "PreTrainedTokenizerFast"' "$_tc" > "$_tc.tmp"
      mv "$_tc.tmp" "$_tc"
    fi
  '';
}
