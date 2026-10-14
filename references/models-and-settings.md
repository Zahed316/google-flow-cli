# Google Flow Models & Settings Reference for AI Agents

Authoritative specification for AI agents configuring media formats, model families, and generation settings in Google Flow (`flow.google.com`) via `google-flow-cli` or Playwright CDP automation.

---

## 1. Quick Decision Matrix for AI Agents

Use this decision table when choosing media type and model family for an automated task:

| Desired Output / Goal | Media Type | Recommended Model | Duration / Aspect | Notes |
|---|---|---|---|---|
| **Audio-synchronized Video** (Dialogue, SFX, ambient) | `video` | `Omni 1.1 Flash` | 4s, 6s, 8s, 10s / 9:16, 16:9 | Default model. Produces synchronized sound effects and speech. |
| **High-Speed Video Iteration / Draft** | `video` | `Veo 3.1 - Fast` | 4s, 6s, 8s, 10s / 9:16, 16:9 | Lowest latency for video generation. |
| **Resource-Efficient Video** | `video` | `Veo 3.1 - Lite` | 4s, 6s, 8s, 10s / 9:16, 16:9 | Minimal quota consumption. |
| **Maximum Photorealism & Detail Video** | `video` | `Veo 3.1 - Quality` | 4s, 6s, 8s, 10s / 9:16, 16:9 | Maximum prompt fidelity, realistic physics and textures. |
| **Balanced Static Image Generation** | `image` | `Nano Banana 2.1` | 9:16, 16:9, 1:1, 4:3, 3:4 | Flagship image generator. Balanced speed and detail. |
| **High-Precision Image / Keyframe Art** | `image` | `Nano Banana Pro` | 9:16, 16:9, 1:1, 4:3, 3:4 | Highest detail, typography rendering, and prompt adherence. |
| **Rapid Draft Image / Moodboard** | `image` | `Nano Banana 2 Lite` | 9:16, 16:9, 1:1, 4:3, 3:4 | Fastest turnaround for static concept exploration. |

---

## 2. Complete Model Catalog & Aliases

The CLI and SDK support both full menu labels and normalized short aliases:

### Video Models (`mediaType: "video"`)

| Exact Menu Label | Normalized CLI Aliases | Description | Default Audio |
|---|---|---|---|
| `Omni 1.1 Flash` | `omni`, `flash`, `omni-1.1` | Native multimodal generation with synchronized audio/sound effects | Yes |
| `Veo 3.1 - Fast` | `veo-fast`, `fast`, `veo`, `veo-3.1` | DeepMind Veo 3.1 optimized for high generation speed | No |
| `Veo 3.1 - Lite` | `veo-lite`, `lite` | Lightweight Veo 3.1 for rapid previewing | No |
| `Veo 3.1 - Quality` | `veo-quality`, `quality`, `veo-pro` | Maximum photorealism, detailed motion fidelity | No |

### Image Models (`mediaType: "image"`)

| Exact Menu Label | Normalized CLI Aliases | Description | Aspect Ratios |
|---|---|---|---|
| `Nano Banana 2.1` | `banana-2.1`, `banana`, `imagen`, `image-default` | Core Google Labs image generation model | 9:16, 16:9, 1:1, 4:3, 3:4 |
| `Nano Banana Pro` | `banana-pro`, `pro-image`, `imagen-pro` | High-fidelity generation with superior prompt adherence | 9:16, 16:9, 1:1, 4:3, 3:4 |
| `Nano Banana 2 Lite`| `banana-lite`, `fast-image`, `lite-image` | High-speed, lower-compute draft image generator | 9:16, 16:9, 1:1, 4:3, 3:4 |

---

## 3. Parameter Rules & Valid Combinations

| Parameter | Type / Scope | Allowed Values | Compatibility Constraints |
|---|---|---|---|
| `mediaType` | Global / Scene | `"video"`, `"image"` | Default is `"video"`. Changing switches available settings in overlay. |
| `model` | Global / Scene | See catalog above | Must match the active `mediaType`. Video models cannot be selected when `image` is active, and vice versa. |
| `resolution`| Video only | `"720p"`, `"360p"` | **Ignored** when `mediaType: "image"`. Default is `"720p"`. |
| `duration` | Video only | `"4s"`, `"6s"`, `"8s"`, `"10s"` | **Ignored** when `mediaType: "image"`. Default is `"8s"`. |
| `aspect` | Video & Image | `"9:16"`, `"16:9"`, `"1:1"`, `"4:3"`, `"3:4"` | `"1:1"`, `"4:3"`, and `"3:4"` are **Image only**. For Video, use `"9:16"` (Vertical) or `"16:9"` (Landscape). |
| `mode` | Video only | `"Frames"`, `"Ingredients"` | `"Frames"` requires Start and/or End keyframes. `"Ingredients"` accepts arbitrary prompt and assets. |
| `batches` | Video & Image | `"x1"`, `"x2"`, `"x3"`, `"x4"` | Number of generation candidates produced per request. Default is `"x1"`. |
| `timeout` | Execution | `30` to `1200` (seconds) | Maximum wait time for generation polling before timeout. Default is `300`. |

