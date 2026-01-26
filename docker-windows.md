# Debian 13.2.0 для Hyper-V VM

## Обязательные настройки Debian

```bash
# 1. Установка гостевых утилит Hyper-V (уже включены в ядро 6.8)
sudo apt update && sudo apt install -y linux-cloud-tools-common hyperv-daemons

# 2. Оптимизация динамической памяти
echo "options hv_balloon force_balloon=1" | sudo tee /etc/modprobe.d/hv_balloon.conf
echo "vm.swappiness=5" | sudo tee -a /etc/sysctl.conf  # Минимизировать свопинг

# 3. Настройка для Java-разработки
sudo apt install -y openjdk-21-jdk maven gradle docker.io
sudo usermod -aG docker $USER

# 4. Оптимизация файловой системы
echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=4G 0 0" | sudo tee -a /etc/fstab
echo "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=2G 0 0" | sudo tee -a /etc/fstab

# 5. Это улучшает точность таймеров для Java-приложений
# ЕДИНСТВЕННАЯ рекомендуемая настройка для большинства случаев:
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"\$GRUB_CMDLINE_LINUX_DEFAULT hv_tsc_clocksource=1\"" | sudo tee -a /etc/default/grub
sudo update-grub
sudo reboot
```

### проверка настроек Debian 13.2.0

```bash
# Посмотреть загруженные параметры:
cat /proc/cmdline
# Должно быть что-то вроде:
# BOOT_IMAGE=/vmlinuz-6.8.0-21-amd64 root=/dev/mapper/debian--vg-root ro quiet

# Проверить загруженные модули Hyper-V:
lsmod | grep hv_
# В Debian 13.2.0 должно быть:
hv_netvsc             123456  0
hv_storvsc            65432  1
hv_balloon            43210  0 # Критичен для динамической памяти!
hv_vmbus              98765  4 hv_netvsc,hv_utils,hv_storvsc,hv_balloon
```

## Конфигурация Hyper-V для Debian 13.2.0:

```powershell
$vmName = "Debian-13-Java-Dev"
New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 2 `
  -NewVHDPath "D:\VMs\$vmName\disk.vhdx" -NewVHDSizeBytes 150GB

# Критично для ядра 6.8: отключить Secure Boot
Set-VMFirmware -VMName $vmName -EnableSecureBoot Off

# Динамическая память с буфером для Java сборок
Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $true `
  -MinimumBytes 2GB -StartupBytes 4GB -MaximumBytes 32GB `
  -BufferPercentage 40  # Увеличенный буфер для Maven/Gradle

# Процессор: 6 ядер для параллельных сборок
Set-VMProcessor -VMName $vmName -Count 6 -Reserve 30 -Maximum 100
```

=================================================================================================
## dead:docker-windows



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