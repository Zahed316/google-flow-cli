---
name: google-flow
description: Automate Google Flow (flow.google.com) AI video and image generation via Playwright over Chrome Remote Debugging (CDP on port 9222). Supports persistent Google authentication, model selection (Omni 1.1 Flash, Veo 3.1 Fast/Lite/Quality, Nano Banana Pro/Lite/2.1), media type switching (video/image), Angular CDK overlay handling, resolution/duration/aspect configuration, Start/End keyframe uploads in Frames mode, ProseMirror prompt injection, and direct Google Cloud CDN signed URL extraction and download via curl. Consult references/models-and-settings.md for complete model matrix and rules.
---

# Google Flow Automation (`google-flow`)

Automates Google Flow (`flow.google.com`) for generative AI video production. Built around a Chrome DevTools Protocol (CDP) bridge that preserves genuine Google session cookies while granting Playwright programmatic DOM control.

---

## Architecture Overview

```
+-------------------------------------------------------------------+
| Host System (Linux / X11 / Wayland)                               |
|                                                                   |
|   1. Launch Real Chrome (Zero automation flags)                   |
|      /opt/google/chrome/chrome --remote-debugging-port=9222       |
|                                --user-data-dir=~/.config/...      |
|                                                                   |
|   2. Playwright CDP Connection                                    |
|      chromium.connectOverCDP('http://127.0.0.1:9222')             |
|                                                                   |
|   3. Google Flow (flow.google.com)                                |
|      - Angular CDK Overlay & Backdrop management (Escape key)     |
|      - Mode: 'Frames' (Start / End Keyframes)                     |
|      - Settings: 720p / 9:16 Vertical / 8s / Omni 1.1 Flash       |
|      - ProseMirror Prompt Injection                               |
|      - Virtual Scroll lazy-tile hover trigger                     |
|                                                                   |
|   4. Output Retrieval                                             |
|      - Extract signed CDN URL: flow-content.google/video/...      |
|      - Direct curl download (Bypasses browser download dialogs)   |
+-------------------------------------------------------------------+
```

### Why CDP Over Standard Playwright Launch?
Standard `chromium.launch()` adds `--enable-automation` and `--disable-blink-features=AutomationControlled`, triggering Google Accounts bot detection (`"This browser or app may not be secure"`). Launching native Chrome with `--remote-debugging-port=9222` and a persistent `--user-data-dir` maintains legitimate Google login indefinitely with zero detection artifacts.

---

## 1. Quick Start & Prerequisites

### Launching Chrome with CDP

Run the included launcher script or start Chrome directly:

```bash
# Using the launcher script
~/.claude/skills/google-flow/scripts/launch_chrome.sh

# Or direct invocation
/opt/google/chrome/chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.config/google-chrome-flow" \
  https://flow.google.com >/dev/null 2>&1 &
```

Verify CDP is listening:
```bash
curl -s http://127.0.0.1:9222/json/version
```

### CLI Controller Usage (`flow` / `google-flow`)

The CLI is globally available as `flow` (and `google-flow`) in `~/.local/bin/flow`, adhering to the command line interface guidelines of `onflow/flow-cli` (`noun verb` commands, declarative `flow.json` project configuration, short/long flags, and JSON pipeability).

```bash
# 1. Initialize project configuration in current directory (scaffolds flow.json)
flow init

# 2. Check active project status and diagnostics
flow status
flow doctor

# 3. Configure media type, model family, resolution, duration, aspect, and mode
# Video generation with Veo 3.1 Fast:
flow config --media video -M "Veo 3.1 - Fast" -r 720p -d 8s -a 9:16 -m Frames

# Image generation with Nano Banana Pro:
flow config --media image -M "Nano Banana Pro" -a 9:16

# 4. Setup keyframes, prompt, and generate a scene
flow scene \
  -s "/path/to/scene_start.png" \
  -e "/path/to/scene_end.png" \
  -p "Minimalist Swiss motion graphic: golden turkey transforms into dark obsidian." \
  -M "Veo 3.1 - Fast" \
  --generate \
  -w \
  -t 300 \
  -o "./output_scene.mp4"

# 5. Execute declarative pipeline from flow.json
flow run --dry-run
flow run --scene scene_01

# 6. List and download project videos
flow videos list --json | jq .
flow videos download-latest -o "./rendered_video.mp4"
```

