# host perfomance

## настройки RegEdit

```Windows Registry
Windows Registry Editor Version 5.00

; Оставлять ядро системы в памяти (не сбрасывать в файл подкачки)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"DisablePagingExecutive"=dword:00000001

; Disable APM sleeping mode and/or excessive HDD head parking
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\iaStorAC\Parameters\Device]
"EnableAPM"=dword:00000000
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\amdsata\Parameters\Device]
"EnableAPM"=dword:00000000
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device]
"EnableAPM"=dword:00000000

; Prefetcher/Superfetch: 0 - отключ, 2 - только для файлов загрузки (если отключена SysMain - фиолетово что тут)
; отключение для экономии ресурса SSD
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters]
"EnablePrefetcher"=dword:00000000
"EnableSuperfetch"=dword:00000000
```

## борьба Seagate S.M.A.R.T. Attribute 193 (C1 hex), "Load/Unload Cycle Count"

описание - [https://manpages.debian.org/testing/openseachest/](https://manpages.debian.org/testing/openseachest/)

утилита настройки - [https://github.com/Seagate/openSeaChest](https://github.com/Seagate/openSeaChest)

### настройка-1. Load/Unload Cycle Count

```cmd
openSeaChest_PowerControl.exe -d PD2 --idle_b disable --idle_c disable --standby_z disable
```

проверка-1

```cmd
openSeaChest_PowerControl.exe -d PD2 --showEPCSettings
```

### настройка-2. кеширование

```cmd
openSeaChest_Configure -d PD2 --readLookAhead enable --writeCache enable
```

проверка-2

```cmd
openSeaChest_Configure -d PD2 -i | egrep "(Write Cache:|Read Look-Ahead)"
```

### настройка-3. производительность

```cmd
openSeaChest_PowerControl.exe -d PD2 --setAPMLevel 254
```

проверка-3

```cmd
openSeaChest_PowerControl.exe -d PD2 --showAPMLevel
```

*дополнение*: применяется также при возникновении ошибки "Configuring EPC Settings is not supported on this device." при вызове настройка-1