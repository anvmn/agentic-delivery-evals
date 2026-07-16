// Reference solution — grader self-test only. Never shown to agents.
const { test, expect } = require('@playwright/test');

test('adding a visit updates the list and the counter', async ({ page }) => {
  await page.goto('/');
  await page.fill('#patient-name', 'Chana Levi');
  await page.selectOption('#visit-type', 'vaccination');
  await page.click('#add-visit');
  await expect(page.locator('.visit-item')).toHaveCount(1);
  await expect(page.locator('.visit-item').first()).toContainText('Chana Levi — vaccination');
  await expect(page.locator('#visit-count')).toHaveText('1');
});

test('visits survive a page reload', async ({ page }) => {
  await page.goto('/');
  await page.fill('#patient-name', 'Dov Katz');
  await page.click('#add-visit');
  await expect(page.locator('.visit-item')).toHaveCount(1);
  await page.reload();
  await expect(page.locator('.visit-item')).toHaveCount(1);
  await expect(page.locator('#visit-count')).toHaveText('1');
});
