const { chromium } = require('playwright');
const { ReceiveMessageCommand, DeleteMessageCommand } = require("@aws-sdk/client-sqs");
const { PutObjectCommand } = require("@aws-sdk/client-s3");
const { sqs, s3 } = require('./aws.js');

const QUEUE_URL = process.env.SQS_QUEUE_URL;
const BUCKET_NAME = process.env.S3_BUCKET_NAME;

async function scrapeQuotes() {
  const browser = await chromium.launch({
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  const page = await browser.newPage();

  await page.goto('https://quotes.toscrape.com/scroll', {
    waitUntil: 'networkidle',
  });

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
  return quotes;
}

(async () => {
  if (!QUEUE_URL || !BUCKET_NAME) {
    console.error("Missing SQS_QUEUE_URL or S3_BUCKET_NAME environment variables");
    process.exit(1);
  }

  console.log("Waiting for a message from SQS...");
  
  // Получаем сообщение
  const { Messages } = await sqs.send(new ReceiveMessageCommand({
    QueueUrl: QUEUE_URL,
    MaxNumberOfMessages: 1,
    WaitTimeSeconds: 5, 
  }));

  if (!Messages || Messages.length === 0) {
    console.log("No messages in queue. Exiting.");
    return;
  }

  const message = Messages[0];
  console.log(`Got message ${message.MessageId}. Starting scrape...`);

  try {
    // Скрапим
    const quotes = await scrapeQuotes();
    console.log(`Scraped ${quotes.length} quotes.`);

    // Сохраняем в S3
    const key = `results/${message.MessageId}.json`;
    await s3.send(new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: JSON.stringify(quotes, null, 2),
      ContentType: "application/json",
    }));
    console.log(`Saved to S3: s3://${BUCKET_NAME}/${key}`);

    // Удаляем из SQS после успешной записи в S3
    await sqs.send(new DeleteMessageCommand({
      QueueUrl: QUEUE_URL,
      ReceiptHandle: message.ReceiptHandle,
    }));
    console.log("Message deleted from SQS.");
  } catch (err) {
    console.error("Failed to process message:", err);
  }
})();