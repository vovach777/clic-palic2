# clic-palic2

Lossless palic-2 compression of the [CLIC 2020](https://www.compression.cc/) professional training set (`professional_train_2020`, 585 images).

Сжатие без потерь корпуса CLIC 2020 (`professional_train_2020`, 585 изображений) кодеком palic-2.

## Source / Источник

- Official dataset: CLIC 2020 professional train, 585 images.
- `gray/` — 8-bit grayscale PGM (P5), one `.pln` file per image.
- `color/` — 8-bit RGB PPM (P6), one `.pln` file per image.

Официальный набор CLIC 2020 professional train, 585 изображений. В `gray/` лежат сжатые серые PGM (P5), в `color/` — цветные PPM (P6), 8 бит на канал.

## Codec / Кодек

[palic-2](https://github.com/vovach777/plt2/blob/ctx5/palic-2/palic2.cpp) from [`vovach777/plt2`](https://github.com/vovach777/plt2), branch `ctx5`.

Built with:

```bash
g++ -O3 -march=native -o palic-2 palic2.cpp
```

Decompress / распаковка:

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

Release [v1.0](https://github.com/vovach777/clic-palic2/releases/tag/v1.0) contains two separate tar archives: `clic-palic2-gray.tar` and `clic-palic2-color.tar`.

В релизе [v1.0](https://github.com/vovach777/clic-palic2/releases/tag/v1.0) лежат два отдельных tar-архива: серый и цветной.
