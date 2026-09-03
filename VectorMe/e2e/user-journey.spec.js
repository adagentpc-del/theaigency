const { test, expect } = require('@playwright/test');
const { PNG } = require('pngjs');
const fs = require('node:fs/promises');

function makeLogoPng() {
  const png = new PNG({ width: 128, height: 128 });
  for (let y = 0; y < 128; y++) for (let x = 0; x < 128; x++) {
    const i = (y * 128 + x) * 4;
    let r = 255, g = 255, b = 255, a = 255;
    const outer = x >= 20 && x <= 107 && y >= 20 && y <= 107;
    const hole = x >= 43 && x <= 84 && y >= 43 && y <= 84;
    if (outer && !hole) r = g = b = 18;
    if (x >= 52 && x <= 76 && y >= 4 && y <= 18) { r = 200; g = 35; b = 35; }
    png.data[i] = r; png.data[i + 1] = g; png.data[i + 2] = b; png.data[i + 3] = a;
  }
  return PNG.sync.write(png);
}

async function uploadAndVectorize(page) {
  await page.locator('#fileInput').setInputFiles({
    name: 'customer-logo.png',
    mimeType: 'image/png',
    buffer: makeLogoPng()
  });
  await expect(page.locator('#workspace')).toBeVisible();
  await expect(page.locator('#analysisPanel')).toBeVisible();
  await expect(page.locator('#analysisSummary')).toContainText('Source size');
  await page.getByRole('button', { name: 'T-shirt / apparel' }).click();
  await page.getByRole('button', { name: 'Vectorize artwork' }).click();
  await expect(page.locator('#vectorPreview svg')).toBeVisible();
  await expect(page.locator('#printCheck')).toBeVisible();
  await expect(page.locator('#exports')).toBeVisible();
  await expect(page.locator('#statusText')).toContainText('vector shapes');
  await expect(page.locator('#vendorNextStep')).toContainText('Best files to send your printer');
}

async function expectDownload(page, buttonName, signature) {
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: buttonName, exact: true }).click();
  const download = await downloadPromise;
  const path = await download.path();
  expect(path).toBeTruthy();
  const bytes = await fs.readFile(path);
  expect(bytes.subarray(0, signature.length).equals(signature)).toBeTruthy();
  return { download, bytes };
}

test('customer can go from PNG to usable print-production files', async ({ page }, testInfo) => {
  const pageErrors = [];
  page.on('pageerror', err => pageErrors.push(err.message));

  await page.goto('/');
  await expect(page).toHaveTitle(/Vector Me/);
  await expect(page.getByRole('heading', { name: 'Turn this into a real vector file.' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Upload your artwork' })).toBeVisible();

  await uploadAndVectorize(page);

  await page.getByRole('button', { name: 'Compare' }).click();
  await expect(page.locator('#comparePreview')).toBeVisible();
  await page.locator('#compareSlider').fill('70');

  const svg = await expectDownload(page, 'Download SVG', Buffer.from('<svg'));
  expect(svg.bytes.toString('utf8')).toContain('<path');
  expect(svg.bytes.toString('utf8')).not.toContain('<image');
  expect(svg.bytes.toString('utf8')).toContain('fill-rule="evenodd"');

  await expectDownload(page, 'Download vector PDF', Buffer.from('%PDF'));
  await expectDownload(page, 'Download transparent PNG', Buffer.from([0x89,0x50,0x4e,0x47]));
  await expectDownload(page, 'Download printer package (.ZIP)', Buffer.from('PK'));

  const email = `qa-${Date.now()}-${testInfo.project.name.replace(/\W/g,'')}@example.com`;
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.getByRole('button', { name: 'Create an account instead' }).click();
  await page.locator('#authEmail').fill(email);
  await page.locator('#authPassword').fill('correct-horse-battery-staple');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect(page.locator('#accountDialog')).not.toBeVisible();
  await expect(page.locator('#accountButton')).toContainText(email);

  await page.getByRole('button', { name: 'Save project' }).click();
  await expect(page.locator('#saveProject')).toHaveText('Saved');
  await page.getByRole('button', { name: 'My vectors' }).click();
  await expect(page.locator('#projectList')).toContainText('customer-logo');
  await page.locator('[data-open]').first().click();
  await expect(page.locator('#vectorPreview svg')).toBeVisible();

  await page.getByRole('button', { name: 'My vectors' }).click();
  page.once('dialog', d => d.accept());
  await page.locator('[data-delete]').first().click();
  await expect(page.locator('#projectList')).toContainText('No saved vectors yet.');
  await page.locator('#projectsClose').click();

  expect(pageErrors).toEqual([]);
});

test('second fresh project clearly routes a zero-credit user to pricing', async ({ page }) => {
  await page.goto('/');
  await uploadAndVectorize(page);
  await expectDownload(page, 'Download SVG', Buffer.from('<svg'));

  const email = `credits-${Date.now()}@example.com`;
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.getByRole('button', { name: 'Create an account instead' }).click();
  await page.locator('#authEmail').fill(email);
  await page.locator('#authPassword').fill('correct-horse-battery-staple');
  await page.getByRole('button', { name: 'Create account' }).click();

  await page.getByRole('button', { name: 'New file' }).click();
  await uploadAndVectorize(page);
  await page.getByRole('button', { name: 'Download SVG' }).click();
  await expect(page.locator('#vmToast')).toContainText('export credit');
  await expect(page.locator('#pricing')).toBeVisible();
  await expect(page.locator('#creditBadge')).toContainText('0 credits');
});
