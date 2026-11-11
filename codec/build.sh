#!/usr/bin/env bash
# Build palic-2 from this codec/ tree.
# Sources: vovach777/plt2 @ 5569faae8efca72b32052d9bc1e53cb25b67d63f (branch ctx5)
#
# Usage:
#   ./build.sh              # Linux x86-64-v3 (AVX2) portable static binary (default)
#   ./build.sh v3           # same
#   ./build.sh v2           # Linux x86-64-v2 (SSE4.2); the code itself only needs SSE4.1
#   ./build.sh linux-aarch64
#                           # static aarch64 Linux ELF via cosmocc (scalar path)
#   ./build.sh cosmocc      # fat APE (x86_64+SSE and aarch64+scalar) as palic-2.com
#   ./build.sh all          # v3 + v2 + linux-aarch64 + cosmocc
#
# cosmocc toolchain: https://cosmo.zip/pub/cosmocc/cosmocc.zip
# (GitHub mirror: https://github.com/jart/cosmopolitan/releases ).
# Set COSMOCC to <prefix>/bin/cosmocc, or put that bin/ on PATH, or install
# to /opt/cosmocc. On Apple Silicon macOS, the first run of palic-2.com may
# compile the bundled APE loader (ape-m1.c) with the host compiler; install
# Xcode Command Line Tools first: xcode-select --install
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FSE="$ROOT/third_party/fse"
FSE_SRC=(
  "$FSE/entropy_common.c"
  "$FSE/fse_compress.c"
  "$FSE/fse_decompress.c"
  "$FSE/hist.c"
  "$FSE/fseU16.c"
)
CPPFLAGS=( -I"$FSE" -DFSEU16_MAX_SYMBOL_VALUE=1023 )
COMMON=( -O3 -Wno-psabi )
SRCS=( "$ROOT/palic-2/palic2.cpp" "${FSE_SRC[@]}" )

mkdir -p "$ROOT/bin"

find_cosmocc() {
  local cc="${COSMOCC:-}"
  if [[ -z "$cc" ]]; then
    if command -v cosmocc >/dev/null 2>&1; then
      cc="$(command -v cosmocc)"
    elif [[ -x /opt/cosmocc/bin/cosmocc ]]; then
      cc=/opt/cosmocc/bin/cosmocc
    else
      echo "cosmocc not found. Download https://cosmo.zip/pub/cosmocc/cosmocc.zip" >&2
      echo "or the GitHub release asset cosmocc-*.zip, unpack it, and set COSMOCC" >&2
      echo "to <prefix>/bin/cosmocc." >&2
      return 1
    fi
  fi
  printf '%s\n' "$cc"
}

link_linux() {
  local out="$1"; shift
  local objs=("$@")
  local libs=( -static -static-libstdc++ -static-libgcc )
  if ! g++ "${COMMON[@]}" "${objs[@]}" "${libs[@]}" -o "$out" 2>/tmp/palic2-link.err; then
    echo "warning: full -static failed, retrying with -static-libstdc++ -static-libgcc" >&2
    cat /tmp/palic2-link.err >&2
    libs=( -static-libstdc++ -static-libgcc )
    g++ "${COMMON[@]}" "${objs[@]}" "${libs[@]}" -o "$out"
  fi
}

build_linux() {
  local arch="$1"   # x86-64-v3 or x86-64-v2
  local name="palic-2-linux-x86_64-${arch##*-}"  # palic-2-linux-x86_64-v3
  local out="$ROOT/bin/$name"
  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/palic2-$arch.XXXXXX")"
  trap 'rm -rf "$work"' RETURN
  echo "building $name (-march=$arch, -static, PLN_SSE) ..."
  # Compile FSE as C (g++ would treat .c as C++ and can break FSE).
  local i=0
  local objs=()
  for src in "${FSE_SRC[@]}"; do
    gcc "${COMMON[@]}" -march="$arch" "${CPPFLAGS[@]}" -c "$src" -o "$work/fse$i.o"
    objs+=( "$work/fse$i.o" )
    i=$((i + 1))
  done
  g++ "${COMMON[@]}" -march="$arch" -std=c++17 "${CPPFLAGS[@]}" -DPLN_SSE \
    -c "$ROOT/palic-2/palic2.cpp" -o "$work/palic2.o"
  objs+=( "$work/palic2.o" )
  link_linux "$out" "${objs[@]}"
  chmod +x "$out"
  echo "wrote $out"
}

