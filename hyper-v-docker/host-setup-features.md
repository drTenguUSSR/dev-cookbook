# Оптимальная конфигурация Windows Features для "Ubuntu VM + Docker"

## Windows Features

### ✅ ОБЯЗАТЕЛЬНО ВКЛЮЧИТЬ

1. Hyper-V - основной компонент для виртуализации
    - Hyper-V Platform (автоматически включается с Hyper-V)
    - Hyper-V Services (автоматически включается с Hyper-V)
2. Windows Process Activation Service (если доступен)
    - Необходим для управления виртуальными машинами через PowerShell
3. .NET Framework 3.5 (рекомендуется)
    - Некоторые инструменты управления Hyper-V требуют .NET 3.5

### ❌ ОБЯЗАТЕЛЬНО ВЫКЛЮЧИТЬ

1. Containers - не нужен, так как Docker работает внутри Ubuntu VM
2. Virtual Machine Platform - не нужен без WSL2
3. Windows Subsystem for Linux - не нужен, так как Linux будет в VM
4. Windows Hypervisor Platform - избыточен при включенном полном Hyper-V
5. SMB 1.0/CIFS Client (если не используется) - для безопасности

### ⚠️ ДОПОЛНИТЕЛЬНЫЕ РЕКОМЕНДАЦИИ

Производительность диска:

- Включить: File and Storage Services → Storage Services
- Отключить: Windows Search (если не критичен) - снижает нагрузку на диск

Сетевая производительность:

- Включить: Remote Differential Compression (для эффективной синхронизации)
- Настроить: Отключить энергосбережение для сетевых адаптеров в Device Manager

Управление ресурсами:

- Включить: Quality Windows Audio Video Experience (QWAVE) - помогает с распределением ресурсов CPU
Отключить: Print and Document Services (если не используется) - освобождает ресурсы

## Скрипт для автоматической настройки через PowerShell (Run as Admin)

```powershell
# ВКЛЮЧЕНИЕ необходимых компонентов
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All -All -NoRestart

# ВЫКЛЮЧЕНИЕ ненужных компонентов
Disable-WindowsOptionalFeature -Online -FeatureName Containers -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# ДОПОЛНИТЕЛЬНЫЕ ОПТИМИЗАЦИИ
# Отключение служб для повышения производительности
Set-Service -Name "SysMain" -StartupType Disabled  # SuperFetch
Set-Service -Name "DiagTrack" -StartupType Disabled  # Diagnostics Tracking
Set-Service -Name "WSearch" -StartupType Disabled   # Windows Search

# Настройка параметров питания для максимальной производительности
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance

Write-Host "Конфигурация завершена. Требуется перезагрузка." -ForegroundColor Green
Restart-Computer -Confirm
```

## Проверка конфигурации после перезагрузки

```powershell
# Проверка включенных Hyper-V компонентов
Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -like "*Hyper-V*" -and $_.State -eq "Enabled"}

# Проверка отключенных ненужных компонентов
Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -in @("Containers", "VirtualMachinePlatform", "Microsoft-Windows-Subsystem-Linux") -and $_.State -eq "Disabled"}

# Проверка состояния Hyper-V
Get-VMHost | Select-Object Name, VirtualHardDiskPath, VirtualMachinePath
```

## Важные замечания

1.BIOS/UEFI настройки (проверьте перед установкой)

- ✅ Virtualization Technology (Intel VT-x/AMD-V) - ВКЛЮЧЕНО
- ✅ SLAT (Second Level Address Translation) - ВКЛЮЧЕНО (требуется для динамической памяти)
- ❌ Hyper-V в BIOS не нужно включать отдельно - это настраивается в Windows

2.Требования к оборудованию

- RAM: Минимум 16GB (8GB для хоста + 8GB для VM с динамической памятью)
- CPU: 4+ физических ядра (рекомендуется 6+ для комфортной работы)
- Диск: SSD с 4K allocation unit size для VHDX файлов

Используйте `dism /online /get-features` для просмотра всех доступных компонентов
