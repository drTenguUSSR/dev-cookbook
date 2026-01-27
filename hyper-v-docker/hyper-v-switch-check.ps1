<#
.SYNOPSIS
    Анализ всех виртуальных коммутаторов Hyper-V и параметров сетевых адаптеров ВМ
    Полностью совместим с PowerShell 5.1 (Windows 10 1809 LTSC)

    1. VS Code. Нажать ctrl+shift+P. ввести "Change File Encoding", выбрать
"Save With Encoding", выбрать "UTF8 with BOM".
    2. Set-ExecutionPolicy Bypass -Scope Process -Force
#>

# Получаем все коммутаторы
$switches = Get-VMSwitch | Sort-Object SwitchType, Name

if (-not $switches) {
    Write-Warning "Не найдено виртуальных коммутаторов на хосте"
    return
}

foreach ($switch in $switches) {
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "Коммутатор: $($switch.Name)" -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host ("=" * 80) -ForegroundColor Cyan

    # === Параметры коммутатора ===
    Write-Host "`n[Параметры коммутатора]" -ForegroundColor Yellow

    # Определяем тип макета (без тернарного оператора)
    $switchMode = "Стандартный"
    if ($switch.PSObject.Properties.Name -contains "EmbeddedTeamingEnabled") {
        if ($switch.EmbeddedTeamingEnabled) {
            $switchMode = "SET (Switch Embedded Teaming)"
        }
    }

    $switchProps = [PSCustomObject]@{
        Имя              = $switch.Name
        Тип              = $switch.SwitchType
        ID               = $switch.Id
        Макет            = $switchMode
    }

    # Для внешних коммутаторов — физический адаптер
    if ($switch.SwitchType -eq 'External') {
        try {
            $netAdapter = Get-NetAdapter | Where-Object { 
                $_.InterfaceDescription -like "*$($switch.Name)*" 
            } | Select-Object -First 1

            if ($netAdapter) {
                $switchProps | Add-Member -NotePropertyMembers @{
                    ФизическийАдаптер = "$($netAdapter.Name) ($($netAdapter.InterfaceDescription))"
                    Состояние         = $netAdapter.Status
                    Скорость          = "$([math]::Round($netAdapter.Speed / 1GB, 2)) Gbps"
                } -Force
            }
            else {
                $switchProps | Add-Member -NotePropertyMembers @{
                    ФизическийАдаптер = "Не определён (возможно, адаптер отключён)"
                    Состояние         = "Неизвестно"
                    Скорость          = "—"
                } -Force
            }
        }
        catch {
            $switchProps | Add-Member -NotePropertyMembers @{
                ФизическийАдаптер = "Ошибка получения данных"
                Состояние         = "—"
                Скорость          = "—"
            } -Force
        }
    }
    else {
        $switchProps | Add-Member -NotePropertyMembers @{
            ФизическийАдаптер = "— (внутренний/частный коммутатор)"
            Состояние         = "—"
            Скорость          = "—"
        } -Force
    }

    $switchProps | Format-List

    # === ВМ, подключённые к коммутатору ===
    Write-Host "`n[Виртуальные машины, подключённые к коммутатору]" -ForegroundColor Yellow

    # Надёжное получение адаптеров ВМ (фильтруем системные адаптеры с $null VMName)
    $allAdapters = Get-VMNetworkAdapter -All | Where-Object { 
        $_.VMName -ne $null -and $_.VMName -ne '' 
    }

    $connectedVMs = $allAdapters | Where-Object { 
        $_.SwitchName -eq $switch.Name 
    } | Sort-Object -Property { $_.VMName }

    if (-not $connectedVMs) {
        Write-Host "  Нет подключённых ВМ" -ForegroundColor Green
        continue
    }

    foreach ($adapter in $connectedVMs) {
        # Дополнительная проверка на случай, если ВМ была удалена после получения адаптеров
        $vm = $null
        try {
            $vm = Get-VM -Name $adapter.VMName -ErrorAction Stop
        }
        catch {
            Write-Host "  ⚠ Пропущен адаптер: ВМ '$($adapter.VMName)' не найдена (возможно, удалена)" -ForegroundColor Yellow
            continue
        }

        Write-Host "`n  ┌─ ВМ: $($adapter.VMName)" -ForegroundColor Magenta
        Write-Host "  ├─ Состояние: $($vm.State)" -ForegroundColor Gray

        # Имя адаптера
        Write-Host "  ├─ Имя адаптера      : $($adapter.Name)" -ForegroundColor Gray
        
        # MAC-адрес
        Write-Host "  ├─ MAC-адрес         : $($adapter.MacAddress)" -ForegroundColor Gray
        
        # Динамический MAC
        $dynamicMac = if ($adapter.DynamicMacAddressEnabled) { 'Да' } else { 'Нет' }
        Write-Host "  ├─ Динамический MAC  : $dynamicMac" -ForegroundColor Gray

        # MacAddressSpoofing с цветом
        if ($adapter.MacAddressSpoofing -eq 'On') {
            Write-Host "  ├─ MacAddressSpoofing: Вкл" -ForegroundColor Green
        } else {
            Write-Host "  ├─ MacAddressSpoofing: Выкл" -ForegroundColor Red
        }

        # AllowTeaming с цветом
        if ($adapter.AllowTeaming -eq 'On') {
            Write-Host "  ├─ AllowTeaming      : Вкл" -ForegroundColor Green
        } else {
            Write-Host "  ├─ AllowTeaming      : Выкл" -ForegroundColor Gray
        }

        # VmqWeight с цветовой индикацией
        if ($adapter.VmqWeight -ge 80) {
            $vmqColor = 'Green'
            $vmqLabel = 'Высокий'
        } elseif ($adapter.VmqWeight -ge 50) {
            $vmqColor = 'Yellow'
            $vmqLabel = 'Средний'
        } else {
            $vmqColor = 'Red'
            $vmqLabel = 'Низкий'
        }
        Write-Host "  ├─ VmqWeight         : $($adapter.VmqWeight) ($vmqLabel)" -ForegroundColor $vmqColor

        # Дополнительные параметры
        Write-Host "  ├─ VmqUsage          : $([math]::Round($adapter.VmqUsage, 1))%" -ForegroundColor Gray
        Write-Host "  ├─ IPsecOffload      : $($adapter.IPsecOffloadMaxSA)" -ForegroundColor Gray
        Write-Host "  ├─ RouterGuard       : $($adapter.RouterGuard)" -ForegroundColor Gray
        Write-Host "  └─ DHCPGuard         : $($adapter.DHCPGuard)" -ForegroundColor Gray
    }

    Write-Host ""
}