build_linux_aarch64() {
  local cc prefix cxx strip out
  cc="$(find_cosmocc)"
  prefix="$(cd "$(dirname "$cc")/.." && pwd)"
  cxx="$prefix/bin/aarch64-unknown-cosmo-c++"
  strip="$prefix/bin/aarch64-linux-cosmo-strip"
  if [[ ! -x "$cxx" ]]; then
    echo "missing $cxx (need a full cosmocc toolchain, not just the cosmocc driver)" >&2
    return 1
  fi
  out="$ROOT/bin/palic-2-linux-aarch64"
  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/palic2-aarch64.XXXXXX")"
  trap 'rm -rf "$work"' RETURN
  echo "building palic-2-linux-aarch64 with $cxx (scalar path, no PLN_SSE) ..."
  # No -DPLN_SSE: smmintrin.h is x86-only; palic2.cpp has a scalar fallback.
  "$cxx" "${COMMON[@]}" -std=c++17 "${CPPFLAGS[@]}" \
    -o "$work/palic-2.aarch64.elf" "${SRCS[@]}"
  if [[ -x "$strip" ]]; then
    "$strip" -s -o "$out" "$work/palic-2.aarch64.elf"
  else
    cp -a "$work/palic-2.aarch64.elf" "$out"
  fi
  chmod +x "$out"
  echo "wrote $out"
}

build_cosmocc() {
  local cc prefix cxx86 cxxarm apelink pecheck out
  cc="$(find_cosmocc)"
  prefix="$(cd "$(dirname "$cc")/.." && pwd)"
  cxx86="$prefix/bin/x86_64-unknown-cosmo-c++"
  cxxarm="$prefix/bin/aarch64-unknown-cosmo-c++"
  apelink="$prefix/bin/apelink"
  pecheck="$prefix/bin/pecheck"
  if [[ ! -x "$cxx86" || ! -x "$cxxarm" || ! -x "$apelink" ]]; then
    echo "incomplete cosmocc toolchain under $prefix (need per-arch c++ and apelink)" >&2
    return 1
  fi
  out="$ROOT/bin/palic-2.com"
  local work
  work="$(mktemp -d "${TMPDIR:-/tmp}/palic2-ape.XXXXXX")"
  trap 'rm -rf "$work"' RETURN
  echo "building palic-2.com fat APE (x86_64 + PLN_SSE, aarch64 scalar) ..."
  # Compile each architecture separately so the x86 side can use SSE4.1
  # (PLN_SSE) while the aarch64 side stays on the scalar fallback.
  "$cxx86" "${COMMON[@]}" -std=c++17 "${CPPFLAGS[@]}" -DPLN_SSE \
    -o "$work/palic-2.com.dbg" "${SRCS[@]}"
  "$cxxarm" "${COMMON[@]}" -std=c++17 "${CPPFLAGS[@]}" \
    -o "$work/palic-2.aarch64.elf" "${SRCS[@]}"
  # Bundle both APE loaders and the Apple Silicon (M1) loader source so
  # first run on macOS can compile the loader with Xcode CLT.
  "$apelink" -V -1 \
    -l "$prefix/bin/ape-x86_64.elf" \
    -l "$prefix/bin/ape-aarch64.elf" \
    -M "$prefix/bin/ape-m1.c" \
    -o "$out" \
    "$work/palic-2.com.dbg" \
    "$work/palic-2.aarch64.elf"
  if [[ -x "$pecheck" ]]; then
    "$pecheck" "$out" || true
  fi
  chmod +x "$out"
  # cosmocc also leaves .dbg / .aarch64.elf next to -o when used as a
  # fat driver; we build in $work so they never land in codec/bin/.
  echo "wrote $out"
}

target="${1:-v3}"
case "$target" in
  v3|x86-64-v3|linux-v3) build_linux x86-64-v3 ;;
  v2|x86-64-v2|linux-v2) build_linux x86-64-v2 ;;
  linux-aarch64|aarch64|arm64) build_linux_aarch64 ;;
  cosmocc|ape|com)       build_cosmocc ;;
  all)
    build_linux x86-64-v3
    build_linux x86-64-v2
    build_linux_aarch64
    build_cosmocc
    ;;
  *)
    echo "unknown target: $target (use v3, v2, linux-aarch64, cosmocc, or all)" >&2
    exit 2
    ;;
esac
