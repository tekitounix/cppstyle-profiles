#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cppstyle_bin="${CPPSTYLE_BIN:-}"

if [[ -z "$cppstyle_bin" ]]; then
  sibling_bin="$(dirname "$repo_root")/cppstyle.g4/target/debug/cppstyle"
  if [[ -x "$sibling_bin" ]]; then
    cppstyle_bin="$sibling_bin"
  elif command -v cppstyle >/dev/null 2>&1; then
    cppstyle_bin="$(command -v cppstyle)"
  fi
fi

if [[ -z "$cppstyle_bin" || ! -x "$cppstyle_bin" ]]; then
  echo "cppstyle binary is not executable: $cppstyle_bin" >&2
  exit 3
fi

case_dir="$(mktemp -d "${TMPDIR:-/tmp}/cppstyle-profiles-g6.XXXXXX")"
trap 'rm -rf -- "$case_dir"' EXIT

sync_args=(sync --root "$case_dir")
if [[ -n "${CPPSTYLE_PROFILE_CHECKOUT:-}" ]]; then
  profile_source="git+file:///profile-checkout-override"
  sync_args+=(--profile-checkout "$CPPSTYLE_PROFILE_CHECKOUT")
else
  candidate_head="$(git -C "$repo_root" rev-parse HEAD)"
  git clone --quiet --bare "$repo_root" "$case_dir/profiles.git"
  git --git-dir="$case_dir/profiles.git" update-ref refs/heads/main "$candidate_head"
  git --git-dir="$case_dir/profiles.git" symbolic-ref HEAD refs/heads/main
  profile_source="git+file://$case_dir/profiles.git"
fi
sed "s|@PROFILE_SOURCE@|$profile_source|" \
  "$repo_root/tests/fixtures/umi-four-target.toml" >"$case_dir/cppstyle.toml"

"$cppstyle_bin" "${sync_args[@]}"
if [[ -z "${CPPSTYLE_PROFILE_CHECKOUT:-}" ]]; then
  "$cppstyle_bin" verify --root "$case_dir" --no-drift
fi

consistency_args=(check --root "$case_dir" --consistency)
if [[ -n "${CPPSTYLE_PROFILE_CHECKOUT:-}" ]]; then
  consistency_args+=(--profile-checkout "$CPPSTYLE_PROFILE_CHECKOUT")
fi
"$cppstyle_bin" "${consistency_args[@]}"

for target in host stm32 rp235x wasm; do
  for generated in \
    ".cppstyle/generated/clang-format/$target/style.yaml" \
    ".cppstyle/generated/clang-tidy/$target/.clang-tidy" \
    ".cppstyle/generated/clangd/$target/config.yaml"; do
    if [[ ! -s "$case_dir/$generated" ]]; then
      echo "missing generated file: $generated" >&2
      exit 1
    fi
  done
done

for target in stm32 rp235x wasm; do
  cmp "$case_dir/.cppstyle/generated/clang-format/host/style.yaml" \
    "$case_dir/.cppstyle/generated/clang-format/$target/style.yaml"
  cmp "$case_dir/.cppstyle/generated/clang-tidy/host/.clang-tidy" \
    "$case_dir/.cppstyle/generated/clang-tidy/$target/.clang-tidy"
done

if [[ -n "${CPPSTYLE_BASE_CHECKOUT:-}" ]]; then
  mkdir -p "$case_dir/base"
  sed '/^\[targets\.stm32\]/,$d' "$case_dir/cppstyle.toml" \
    >"$case_dir/base/cppstyle.toml"
  "$cppstyle_bin" sync --root "$case_dir/base" \
    --profile-checkout "$CPPSTYLE_BASE_CHECKOUT"
  for generated in \
    "clang-format/host/style.yaml" \
    "clang-tidy/host/.clang-tidy" \
    "clangd/host/config.yaml"; do
    cmp "$case_dir/base/.cppstyle/generated/$generated" \
      "$case_dir/.cppstyle/generated/$generated"
  done
fi

if rg -n 'cpp\.rt\.|realtime-safety|\[plugins\.' \
  "$repo_root/profiles/projects/umi"/*.toml; then
  echo "unimplemented SL1 or realtime plugin was enabled in a profile" >&2
  exit 1
fi

echo "umi four-target profile resolution: PASS"