# === Итоговая сводка ===
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "ИТОГОВАЯ СВОДКА" -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host ("=" * 80) -ForegroundColor Cyan

$externalCount = ($switches | Where-Object { $_.SwitchType -eq 'External' }).Count
$internalCount = ($switches | Where-Object { $_.SwitchType -eq 'Internal' }).Count
$privateCount  = ($switches | Where-Object { $_.SwitchType -eq 'Private' }).Count

# Надёжный подсчёт ВМ (через все адаптеры с фильтрацией)
$allValidAdapters = Get-VMNetworkAdapter -All | Where-Object { 
    $_.VMName -ne $null -and $_.VMName -ne '' 
}
$totalVMs = ($allValidAdapters | Select-Object -ExpandProperty VMName -Unique).Count
$spoofingOn = ($allValidAdapters | Where-Object { $_.MacAddressSpoofing -eq 'On' }).Count

$summary = [PSCustomObject]@{
    ВсегоКоммутаторов     = $switches.Count
    Внешних              = $externalCount
    Внутренних           = $internalCount
    Частных              = $privateCount
    ВсегоВМ              = $totalVMs
    ВМсВключённымSpoofing = $spoofingOn
}

$summary | Format-List

# Предупреждения для критичных случаев
$runningVMs = Get-VM | Where-Object { $_.State -eq 'Running' }
$adaptersWithoutSpoofing = @()
foreach ($vm in $runningVMs) {
    $adapters = Get-VMNetworkAdapter -VMName $vm.Name -ErrorAction SilentlyContinue
    foreach ($adapter in $adapters) {
        if ($adapter.MacAddressSpoofing -ne 'On') {
            $adaptersWithoutSpoofing += $adapter
        }
    }
}

if ($adaptersWithoutSpoofing.Count -gt 0) {
    Write-Host "`n⚠️  ВНИМАНИЕ: обнаружены работающие ВМ без MacAddressSpoofing (проблемы с Minikube/Docker):" -ForegroundColor Red
    foreach ($badAdapter in $adaptersWithoutSpoofing) {
        Write-Host "   - $($badAdapter.VMName) (коммутатор: $($badAdapter.SwitchName))" -ForegroundColor Red
    }
}