---

## 2. Declarative Project Spec (`flow.json`)

Running `flow init` scaffolds a `flow.json` specification:

```json
{
  "$schema": "https://flow.google/schema/v1.json",
  "version": "1.0.0",
  "name": "my-project",
  "project": {
    "id": "547683bf-5c5e-4ad3-8943-d2df0a4575c5",
    "url": "https://flow.google.com/project/547683bf-5c5e-4ad3-8943-d2df0a4575c5",
    "title": "Google Flow Project"
  },
  "defaults": {
    "mediaType": "video",
    "model": "Omni 1.1 Flash",
    "resolution": "720p",
    "duration": "8s",
    "aspect": "9:16",
    "mode": "Frames",
    "batches": "x1",
    "timeout": 300
  },
  "scenes": [
    {
      "name": "scene_01",
      "model": "Veo 3.1 - Fast",
      "start": "assets/frames/scene_01_start.png",
      "end": "assets/frames/scene_01_end.png",
      "prompt": "Minimalist Swiss motion graphic...",
      "output": "assets/videos/scene_01.mp4"
    }
  ]
}
```

Commands (`flow status`, `flow scene`, `flow run`) auto-detect `flow.json` in the current working directory or upward. Explicit CLI flags override `flow.json` defaults. Consult `references/models-and-settings.md` for full model choices and rules.

---

## 2. Core Automation Rules & Patterns

### Rule 1: Angular CDK Overlay & Backdrop Management
Google Flow wraps modal dialogs, menus, and asset choosers in Angular CDK overlays (`.cdk-overlay-pane`, `.cdk-overlay-backdrop`). An active backdrop intercepts pointer events across the page.
- **Always dismiss overlays prior to and after modal actions** by sending the `Escape` key:
  ```javascript
  await page.keyboard.press("Escape");
  await page.waitForTimeout(300);
  ```

### Rule 2: Model Family & Media Type Selection
Google Flow supports two primary media formats (`Video` vs `Image`) and distinct AI model families:
- **Video Models**: `Omni 1.1 Flash` (multimodal + audio), `Veo 3.1 - Fast` (high-speed), `Veo 3.1 - Lite` (efficient), `Veo 3.1 - Quality` (photorealistic).
- **Image Models**: `Nano Banana 2.1` (default), `Nano Banana Pro` (high-detail), `Nano Banana 2 Lite` (fast draft).

To select a model:
```javascript
// 1. Open primary settings overlay
const settingsBtn = await page.$("button[aria-label='Settings trigger']");
await settingsBtn.click();
await page.waitForTimeout(400);

// 2. Select Media Type toggle (Video or Image)
const mediaToggle = await page.$(`.cdk-overlay-pane mat-button-toggle:has-text('${mediaType}') button`);
if (mediaToggle) await mediaToggle.click();

// 3. Open secondary model dropdown menu
const modelTrigger = await page.$(".cdk-overlay-pane button[aria-label='Select model family']");
await modelTrigger.click();
await page.waitForTimeout(400);

// 4. Click target model menu item and dismiss overlay
const option = await page.$(`.cdk-overlay-pane button[role='menuitem']:has-text('${targetModel}')`);
if (option) await option.click();
await page.keyboard.press("Escape");
```

### Rule 3: Resolution, Duration, Aspect Ratio & Batches Configuration
The settings pill button (`button[aria-label="Settings trigger"]`) exposes an overlay containing `mat-button-toggle` controls:
- **Resolution**: `720p` or `360p` (Video only)
- **Aspect Ratio**: `9:16` (Vertical), `16:9` (Landscape) for Video; plus `1:1`, `4:3`, `3:4` for Image
- **Duration**: `4s`, `6s`, `8s`, or `10s` (Video only)
- **Generation Mode**: `Frames` (`crop_free Frames`) vs `Ingredients` (`chrome_extension Ingredients`)
- **Batches**: `x1`, `x2`, `x3`, `x4`

To select an option:
```javascript
const toggle = await page.$(`.cdk-overlay-pane mat-button-toggle:has-text('${opt}') button`);
if (toggle) await toggle.click();
```

