const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage();

  await page.goto('https://quotes.toscrape.com/scroll', {
    waitUntil: 'networkidle',
  });

  // скроллим до конца, чтобы подгрузились все цитаты
  let previousCount = 0;
  while (true) {
    const count = await page.locator('.quote').count();
    if (count === previousCount) break;
    previousCount = count;
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await page.waitForTimeout(500);
  }

  const quotes = await page.$$eval('.quote', (nodes) =>
    nodes.map((n) => ({
      text: n.querySelector('.text')?.innerText.trim(),
      author: n.querySelector('.author')?.innerText.trim(),
      tags: Array.from(n.querySelectorAll('.tag')).map((t) => t.innerText.trim()),
    }))
  );

  await browser.close();

  const outDir = path.join(__dirname, '..', 'out');
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(
    path.join(outDir, 'result.json'),
    JSON.stringify(quotes, null, 2)
  );

  console.log(`Saved ${quotes.length} quotes`);
})();