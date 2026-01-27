# репозиторий полезных рецептов

[http выкладка - https://drtenguussr.github.io/dev-cookbook/](https://drtenguussr.github.io/dev-cookbook/)

- [работа с git/github - cookbook-github.md](cookbook-github.md)

## виртуальный сервер под Docker

задача: рабочее место для разработки Java приложений с применением технологии Docker. Ограничения: ОС - Windows 10 1809 Enterprise LTSC. Нужна поддержка Java 8.
Реализация: в Windows 10 устанавливается Hyper-V. Внутри Hyper-V запускается Debian. Внутри Debion стартует docker и среда разработки.

- настройка windows [01.host-setup-features.md](hyper-v-docker/01.host-setup-features.md)
- настройка производительности хоста - Windows [02.host-perfomance.md](hyper-v-docker/02.host-perfomance.md)
- конфигурация Hyper-V для Debian 13.2.0 и установка Debian [03.host-create-vm.md](hyper-v-docker/03.host-create-vm.md)
- уточнение про добавление Java 8u202

### проектирование-тестирование для стенда

- параметры [90.check-hdd.md](hyper-v-docker/90.check-hdd.md)
 