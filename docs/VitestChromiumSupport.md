# Running Vitest Chromium Tests on Termux

Install Chromium:

```bash
pkg install chromium
```

Then in the project:

```bash
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install -D @vitest/browser-playwright playwright
```

For vitest config:

```js
import { playwright } from '@vitest/browser-playwright'

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      headless: true,
      provider: playwright({
        launchOptions: {
          executablePath: '/data/data/com.termux/files/usr/bin/chromium-browser',
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',

            // '--disable-gpu', else the below:
            '--ignore-gpu-blocklist',
            '--enable-unsafe-webgpu',
            '--enable-features=Vulkan',
            '--use-vulkan=native',
          ]
        }
      }),
      instances: [{ browser: 'chromium' }]
    }
  }
})
```
