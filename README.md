# clic-palic2

Lossless palic-2 compression of the [CLIC 2020](https://www.compression.cc/) professional training set (`professional_train_2020`, 585 images).

Сжатие без потерь корпуса CLIC 2020 (`professional_train_2020`, 585 изображений) кодеком palic-2.

## Source / Источник

- Official dataset: CLIC 2020 professional train, 585 images.
- `gray/` — 8-bit grayscale PGM (P5), one `.pln` file per image.
- `color/` — 8-bit RGB PPM (P6), one `.pln` file per image.

Официальный набор CLIC 2020 professional train, 585 изображений. В `gray/` лежат сжатые серые PGM (P5), в `color/` — цветные PPM (P6), 8 бит на канал.

## Codec / Кодек

Sources used to compress this corpus live in [`codec/`](codec/):

Исходники, которыми сжат этот корпус, лежат в [`codec/`](codec/):

- `codec/palic-2/palic2.cpp` and `codec/palic-1/netpbm.hpp` (the local header included as `../palic-1/netpbm.hpp`)
- `codec/third_party/fse/` — FSE (tANS) from Yann Collet’s FiniteStateEntropy, BSD-2-Clause (see `LICENSE`)
- `codec/palic-2/CMakeLists.txt` — snapshot of the plt2 file; the `palic-2r` target is omitted because those sources are not shipped
- `codec/build.sh` — the build script below
- `codec/SOURCE.txt` — exact upstream pointer

Upstream: [`vovach777/plt2`](https://github.com/vovach777/plt2), branch `ctx5`, commit [`5569faae8efca72b32052d9bc1e53cb25b67d63f`](https://github.com/vovach777/plt2/commit/5569faae8efca72b32052d9bc1e53cb25b67d63f) ([`palic2.cpp` on ctx5](https://github.com/vovach777/plt2/blob/ctx5/palic-2/palic2.cpp)).

### Build / Сборка

From `codec/`:

```bash
./build.sh          # Linux x86-64-v3, fully static (default)
./build.sh v2       # Linux x86-64-v2, fully static
./build.sh linux-aarch64   # static aarch64 Linux ELF via cosmocc (needs the cosmocc toolchain)
./build.sh cosmocc  # fat Actually Portable Executable (palic-2.com)
./build.sh all
```

Equivalent `g++` for the x86-64-v3 Linux binary (FSE sources compiled as C):

```bash
gcc -O3 -march=x86-64-v3 -Wno-psabi -I third_party/fse -DFSEU16_MAX_SYMBOL_VALUE=1023 \
    -c third_party/fse/{entropy_common,fse_compress,fse_decompress,hist,fseU16}.c
g++ -O3 -march=x86-64-v3 -std=c++17 -Wno-psabi -I third_party/fse \
    -DFSEU16_MAX_SYMBOL_VALUE=1023 -DPLN_SSE \
    -c palic-2/palic2.cpp
g++ -O3 -static -static-libstdc++ -static-libgcc -o palic-2-linux-x86_64-v3 *.o
```

The original corpus was compressed with `g++ -O3 -march=native` on an AVX-512 Xeon; that native binary is **not** shipped (it is not portable).

Корпус сжимался через `g++ -O3 -march=native` на AVX-512 Xeon; этот нативный бинарник **не** выкладывается, он непереносим.

The fat APE is built with Cosmopolitan `cosmocc` by compiling the two architectures separately and joining them with `apelink` (SSE on x86_64, scalar fallback on aarch64). Toolchain: [cosmocc.zip](https://cosmo.zip/pub/cosmocc/cosmocc.zip) or the [GitHub release](https://github.com/jart/cosmopolitan/releases).

Fat APE собирается Cosmopolitan `cosmocc`: каждую архитектуру компилируют отдельно и склеивают через `apelink` (на x86_64 — SSE, на aarch64 — скалярный путь).

### Prebuilt binaries / Готовые бинарники

They are in [`codec/bin/`](codec/bin/) and in the [v1.0 release](https://github.com/vovach777/clic-palic2/releases/tag/v1.0):

Готовые файлы лежат в [`codec/bin/`](codec/bin/) и в [релизе v1.0](https://github.com/vovach777/clic-palic2/releases/tag/v1.0):

| File | What it is / Что это | CPU / requirements |
|------|----------------------|--------------------|
| `palic-2-linux-x86_64-v3` | static Linux x86-64 | x86-64-v3: AVX2, BMI2, FMA, … |
| `palic-2-linux-x86_64-v2` | static Linux x86-64 | x86-64-v2: SSE4.2, POPCNT, … (the codec itself only uses SSE4.1) |
| `palic-2-linux-aarch64` | static aarch64 Linux ELF (Cosmopolitan libc, not glibc) | 64-bit ARM, Linux |
| `palic-2.com` | fat [APE](https://justine.lol/ape.html): Linux / macOS / Windows / BSD, x86_64 + aarch64 | x86_64 runs the SSE path; aarch64 uses the scalar fallback |

**Apple Silicon macOS.** The first run of `palic-2.com` may compile the bundled APE loader (`ape-m1.c`) with the host compiler. Install Xcode Command Line Tools beforehand:

**macOS на Apple Silicon.** При первом запуске `palic-2.com` может скомпилировать встроенный загрузчик APE (`ape-m1.c`) компилятором хоста. Заранее установите Xcode Command Line Tools:

```bash
xcode-select --install
```

### Decompress / Распаковка

```bash
# color / цвет
palic-2 d in.pln out.ppm

# gray / серое
palic-2 d in.pln out.pgm
```

## Results / Результаты

All 1170 files were verified lossless by a round-trip `cmp` against the original PGM/PPM.

Все 1170 файлов проверены на сжатие без потерь: распакованный результат совпал с исходным PGM/PPM байт в байт (`cmp`).

| Set | Images | Original | Compressed | Ratio | Bits/pixel |
|-----|--------|----------|------------|-------|------------|
| gray (P5) | 585 | 1,363,953,867 | 666,124,409 | 48.8% | 3.907 bpp |
| color (P6) | 585 | 4,091,841,959 | 1,471,694,037 | 36.0% | 8.632 bpp |

Release [v1.0](https://github.com/vovach777/clic-palic2/releases/tag/v1.0) contains two separate tar archives of the compressed corpus (`clic-palic2-gray.tar`, `clic-palic2-color.tar`), the prebuilt binaries above, and a source tarball `palic-2-src.tar.gz`.

В релизе [v1.0](https://github.com/vovach777/clic-palic2/releases/tag/v1.0) лежат два отдельных tar-архива сжатого корпуса (серый и цветной), готовые бинарники и архив исходников `palic-2-src.tar.gz`.

## Release v2.0 — PLR (photos) and PLS (screens)

Lossless palic-2r compression of the same CLIC 2020 professional train set (PLR, default mode) plus screen-content sets (PLS, `-s`). Compressed files are **release assets only** and are not committed to the repository tree.

Сжатие без потерь того же корпуса CLIC 2020 в формате PLR (режим по умолчанию) и экранных наборов в формате PLS (`-s`). Сжатые файлы лежат **только в релизе**, в дерево репозитория они не коммитятся.

Upstream codec: [`vovach777/plt2`](https://github.com/vovach777/plt2), branch `ctx5`, commit [`36c0c650b62898796d57aaf010a193531f350d27`](https://github.com/vovach777/plt2/commit/36c0c650b62898796d57aaf010a193531f350d27), CMake target `palic-2r` (`palic-2/palic2r.cpp`). Built with **clang** 19.1.7, `-DPLT_ARCH=x86-64-v3` and `x86-64-v4`.

### Formats / Форматы

- **PLR** — default photo mode (static QH tables). Use for P5/P6 photographs (`*.plr`).
- **PLS** — screen mode (`-s`): per-plane PLR/PLS switch on each tile, Sparse-Raw split and screen QH tables. Use for screenshots, UI and icons (`*.pls`).

PLR — режим по умолчанию для фото. PLS (`-s`) — экранный режим: на каждую плоскость тайла выбирается PLR или PLS.

### Build / Сборка

```bash
cmake -S palic-2 -B b3 -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DPLT_ARCH=x86-64-v3
cmake --build b3 --target palic-2r

cmake -S palic-2 -B b4 -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DPLT_ARCH=x86-64-v4
cmake --build b4 --target palic-2r
```

Sources and this recipe are in the v2.0 asset `palic-2r-src.tar.gz` (`SOURCE.txt` has the commit hash). Prebuilt static Linux binaries and a fat APE are in the [v2.0 release](https://github.com/vovach777/clic-palic2/releases/tag/v2.0):

Исходники и эта команда — в ассете `palic-2r-src.tar.gz`. Готовые бинарники — в [релизе v2.0](https://github.com/vovach777/clic-palic2/releases/tag/v2.0):

| File | Notes |
|------|--------|
| `palic-2r-linux-x86_64-v3` | static Linux, `-march=x86-64-v3` (AVX2), clang 19.1.7 |
| `palic-2r-linux-x86_64-v4` | static Linux, `-march=x86-64-v4` (AVX-512). Compressed output is byte-identical to v3 |
| `palic-2r.com` | fat APE (x86_64 + aarch64, Cosmopolitan). x86_64 uses AVX2; aarch64 uses the scalar/generic path. Cross-checked against v3 |

On Apple Silicon macOS the first run of `palic-2r.com` may compile the bundled APE loader; install Xcode CLT first: `xcode-select --install`.

### Decompress / Распаковка

```bash
# photo / фото (PLR)
palic-2r d in.plr out.ppm    # color
palic-2r d in.plr out.pgm    # gray

# screen / экран (PLS)
palic-2r d in.pls out.ppm
```

Encode: `palic-2r c in.ppm out.plr` (photo) or `palic-2r c in.ppm out.pls -s` (screen).

### Results / Результаты

Round-trip `cmp` vs the original P5/P6: all published files ok. Speeds from `palic-2r bench DIR -r 1` (v3, clang, this AVX-512 Xeon).

Все опубликованные файлы прошли проверку `cmp` с исходным P5/P6. Скорости — `bench DIR -r 1` на v3.

| Set | Files | Original (P5/P6) | PLN2 v1.0 | PLR / PLS | bpp | enc MB/s | dec MB/s |
|-----|-------|------------------|-----------|-----------|-----|----------|----------|
| CLIC color (P6, PLR) | 585 | 4,091,841,959 | 1,471,694,037 | 1,454,255,606 | 8.5297 | 640.8 | 262.3 |
| CLIC gray (P5, PLR) | 585 | 1,363,953,867 | 666,124,409 | 663,717,864 | 3.8929 | 538.2 | 261.6 |
| halic-wins-screen-p6 (PLS) | 12 | 224,903,777 | — | 12,101,489 | 1.2914 | 1038.7 | 450.5 |
| gb82-sc (PLS, CC0) | 10 | 91,943,842 | — | 3,677,903 | 0.9600 | 1499.0 | 550.8 |
| qoi-screenshot-web (PLS, CC0) | 14 | 341,273,933 | — | 23,335,605 | 1.6411 | 1055.3 | 453.6 |
| icon-512 (PLS, Public Domain) | 213 | 167,513,211 | — | 9,048,924 | 1.2965 | 979.1 | 511.8 |
| icon-64 (PLS, Public Domain) | 213 | 2,620,113 | — | 554,064 | 5.0805 | 464.1 | 339.8 |
| screenshot-game (PLS, CC BY-SA 3.0) | 617 | 1,172,716,382 | — | 233,028,983 | 4.7682 | 653.8 | 350.4 |

Screen-set PNGs from [imazen/codec-corpus](https://github.com/imazen/codec-corpus) v1.1.0 were converted losslessly to P6; **alpha was dropped** (noted in each archive’s `NOTES.txt`, licenses included). One unreadable upstream PNG in `screenshot_game` (`Htdamg_affinity.png`) was skipped; 617 of 618 images are published.

PNG из codec-corpus переведены в P6 без потерь, **альфа-канал отброшен** (это указано в `NOTES.txt` каждого архива). В `screenshot_game` пропущен один нечитаемый исходный PNG.

v2.0 assets: `clic-palic2-plr-color.tar`, `clic-palic2-plr-gray.tar`, `screens-pls-<set>.tar`, the three binaries, `palic-2r-src.tar.gz`. See [v2.0](https://github.com/vovach777/clic-palic2/releases/tag/v2.0).
