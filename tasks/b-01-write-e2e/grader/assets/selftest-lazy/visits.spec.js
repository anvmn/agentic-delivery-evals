// Deliberately insufficient test — grader self-test only. It checks the list
// but never persistence, so it passes on BOTH fixtures and must be rejected
// by the broken_detected stage. This file documents why the double-fixture
// rule exists.
const { test, expect } = require('@playwright/test');

test('adding a visit shows in the list', async ({ page }) => {
  await page.goto('/');
  await page.fill('#patient-name', 'Lazy Test');
  await page.click('#add-visit');
  await expect(page.locator('.visit-item')).toHaveCount(1);
});
