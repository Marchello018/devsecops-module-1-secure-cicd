# Module 1: Secure CI/CD Pipeline

Учебный проект для первого модуля по DevSecOps: минимальный FastAPI-сервис, Dockerfile и hardened pipeline на GitHub Actions.

## Что внутри

- `app/main.py` — FastAPI-приложение
- `app/test_main.py` — базовые тесты
- `app/requirements.txt` — runtime-зависимости
- `requirements-dev.txt` — dev/security-зависимости для локальной практики
- `.github/workflows/ci.yml` — secure CI pipeline
- `Dockerfile` — контейнеризация приложения
- `THREAT_MODEL.md` — модель угроз для CI/CD
- `scripts/check-prereqs.ps1` — проверка локального окружения
- `scripts/bootstrap.ps1` — разворачивание локальной среды и проверка проекта
- `scripts/publish-github.ps1` — публикация репозитория на GitHub

## Структура

```text
.
├── .github/
│   └── workflows/
│       └── ci.yml
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── requirements.txt
│   └── test_main.py
├── .dockerignore
├── .gitignore
├── Dockerfile
├── README.md
├── requirements-dev.txt
├── scripts/
│   ├── bootstrap.ps1
│   ├── check-prereqs.ps1
│   └── publish-github.ps1
└── THREAT_MODEL.md
```

## Быстрый старт

Run commands from the repository root.

Сначала проверь, чего не хватает на машине:

```powershell
.\scripts\check-prereqs.ps1
```

## Локальный запуск

Для локального запуска нужен Python 3.11+.

### Windows PowerShell

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
pytest app/test_main.py -q
uvicorn app.main:app --reload
```

После запуска приложение будет доступно на:

- `http://127.0.0.1:8000/`
- `http://127.0.0.1:8000/docs`

Для автоматического bootstrap используй:

```powershell
.\scripts\bootstrap.ps1
```

## Как устроен pipeline

`Secure CI` разделён на четыре job:

1. `test` — ставит зависимости и запускает `pytest`
2. `scan` — запускает `bandit` и `pip-audit`
3. `package` — собирает Docker image
4. `deploy` — доступен только для push в `main` и должен быть защищён через GitHub Environment

## Почему этот pipeline безопаснее baseline

- Минимальные права через `permissions: contents: read`
- Зафиксированные версии actions вместо плавающих тегов
- `persist-credentials: false` уменьшает риск утечки токена
- Никаких секретов и деплоя в `pull_request`
- Есть таймауты job и разделение доверенных/недоверенных стадий
- Deploy вынесен в `production` environment

## Что нужно настроить в GitHub

Все команды ниже выполняй из корня репозитория.

1. Создай пустой репозиторий на GitHub
2. Настрой `git user.name` и `git user.email`, если они ещё не заданы
3. Добавь remote
4. Сделай первый commit и push
5. В `Settings -> Environments` создай `production`
6. Включи `Required reviewers` для `production`

Команды:

```powershell
git config user.name "Your Name"
git config user.email "you@example.com"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git add .
git commit -m "Add secure CI/CD lesson project"
git push -u origin main
```

Или одной командой через helper-скрипт:

```powershell
.\scripts\publish-github.ps1 `
  -GitUserName "Your Name" `
  -GitUserEmail "you@example.com" `
  -RemoteUrl "https://github.com/<your-username>/<your-repo>.git"
```

## Установка инструментов

Если `winget` и `gh` не установлены, самый простой путь такой:

1. Установи Python 3.11+ с включённым `Add python.exe to PATH`
2. Установи Docker Desktop
3. При желании установи GitHub CLI (`gh`) для автоматизации работы с репозиториями

Полезные ссылки:

- [Python for Windows](https://www.python.org/downloads/windows/)
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
- [GitHub CLI](https://cli.github.com/)

## Письменные ответы для домашки

### Почему нельзя давать pipeline write permissions?

Если pipeline скомпрометируют, злоумышленник сможет менять код, workflow, релизы, теги и артефакты от имени репозитория. Это превращает CI из инструмента проверки в точку полного захвата supply chain.

### Чем опасны third-party actions?

Это чужой код, который исполняется внутри твоего pipeline и получает доступ к файлам, переменным окружения и иногда токенам. Если action окажется вредоносным или будет скомпрометирован, он сможет украсть данные или подменить процесс сборки.

### Почему PR из fork — риск?

Код в PR контролируется внешним автором. Если дать такому pipeline секреты или write-права, атакующий сможет встроить команды для их кражи или изменить артефакты сборки.

## Что говорить на собеседовании

> Я собрал secure CI/CD pipeline на GitHub Actions: ограничил permissions, зафиксировал версии actions, разделил test/scan/package/deploy, убрал deploy из untrusted pull request контекста и добавил protected deployment через environment approval.