### Rule 4: Keyframe Uploading in 'Frames' Mode
1. Click the `Start` or `End` chip (`button.empty-chip:has-text('Start')`).
2. Concurrently wait for the file chooser and click `button:has-text('Upload media')`:
   ```javascript
   const [fileChooser] = await Promise.all([
     page.waitForEvent("filechooser"),
     uploadBtn.click()
   ]);
   await fileChooser.setFiles(filePath);
   ```
3. Wait ~2500ms for client-side processing, then click `.asset-item` (the first element represents the newest upload).
4. **Confirm Asset Selection**: Click `button.detail-add-to-prompt-btn` (`.cdk-overlay-pane button:has-text('Add to prompt')`) to commit the chip to the prompt bar.
5. Dismiss the picker overlay with `await page.keyboard.press("Escape")`.

### Rule 4: ProseMirror Prompt Injection
The prompt input is rendered via ProseMirror (`.ProseMirror`). Directly setting `.value` or `innerText` will bypass the internal state tree.
- **Use native keyboard simulation**:
  ```javascript
  const editor = await page.$(".ProseMirror");
  await editor.click();
  await page.keyboard.press("Control+A");
  await page.keyboard.press("Backspace");
  await page.keyboard.type(promptText, { delay: 5 });
  ```

### Rule 5: Lazy Video Mounting & Cloud CDN Extraction
Google Flow utilizes Angular virtual scrolling (`cdk-virtual-scroll-viewport`). Video tiles (`flow-video-tile`) lazy-mount `<video>` elements.
1. Hovering over a tile mounts its child `<video>` tag:
   ```javascript
   const tiles = await page.$$("flow-video-tile");
   for (const tile of tiles) {
     await tile.hover();
     await page.waitForTimeout(100);
   }
   ```
2. Query `<video>` tags for their CDN `src` or `currentSrc`:
   ```text
   https://flow-content.google/video/<UUID>?Expires=<EXP>&KeyName=labs-flow-prod-cdn-key&Signature=<SIG>
   ```
3. Download directly via `curl`:
   ```bash
   curl -s -L -o "output.mp4" "<SIGNED_CDN_URL>"
   ```
   *No cookies or authentication headers are needed for signed Cloud CDN URLs.*

---

## 3. Copy-Pasteable Standalone Automation Script

Below is a complete, copy-pasteable Node.js script for automating a full scene generation workflow:

