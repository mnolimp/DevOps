# ---------- Стадия 1: зависимости ----------
FROM node:22-bookworm AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# ---------- Стадия 2: браузер ----------
FROM node:22-bookworm AS libs
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2 fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

    # ---------- Стадия 3: браузер ----------
FROM deps AS browser
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npx playwright install chromium

# ---------- Стадия 4: финальный образ ----------
FROM node:22-bookworm AS runtime
WORKDIR /app

COPY --from=libs /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=libs /usr/share/fonts /usr/share/fonts
COPY --from=libs /etc/fonts /etc/fonts

COPY --from=browser /ms-playwright /ms-playwright
COPY --from=deps /app/node_modules /app/node_modules
COPY package.json ./
COPY src ./src

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV NODE_ENV=production

CMD ["node", "src/scraper.js"]