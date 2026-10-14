# Google Flow DOM Selectors & Components Reference

This document maps the Angular Material (MDC / Angular CDK) DOM elements, components, and classes used across Google Flow (`flow.google.com`).

---

## 1. Top-Level Shell & Navigation

| Component / Selector | Purpose | Notes |
|---|---|---|
| `aisandbox-root` | Application root element | Angular root |
| `flow-project-shell` | Main workspace container | Houses navigation, canvas, and toolbar |
| `button[aria-label="Home"]` | Return to projects list | Icon `home` |
| `button[aria-label="More options for the project"]` | Project metadata & actions | Icon `more_vert` |
| `.settings-trigger-button` / `button[aria-label="Settings trigger"]` | Generation settings pill | Shows e.g. `Video · 720p · 8s \| crop_9_16 \| x1` |

---

## 2. Generation Settings Overlay

When clicking `button[aria-label="Settings trigger"]`, an Angular CDK overlay (`.cdk-overlay-pane`) opens containing `mat-button-toggle-group` toggles.

### Mode & Media Toggles

| Target | Selector |
|---|---|
| **Image Mode** | `.cdk-overlay-pane mat-button-toggle:has-text('Image') button` |
| **Video Mode** | `.cdk-overlay-pane mat-button-toggle:has-text('Video') button` |
| **Frames Mode** | `.cdk-overlay-pane mat-button-toggle:has-text('Frames') button` (`crop_free Frames`) |
| **Ingredients Mode** | `.cdk-overlay-pane mat-button-toggle:has-text('Ingredients') button` |

### Aspect Ratio

| Target | Selector |
|---|---|
| **16:9 Landscape** | `.cdk-overlay-pane mat-button-toggle:has-text('16:9') button` |
| **9:16 Vertical** | `.cdk-overlay-pane mat-button-toggle:has-text('9:16') button` |

### Resolution

| Target | Selector |
|---|---|
| **360p** | `.cdk-overlay-pane mat-button-toggle:has-text('360p') button` |
| **720p** | `.cdk-overlay-pane mat-button-toggle:has-text('720p') button` |

### Duration & Multipliers

| Target | Selector |
|---|---|
| **Durations** | `.cdk-overlay-pane mat-button-toggle:has-text('4s') button`, `6s`, `8s`, `10s` |
| **Batches** | `.cdk-overlay-pane mat-button-toggle:has-text('x1') button`, `x2`, `x3`, `x4` |

*Active state indicator: Parent `mat-button-toggle` element has class `mat-button-toggle-checked`.*

---

## 3. Keyframes & Prompt Input (Frames Mode)

| Action / Element | Selector | Interaction Flow |
|---|---|---|
| **Start Frame Chip** | `button.empty-chip:has-text('Start')` or `button:has-text('Start')` | Click opens asset/upload popover |
| **End Frame Chip** | `button.empty-chip:has-text('End')` or `button:has-text('End')` | Click opens asset/upload popover |
| **Swap Frames** | `button[aria-label="Swap first and last frames"]` | Swaps Start and End frames |
| **Upload Button** | `button:has-text('Upload media')` | Intercept with `page.waitForEvent('filechooser')` |
| **Asset Selection** | `.asset-item` | First `.asset-item` is newest upload |
| **Prompt Editor** | `.ProseMirror`, `div[contenteditable="true"]` | Focus, `Control+A`, `Backspace`, `keyboard.type(prompt)` |
| **Generate Button** | `button.generate-icon-button`, `button[aria-label="Start generation"]` | Disabled if `mat-mdc-button-disabled` present |

---

## 4. Video Tiles & CDN Extraction

Google Flow utilizes Angular CDK virtual scrolling (`cdk-virtual-scroll-viewport.tiles-container`). Video tiles are lazy-rendered.

| Element | Selector | Notes |
|---|---|---|
| **Grid Tile Container** | `flow-grid-tile-container` | Wraps single generation tile |
| **Video Tile** | `flow-video-tile` | Hovering mounts the `<video>` element into the DOM |
| **Video Element** | `flow-video-tile video`, `video` | Contains `src` or `currentSrc` |
| **Tile Menu Button** | `flow-video-tile button[aria-label="More options"]` | Opens context menu (`download`, `reuse`, `favorite`) |

### CDN Signed URL Format
```text
https://flow-content.google/video/<UUID>?Expires=<UNIX_TIMESTAMP>&KeyName=labs-flow-prod-cdn-key&Signature=<HMAC_SIGNATURE>
```
Signed URLs can be downloaded directly using `curl -s -L -o output.mp4 "<URL>"` without requiring Google cookies or session headers.

---

## 5. Overlay Dismissal Pattern

Angular CDK overlays block underlying pointer events via `.cdk-overlay-backdrop`.
To dismiss safely before subsequent interactions:
```javascript
await page.keyboard.press("Escape");
await page.waitForTimeout(300);
```
