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

## Проверка внутри Windows

crystal disk mark, 64gb, R70%/W30%
h: seq1m: read=810 mb/s, write=763 mb/s, mix=192 mb/s
g: srq1m: read=264 mb/s, write=264 mb/s, mix=150 mb/s

## Скрипт тестирования в Debian

```bash
#!/bin/bash
DISK="/dev/sdb"  # RAID 0 или LVM
mkdir -p /docker/test

echo "=== Random 4K Read ==="
fio --name=randread --ioengine=libaio --direct=1 --rw=randread --bs=4k --iodepth=64 --size=5G --runtime=30 --filename=/docker/test/testfile

echo "=== Random 4K Write ==="
fio --name=randwrite --ioengine=libaio --direct=1 --rw=randwrite --bs=4k --iodepth=64 --size=5G --runtime=30 --filename=/docker/test/testfile

echo "=== Sequential 1M ==="
fio --name=seq --ioengine=libaio --direct=1 --rw=randrw --bs=1M --iodepth=32 --rwmixread=50 --size=10G --runtime=30 --filename=/docker/test/testfile

rm -f /docker/test/testfile
```