```javascript
const { chromium } = require(
  process.env.PLAYWRIGHT_PATH ||
  "/home/zahedrastgar/.nvm/versions/node/v24.18.1/lib/node_modules/playwright"
);
const { execSync } = require("child_process");

async function runFlowScene() {
  const browser = await chromium.connectOverCDP("http://127.0.0.1:9222");
  const context = browser.contexts()[0];
  const page = context.pages().find(p => p.url().includes("flow.google.com"));

  if (!page) {
    console.error("Google Flow tab not found in Chrome!");
    process.exit(1);
  }

  console.log("Connected to Google Flow:", page.url());

  const startImagePath = "/path/to/scene_start.png";
  const endImagePath = "/path/to/scene_end.png";
  const prompt = "High contrast motion graphic: camera zooms smoothly into target.";
  const outputVideo = "/path/to/output_scene.mp4";

  // Dismiss any existing overlays
  await page.keyboard.press("Escape");
  await page.waitForTimeout(400);

  // 1. Upload Start Frame
  const startBtn = await page.$("button:has-text('Start')");
  if (startBtn) {
    await startBtn.click();
    await page.waitForTimeout(500);

    const uploadBtn = await page.$("button:has-text('Upload media')");
    if (uploadBtn) {
      const [fileChooser] = await Promise.all([
        page.waitForEvent("filechooser"),
        uploadBtn.click()
      ]);
      await fileChooser.setFiles(startImagePath);
      await page.waitForTimeout(2500);

      const assetItem = await page.$(".asset-item");
      if (assetItem) await assetItem.click();
    }
    await page.keyboard.press("Escape");
    await page.waitForTimeout(500);
  }

  // 2. Upload End Frame
  const endBtn = await page.$("button:has-text('End')");
  if (endBtn) {
    await endBtn.click();
    await page.waitForTimeout(500);

    const uploadBtn = await page.$("button:has-text('Upload media')");
    if (uploadBtn) {
      const [fileChooser] = await Promise.all([
        page.waitForEvent("filechooser"),
        uploadBtn.click()
      ]);
      await fileChooser.setFiles(endImagePath);
      await page.waitForTimeout(2500);

      const assetItem = await page.$(".asset-item");
      if (assetItem) await assetItem.click();
    }
    await page.keyboard.press("Escape");
    await page.waitForTimeout(500);
  }

  // 3. Inject Prompt
  const editor = await page.$(".ProseMirror");
  if (editor) {
    await editor.click();
    await page.keyboard.press("Control+A");
    await page.keyboard.press("Backspace");
    await page.keyboard.type(prompt, { delay: 5 });
  }

  // 4. Capture baseline videos
  const baseline = await page.evaluate(() =>
    Array.from(document.querySelectorAll("video")).map(v => v.src || v.currentSrc)
  );

  // 5. Trigger Generation
  const generateBtn = await page.$("button.generate-icon-button, button[aria-label='Start generation']");
  if (!generateBtn) throw new Error("Generate button missing");

  console.log("Triggering generation...");
  await generateBtn.click();

  // 6. Poll for completion
  console.log("Waiting for video completion...");
  let newVideoUrl = null;
  for (let i = 0; i < 40; i++) {
    await page.waitForTimeout(5000);

    // Hover video tiles to trigger lazy mounting
    const tiles = await page.$$("flow-video-tile");
    if (tiles[0]) await tiles[0].hover();

    const currentVideos = await page.evaluate(() =>
      Array.from(document.querySelectorAll("video")).map(v => v.src || v.currentSrc)
    );

    const fresh = currentVideos.filter(url => url && !baseline.includes(url));
    if (fresh.length > 0) {
      newVideoUrl = fresh[0];
      break;
    }
  }

  if (newVideoUrl) {
    console.log("Video ready! Downloading via curl:", newVideoUrl);
    execSync(`curl -s -L -o "${outputVideo}" "${newVideoUrl}"`);
    console.log("Saved to:", outputVideo);
  } else {
    console.error("Timed out waiting for generation.");
  }

  await browser.close();
}

runFlowScene().catch(console.error);
```

---

## 4. Failure Modes & Diagnostic Fixes

| Failure Symptom | Underlying Cause | Verified Remediation |
|---|---|---|
| `Element click intercepted: <div class="cdk-overlay-backdrop">` | An Angular Material backdrop is blocking pointer events | Call `await page.keyboard.press("Escape")` followed by `await page.waitForTimeout(300)` before clicking target element. |
| `button.generate-icon-button has mat-mdc-button-disabled` | Missing Start/End frame or prompt text is empty | Ensure both frames have been selected from the asset popover and `.ProseMirror` contains prompt text. |
| `video` elements not found in DOM | Angular CDK virtual scroll hasn't mounted the video tile | Call `await tile.hover()` on `flow-video-tile` elements to trigger component mounting and source resolution. |
| Playwright cannot connect to `127.0.0.1:9222` | Chrome CDP process is not running or crashed | Run `scripts/launch_chrome.sh` to restart Chrome with remote debugging on port 9222. |
| `SyntaxError: ':has-text()' is not a valid selector` | Playwright pseudo-selectors used inside `page.evaluate()` | Use standard DOM methods (`querySelectorAll` + `.find()`) inside `page.evaluate()`; reserve `:has-text()` for Playwright `page.$()` calls. |
| Google authentication loop or cookie rotation | Ephemeral browser profile or bot detection triggered | Ensure Chrome is launched with `--user-data-dir` pointing to a persistent directory (e.g. `~/.config/google-chrome-flow`) and NO `--enable-automation` flag. |

---

## 5. References

- Model matrix and generation settings specification: `references/models-and-settings.md`
- Detailed DOM selectors and element hierarchy: `references/selectors.md`
- Controller implementation: `scripts/flow_controller.js`
- Chrome launcher script: `scripts/launch_chrome.sh`
