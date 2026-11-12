# halic-wins-screen-p6 — screen content where HALIC 0.7.2 beats PLR

Samples for studying what HALIC does with screen content (colour / palette modes, repeats etc.).
12 raw PPM (P6, 8-bit RGB) images where HALIC 0.7.2 compresses better than PLR (palic-2r, plt2 branch ctx5).

Образцы экранного контента, где HALIC 0.7.2 жмёт лучше PLR, — для исследования, что HALIC делает с такими
картинками (цветовые режимы, палитра, повторы и т. п.). 12 файлов P6.

## Source / Источник

From [imazen/codec-corpus](https://github.com/imazen/codec-corpus) v1.1.0, both sets CC0 1.0:
- `gb82sc_*` — `gb82-sc/` (GB82 screen content by Gianni Rosato). `windows95` was a palette PNG, expanded to RGB.
- `qoiweb_*` — `qoi-benchmark/screenshot_web/` (web page screenshots by Dominic Szablewski, phoboslab.org); the
  PNGs were RGBA, alpha dropped.
Converted with `hlc/research/sc_convert.py` from vovach777/plt2 (ctx5).

## Sizes, bits per pixel / Размеры, бит на пиксель

PLR = palic-2r (QH tables), HALIC = 0.7.2 ST avx2 Linux static, all round trips ok. ratio = PLR / HALIC.

| file | size | PLR | HALIC 0.7.2 | HALIC FAST | ratio | HALIC round trip |
|---|---|---|---|---|---|---|
| gb82sc_imac_dark.ppm | 2940x1912 | 1.7684 | 1.6383 | 1.8570 | 1.08 | ok |
| gb82sc_imac_g3.ppm | 2940x1912 | 1.5969 | 1.4245 | 1.7771 | 1.12 | ok |
| gb82sc_imessage.ppm | 1206x2622 | 1.5272 | 1.2250 | 1.9594 | 1.25 | ok |
| gb82sc_terminal.ppm | 1646x1062 | 1.3078 | 1.1906 | 1.5435 | 1.10 | ok |
| gb82sc_windows.ppm | 2560x1392 | 2.2327 | 1.6541 | 1.7402 | 1.35 | ok |
| gb82sc_windows95.ppm | 640x480 | 2.9367 | 0.7641 | 0.7780 | 3.84 | ok |
| qoiweb_duckduckgo.com.ppm | 1313x2874 | 0.7999 | 0.6827 | 0.9676 | 1.17 | ok |
| qoiweb_en.wikipedia.org.ppm | 1313x2936 | 3.4456 | 3.1096 | 4.0319 | 1.11 | ok |
| qoiweb_news.ycombinator.com.ppm | 1325x1450 | 1.3553 | 1.0793 | 1.1984 | 1.26 | ok |
| qoiweb_phoboslab.org.ppm | 1313x20667 | 2.0179 | 1.6613 | 1.8687 | 1.21 | ok |
| qoiweb_stripe.com.ppm | 1313x6603 | 1.3030 | 1.2279 | 1.5745 | 1.06 | ok |
| qoiweb_sublime.ppm | 1008x9513 | 1.8559 | 1.5430 | 1.9648 | 1.20 | ok |

Note: on `windows95` and `windows` HALIC FAST is almost as good as HALIC (0.778 / 0.764 and 1.740 / 1.654), so the gain
there is not the slower context modelling of the normal mode but something structural that both modes share
(palette / few-colours mode, repeated rows or blocks, …) — a good first thing to look for.

Замечание: на `windows95` и `windows` HALIC FAST почти не уступает обычному HALIC, значит выигрыш там не от более
медленного контекстного моделирования, а от чего-то структурного, общего для обоих режимов (палитра / мало цветов,
повторы строк или блоков…) — с этого стоит начать.
