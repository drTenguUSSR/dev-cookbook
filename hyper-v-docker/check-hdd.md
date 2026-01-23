# check-hdd

Планирование дисковой подсистемы для
Windows 10 1809 LTSC + (Debian Debian 13.2.0 + docker)

## Описание

базовые параметры.
H:, raid-0 средствами Windows, NTFS, 64к на четырех дисках. использовались специальные разделы вначале диска по 256Gb:

- ST2000DM008, D:
- ST4000NM0035, F:
- ST10000NM017B, G:
- ST8000VE001, K:

G:, самый быстрый диск

## проверка внутри Windows

crystal disk mark, 64gb, R70%/W30%
h: seq1m: read=810 mb/s, write=763 mb/s, mix=192 mb/s
g: srq1m: read=264 mb/s, write=264 mb/s, mix=150 mb/s