---

## 4. Automation & Selector Mechanics (DOM Rules)

When automating Google Flow through Playwright or CDP directly:

```
[Settings Trigger Button]
    │  Click button[aria-label="Settings trigger"]
    ▼
[.cdk-overlay-pane] (Primary Settings Overlay)
    ├── Media Toggle: mat-button-toggle:has-text('Video') | mat-button-toggle:has-text('Image')
    ├── Mode Toggle: mat-button-toggle:has-text('Frames') | mat-button-toggle:has-text('Ingredients')
    ├── Aspect Toggle: mat-button-toggle:has-text('9:16') | mat-button-toggle:has-text('16:9') | ...
    ├── Resolution Toggle: mat-button-toggle:has-text('720p') | mat-button-toggle:has-text('360p')
    ├── Duration Toggle: mat-button-toggle:has-text('8s') | ...
    ├── Batch Toggle: mat-button-toggle:has-text('x1') | ...
    │
    └── [Model Family Dropdown Trigger]
            │  Click button[aria-label="Select model family"]
            ▼
        [.cdk-overlay-pane] (Secondary Menu Overlay)
            └── button[role="menuitem"]:has-text('<TARGET_MODEL>')
```

### Critical DOM Rules for AI Agents:
1. **Always send `Escape` after selecting a model**: Selecting a model opens a secondary CDK popover (`.cdk-overlay-popover`) that intercepts clicks to the primary settings panel. Always dismiss with `await page.keyboard.press("Escape")`.
2. **Switch Media Type Before Model Selection**: The model menu items update dynamically based on whether `Video` or `Image` is selected. Set `mediaType` first, then call `selectModel()`.
3. **Lazy Virtual-Scroll Mounting**: To read generated videos or images, hover over `.video-tile` or `flow-video-tile` elements so the browser mounts the child `<video>` or `<img>` element into the DOM.

---

## 5. Declarative `flow.json` Examples

### Example A: Vertical Video Pipeline with Veo 3.1 Fast

```json
{
  "$schema": "https://flow.google/schema/v1.json",
  "version": "1.0.0",
  "name": "brand-campaign-vertical",
  "defaults": {
    "mediaType": "video",
    "model": "Veo 3.1 - Fast",
    "resolution": "720p",
    "duration": "8s",
    "aspect": "9:16",
    "mode": "Frames",
    "batches": "x1"
  },
  "scenes": [
    {
      "name": "scene_01_intro",
      "start": "assets/frames/s01_start.png",
      "end": "assets/frames/s01_end.png",
      "prompt": "Minimalist typography animation, camera tracks smoothly from left to right.",
      "output": "assets/videos/s01.mp4"
    },
    {
      "name": "scene_02_feature",
      "model": "Veo 3.1 - Quality",
      "start": "assets/frames/s02_start.png",
      "end": "assets/frames/s02_end.png",
      "prompt": "Photorealistic close-up with volumetric lighting and subtle ambient motion.",
      "output": "assets/videos/s02.mp4"
    }
  ]
}
```

### Example B: Static Keyframe Pipeline with Nano Banana Pro

```json
{
  "$schema": "https://flow.google/schema/v1.json",
  "version": "1.0.0",
  "name": "keyframe-generation-pipeline",
  "defaults": {
    "mediaType": "image",
    "model": "Nano Banana Pro",
    "aspect": "9:16",
    "batches": "x1"
  },
  "scenes": [
    {
      "name": "keyframe_title",
      "prompt": "Modern Swiss graphic poster, bold black typography on pure white background, award-winning composition.",
      "output": "assets/images/keyframe_01.png"
    },
    {
      "name": "keyframe_climax",
      "aspect": "16:9",
      "prompt": "Cinematic wide-angle shot of futuristic architecture at dusk, warm tungsten reflections.",
      "output": "assets/images/keyframe_02.png"
    }
  ]
}
```

---

## 6. CLI Command Reference for AI Execution

### Direct Model Configuration
```bash
# Set video model to Veo 3.1 Fast
flow config --media video -M "Veo 3.1 - Fast" -r 720p -d 8s -a 9:16

# Set video model with alias
flow config --media video -M veo-quality -d 6s

# Set image model to Nano Banana Pro
flow config --media image -M "Nano Banana Pro" -a 1:1

# Set image model with alias
flow config --media image -M banana-lite -a 16:9
```

### Executing Scenes with Explicit Model Overrides
```bash
# Generate video scene using Omni 1.1 Flash (multimodal with audio)
flow scene -s start.png -e end.png -p "Cinematic transformation" \
  --media video -M "Omni 1.1 Flash" -o scene_01.mp4 --generate

# Generate static image keyframe using Nano Banana Pro
flow scene -p "Swiss graphic layout with golden ratio grid" \
  --media image -M "Nano Banana Pro" -a 9:16 -o keyframe_start.png --generate
```
