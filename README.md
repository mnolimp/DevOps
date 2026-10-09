# Quotes Scrapper

Скрапер цитат с сайта [quotes.toscrape.com/scroll](https://quotes.toscrape.com/scroll).
Открывает страницу в headless Chromium через Playwright, прокручивает её до конца
(данные подгружаются JavaScript), собирает цитаты и сохраняет их в `out/result.json`.

## Стек

- Node.js 22
- Playwright (Chromium)
- Docker (multistage build)
- Make (единственная точка входа)
- GitHub Actions (CI)

## Структура

```
.
├─ Dockerfile              # multistage: deps → browser → runtime
├─ Makefile                # build / run / clean / ci
├─ package.json
├─ package-lock.json
├─ src/
│  └─ scraper.js           # исходный код скрапера
├─ out/                    # результат (в git не коммитится)
└─ .github/workflows/ci.yml
```

## Локальная разработка

Требуется Node.js 22+.

```bash
# 1. Установить зависимости
npm install

# 2. Установить Chromium для Playwright
npx playwright install chromium

# 3. Запустить скрапер
npm start
```

Результат появится в `out/result.json`.

## Сборка продакшн-образа

Всё управление — через Makefile. Ручные `docker` команды не используются.

```bash
make build     # собрать образ quotes-scrapper:latest
make run       # запустить контейнер, результат в out/result.json
make clean     # удалить образ и out/
make ci        # полный цикл: build + run + валидация JSON
```

Если Docker требует прав суперпользователя:

```bash
make build SUDO=sudo
make run SUDO=sudo
make clean SUDO=sudo
```

## CI

GitHub Actions запускается на pull request в `main` и вызывает `make ci`.
Если `out/result.json` пустой или невалидный — пайплайн падает.

## Как это работает

### Dockerfile (multistage)

Три стадии:

1. **deps** — установка npm-зависимостей (`npm ci`).
2. **browser** — системные библиотеки + Chromium через `playwright install`.
3. **runtime** — финальный тонкий образ: только `node_modules`, браузер и код.

Такое разделение даёт кэширование: правка `src/scraper.js` не пересобирает
ни зависимости, ни браузер — эти слои берутся из кэша Docker.

### Makefile

Единственная точка входа. Цели:

- `build` — собрать образ;
- `run` — запустить контейнер с монтированием `out/`;
- `clean` — удалить образ и `out/`;
- `ci` — build + run + проверка, что JSON непустой и валидный.