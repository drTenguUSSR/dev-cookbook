# репозиторий полезных рецептов

[http выкладка - https://drtenguussr.github.io/dev-cookbook/](https://drtenguussr.github.io/dev-cookbook/)

- [работа с git/github - cookbook-github.md](cookbook-github.md)

## виртуальный сервер под Docker

задача: рабочее место для разработки Java приложений с применением технологии Docker. Ограничения: ОС - Windows 10 1809 Enterprise LTSC. Нужна поддержка Java 8.
Реализация: в Windows 10 устанавливается Hyper-V. Внутри Hyper-V запускается Debian. Внутри Debion стартует docker и среда разработки.

- настройка windows [host-setup-features.md](hyper-v-docker/host-setup-features.md)
- производительность windows [host-perfomance.md](hyper-v-docker/host-perfomance.md)
- установка и настройка Debian
- уточнение про добавление Java 8u202


### проектирование-тестирование для стенда
- параметры [check-hdd.md](hyper-v-docker/check-hdd.md)