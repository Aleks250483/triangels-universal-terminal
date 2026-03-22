# 🌍 TriAngels Universal Terminal Standard

Единый DevOps-терминал для всей инфраструктуры TriAngels.

> ⚡ Настройка за 30 секунд • Работает на macOS, Linux, NAS • Безопасен для серверов


## 🚀 Быстрый старт

```bash
curl -fsSL https://raw.githubusercontent.com/Aleks250483/triangels-universal-terminal/main/setup-triangels-universal.sh | bash
```
После установки:

source ~/.bashrc  # или ~/.zshrc

## 🎯 Зачем это нужно

TriAngels строит распределённую инфраструктуру.

Когда у вас 5 устройств — всё просто.  
Когда 20 — начинается хаос.  
Когда 50+ — без стандарта невозможно работать.

Разные сервера → разные окружения → ошибки → потеря времени.


С TriAngels Terminal Standard:

✔ все устройства выглядят одинаково  
✔ инженеры не путаются  
✔ партнёры быстрее обучаются  
✔ снижается количество ошибок  
✔ упрощается поддержка  


👉 Это фундамент DevOps-инфраструктуры TriAngels.

## ✅ Что вы получите

После установки каждый сервер, NAS и ноутбук будет выглядеть одинаково:

✔ цветное имя пользователя  
✔ цветное имя устройства  
✔ отображение IP-адреса  
✔ индикатор Docker 🐳  
✔ чистый и профессиональный prompt  
✔ единый стандарт TriAngels  


💡 Это упрощает работу, ускоряет обучение и снижает количество ошибок.

## 🧩 Поддерживаемые платформы

macOS Intel

macOS Apple Silicon (M1/M2/M3)

Linux x86_64

Linux ARM64

WSL (через Ubuntu)

Работает на:

✅ iMac / MacBook  
✅ Linux VPS  
✅ NAS (TerraMaster / Synology / Linux)  
✅ Домашние серверы  


## 🚀 Что делает этот скрипт

Скрипт приводит терминал к единому стандарту TriAngels на всех устройствах.

После установки каждый участник сети TriAngels видит одинаковую,
понятную и профессиональную рабочую среду.

## 🖥 Как выглядит результат

До установки:


user@server:~$


После установки:


taadmin 🖥 triangels-exit-hu-01 🌍 45.12.132.6 ~
🎯 ➜


Единый стиль на всех устройствах TriAngels.

## 🔒 Что скрипт НЕ делает

Важно понимать:

✗ не отправляет данные на сторонние серверы  
✗ не собирает никакую аналитику  
✗ не изменяет системные настройки без вашего ведома  
✗ не устанавливает ничего скрытого  

Скрипт полностью открыт и прозрачен — вы можете проверить его перед запуском.

## 🧠 Скрипт автоматически определяет

– операционную систему (macOS / Linux)  
– уровень доступа (пользователь или root)  
– способ подключения (SSH или локально)  
– наличие Docker  
– тип оболочки (bash / zsh)  

Ничего вручную настраивать не нужно.


## ✅ После установки вы получите

✔ Цветное имя пользователя  
✔ Цветное имя устройства  
✔ Отображение IP-адреса  
✔ Индикатор Docker 🐳  
✔ Профессиональный DevOps-вид терминала  
✔ Единый стандарт TriAngels  

Все устройства начинают выглядеть одинаково.


## ⚡ Быстрая установка (рекомендуется)

Подходит для macOS, Linux, VPS и NAS.
Скопируйте команду ниже и вставьте в терминал:

```bash
curl -fsSL https://raw.githubusercontent.com/Aleks250483/triangels-universal-terminal/main/setup-triangels-universal.sh | bash
```
Если команда не запускается — попробуйте:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Aleks250483/triangels-universal-terminal/main/setup-triangels-universal.sh)"
```
После установки примените изменения:

source ~/.bashrc   # для bash
source ~/.zshrc    # для zsh

Готово — откройте новый терминал 🚀

## 🔁 Авто-применение (опционально)

Если хотите, чтобы терминал применился автоматически
(только в интерактивной сессии):

```bash
TRIANGELS_AUTO_APPLY=1 curl -fsSL https://raw.githubusercontent.com/Aleks250483/triangels-universal-terminal/main/setup-triangels-universal.sh | bash
```

## 🔄 Обновление

Просто запустите установку повторно.

Скрипт:

создаёт резервные копии

обновляет только свой блок

не ломает существующие настройки

## ♻️ Удаление / откат

Удалить оформление:

```bash
# Remove TriAngels block from rc files
awk -v b='# >>> TRIANGELS_TERMINAL_STANDARD >>>' \
    -v e='# <<< TRIANGELS_TERMINAL_STANDARD <<<' \
    '$0==b{in=1;next} $0==e{in=0;next} !in{print}' \
    ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
```

При необходимости восстановите файлы:

~/.bashrc.bak.*
~/.zshrc.bak.*


## 🧩 Установка вручную (если требуется)

macOS / Linux:

```bash
chmod +x setup-triangels-universal.sh
./setup-triangels-universal.sh
```

Удалённый сервер (VPS / NAS):

```bash
ssh user@server
chmod +x setup-triangels-universal.sh
./setup-triangels-universal.sh
```

После установки переподключитесь по SSH.

```md
## 🎨 Цветовая логика TriAngels

| Тип устройства | Цвет |
|---------------|------|
| macOS         | 🔵 Синий |
| Linux VPS     | 🟢 Зелёный |
| root          | 🔴 Красный |
| Docker        | 🐳 Голубой |

## 🌐 Зачем это нужно

TriAngels строит собственную децентрализованную инфраструктуру.

Когда десятки устройств выглядят одинаково:

- проще обучать партнёров
- меньше ошибок
- быстрее поддержка
- единый инженерный стандарт

Это первый шаг к созданию:

✅ TriAngels Private Network
✅ T-Cloud инфраструктуре
✅ масштабируемой Mesh-сети

## 📦 Версия

TriAngels Universal Terminal Standard v1.2
Production Edition
