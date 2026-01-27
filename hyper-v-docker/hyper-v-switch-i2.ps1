#    1. VS Code. Нажать ctrl+shift+P. ввести "Change File Encoding", выбрать
#"Save With Encoding", выбрать "UTF8 with BOM".
#    2. Set-ExecutionPolicy Bypass -Scope Process -Force

# Получаем все коммутаторы
$switches = Get-VMSwitch | Sort-Object SwitchType, Name

foreach ($switch in $switches) {
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "Коммутатор: $($switch.Name)" -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host ("=" * 80) -ForegroundColor Cyan

    Write-Host "`n[Параметры коммутатора]" -ForegroundColor Yellow

    # Определяем тип макета
    $switchMode = "Стандартный"
    if ($switch.PSObject.Properties.Name -contains "EmbeddedTeamingEnabled") {
        if ($switch.EmbeddedTeamingEnabled) {
            $switchMode = "SET (Switch Embedded Teaming)"
        }
    }

    # Базовые параметры коммутатора
    $switchProps = [PSCustomObject]@{
        Имя              = $switch.Name
        Тип              = $switch.SwitchType
        ID               = $switch.Id
        Макет            = $switchMode
    }

    # Для внешних коммутаторов — пытаемся найти физический адаптер
    if ($switch.SwitchType -eq 'External') {
        $physicalAdapter = $null
        $speedGbps = "—"
        $status = "—"
        $adapterName = "—"

        # Способ 1: через свойство NetAdapterInterfaceDescription (если доступно в 1809)
        if ($switch.PSObject.Properties.Name -contains "NetAdapterInterfaceDescription") {
            $interfaceDesc = $switch.NetAdapterInterfaceDescription
            if ($interfaceDesc) {
                $physicalAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | 
                    Where-Object { 
                        $_.InterfaceDescription -eq $interfaceDesc -and 
                        $_.PhysicalAdapter -eq $true 
                    } | Select-Object -First 1
            }
        }

        # Способ 2: через анализ активных физических адаптеров (если способ 1 не сработал)
        if (-not $physicalAdapter) {
            $allPhysical = Get-CimInstance -ClassName Win32_NetworkAdapter | 
                Where-Object { 
                    $_.PhysicalAdapter -eq $true -and 
                    $_.NetEnabled -eq $true -and 
                    $_.InterfaceDescription -notlike "*vEthernet*" 
                }

            # Эвристика: выбираем адаптер с максимальной скоростью (обычно это основной)
            $physicalAdapter = $allPhysical | Sort-Object -Property Speed -Descending | Select-Object -First 1
        }

        # Формируем данные
        if ($physicalAdapter) {
            $adapterName = $physicalAdapter.Name
            $status = if ($physicalAdapter.NetEnabled) { "Up" } else { "Down" }
            if ($physicalAdapter.Speed -gt 0) {
                $speedGbps = "$([math]::Round($physicalAdapter.Speed / 1GB, 2)) Gbps"
            }
            else {
                $speedGbps = "Неизвестно"
            }
        }
        else {
            $adapterName = "Не определён"
            $status = "—"
            $speedGbps = "—"
        }

        $switchProps | Add-Member -NotePropertyMembers @{
            ФизическийАдаптер = $adapterName
            Состояние         = $status
            Скорость          = $speedGbps
        } -Force
    }
    else {
        $switchProps | Add-Member -NotePropertyMembers @{
            ФизическийАдаптер = "— (внутренний/частный коммутатор)"
            Состояние         = "—"
            Скорость          = "—"
        } -Force
    }

    $switchProps | Format-List
}