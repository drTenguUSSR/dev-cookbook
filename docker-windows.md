# docker-windows

```bash
# Проверить загруженные модули Hyper-V:
$ lsmod | grep hv_
hv_vmbus             123456  5 hv_netvsc,hv_utils,hv_storvsc,hv_balloon,hv_sock
hv_netvsc             65432  0
hv_storvsc            32109  2
hv_balloon            21098  0  # Критичен для динамической памяти!

# Проверить статус Hyper-V интеграции:
$ sudo dmesg | grep -i hyper-v
[    1.234567] Hyper-V Host Build:18362-10.0-3-0.3194
[    1.234568] Hyper-V: Registering HyperV Bus
[    1.234569] hv_vmbus: VMBUS IC version 3.0
```

Оптимизация для Hyper-V:

- ✅ hv_balloon - драйвер для динамической памяти (стабильно работает с ядром 6.1)
- ✅ hv_netvsc - сетевой драйвер с производительностью 98% от нативного
- ✅ hv_storvsc - SCSI контроллер для дисков (50K+ IOPS на SSD)

Проблема с Ubuntu 24.04 и новыми ядрами

```bash
# Пример проблемы в Ubuntu 24.04 (ядро 6.8):
dmesg | grep -i "balloon"
[  123.456] hv_balloon: Balloon request rejected: out of memory
[  123.457] hv_balloon: Failed to hot-add memory
```

Причина: В новых ядрах Linux (6.6+) изменилась логика работы с динамической памятью Hyper-V. Debian 12 с ядром 6.1 имеет проверенную и стабильную реализацию.

Debian 13.2.0

- ✅ hv_balloon v3 — мгновенное выделение памяти без фрагментации
- ✅ hv_netvsc RSS — распределение сетевой нагрузки по нескольким ядрам
- ✅ hv_storvsc Direct I/O — 2x скорость для баз данных в контейнерах
- ✅ hv_timesync — точность синхронизации времени ±1мс (критично для распределенных систем)

!!! далее от отметки "Оптимизация Debian 13.2.0 для Hyper-V VM" в чате docker-1809 !!!

debian-13.2.0-amd64-DVD-1.iso

==========================================================

! Пример конфигурации Ubuntu VM для максимальной производительности

! 1. Создание VM с оптимальными настройками
$vmName = "Ubuntu-Docker-Host"
New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 2 -NewVHDPath "D:\VMs\$vmName\disk.vhdx" -NewVHDSizeBytes 120GB

! 2. Настройка процессора (рекомендуется фиксированное ядро для стабильности)
Set-VMProcessor -VMName $vmName -Count 4 -Reserve 25 -Maximum 100

! 3. КРИТИЧЕСКИ ВАЖНО: Настройка динамической памяти
Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true `
  -MinimumBytes 2GB `
  -StartupBytes 4GB `
  -MaximumBytes 24GB `
  -BufferPercentage 30  # 30% буфер для быстрого роста

! 4. Сеть: Использование External switch для максимальной производительности
$switchName = "Docker-Optimized"
New-VMSwitch -Name $switchName -NetAdapterName (Get-NetAdapter | Where Status -eq 'Up' | Select -First 1).Name -AllowManagementOS $true
Connect-VMNetworkAdapter -VMName $vmName -SwitchName $switchName

! 5. Диск: Оптимизация VHDX для SSD
Optimize-VHD -Path "D:\VMs\$vmName\disk.vhdx" -Mode Full
Set-VHD -Path "D:\VMs\$vmName\disk.vhdx" -PhysicalSectorSizeBytes 4096

=======================================================

! /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65535,
      "Soft": 65535
    }
  }
}

! Настройка swappiness для лучшей работы с динамической памятью
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p