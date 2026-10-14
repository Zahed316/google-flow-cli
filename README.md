# Google Flow CLI (`google-flow-cli`)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen.svg)](https://nodejs.org/)
[![Playwright Supported](https://img.shields.io/badge/playwright-dynamic%20discovery-orange.svg)](https://playwright.dev/)
[![Google Flow](https://img.shields.io/badge/platform-flow.google.com-4285F4.svg)](https://flow.google.com)

A universal, declarative Command-Line Interface (CLI) and programmatic Node.js SDK for **Google Flow** (`flow.google.com`). Automates AI video generation (DeepMind Veo 3.1 & Omni 1.1 Flash) and static image keyframing (Nano Banana 2.1 / Pro / Lite) via persistent Chrome DevTools Protocol (CDP).

Designed for automated video pipelines, motion graphics workflows, and AI coding agents (Claude Code, Codex, Cursor).

---

## 📑 Table of Contents

- [The Problem & Architecture](#-the-problem--architecture)
- [Key Features](#-key-features)
- [Prerequisites & Quick Start](#-prerequisites--quick-start)
- [CLI Command Reference](#-cli-command-reference)
- [AI Models & Media Settings](#-ai-models--media-settings)
- [Declarative Pipelines (`flow.json`)](#-declarative-pipelines-flowjson)
- [Programmatic Node.js SDK](#-programmatic-nodejs-sdk)
- [Maintenance & Future Updates Guide](#-maintenance--future-updates-guide)
- [Security & Credentials](#-security--credentials)
- [Claude Code Skill Integration](#-claude-code-skill-integration)
- [License](#-license)

---

## 💡 The Problem & Architecture

Standard browser automation frameworks (`puppeteer.launch()`, `chromium.launch()`) inject automation flags such as `--enable-automation` and `--disable-blink-features=AutomationControlled`. Google Accounts immediately flags these sessions with:

> *"This browser or app may not be secure. Learn more. Try using a different browser."*

`google-flow-cli` solves this by decoupling browser lifecycle management from automation:

```
+-------------------------------------------------------------------------+
| Host System (Linux / macOS / Windows)                                   |
|                                                                         |
|   1. Launch Real Chrome (Zero automation flags)                         |
|      google-chrome --remote-debugging-port=9222                          |
|                    --user-data-dir=~/.config/google-chrome-flow         |
|                                                                         |
|   2. Playwright CDP Bridge (Non-intrusive attachment)                   |
|      chromium.connectOverCDP('http://127.0.0.1:9222')                   |
|                                                                         |
|   3. Google Flow (flow.google.com) DOM Controller                       |
|      ├── Angular CDK Overlay & Backdrop management (Escape dismissal)   |
|      ├── Model Selector Dropdown: Omni 1.1 Flash, Veo 3.1, Nano Banana  |
|      ├── Media Toggle: Video (720p/360p, 4s-10s) vs Image (1:1, 9:16)   |
|      ├── ProseMirror Keyboard Event Injection                           |
|      └── Virtual-Scroll Viewport Hover & Lazy-Tile Mounting             |
|                                                                         |
|   4. Direct Cloud CDN Extraction & Download                             |
|      └── Signed URL: flow-content.google/video/... -> curl download     |
+-------------------------------------------------------------------------+
```

### Architectural Advantages:
1. **Indefinite Google Authentication**: You log in to Google Flow once. Your genuine authentication cookies persist in `~/.config/google-chrome-flow`.
2. **Zero Bot Detection**: Native Chrome binary with genuine canvas fingerprints, WebGL contexts, and user profiles.
3. **Signed Cloud CDN Extraction**: Generated videos are served from signed Google Cloud CDN endpoints. The CLI retrieves these URLs and downloads them directly via `curl` with resume and integrity checks, bypassing browser download dialogs entirely.

---

## ⚡ Key Features

- **Universal CLI Interface**: Inspired by `onflow/flow-cli` with clean noun-verb command hierarchy (`flow config`, `flow scene`, `flow run`, `flow doctor`).
- **Dynamic Playwright Discovery**: Zero hardcoded paths. Scans local `node_modules`, global npm (`npm root -g`), NVM version directories, and system paths.
- **Model Family Switching**: Complete programmatic control over `Omni 1.1 Flash`, `Veo 3.1 - Fast`, `Veo 3.1 - Lite`, `Veo 3.1 - Quality`, `Nano Banana 2.1`, `Nano Banana Pro`, and `Nano Banana 2 Lite`.
- **Declarative `flow.json` Specification**: Upward configuration discovery with full JSON schema validation (`schemas/flow.schema.json`).
- **Chained Keyframe Support**: Direct scene chaining where Scene N's End frame seamlessly becomes Scene N+1's Start frame.
- **Machine Composition Ready**: Pure JSON output mode (`--json`) for pipelining with `jq`, Python, or shell scripts.

---

## 🚀 Prerequisites & Quick Start

### 1. Installation

Install globally via npm:

```bash
npm install -g google-flow-cli
```

Or install locally in your project:

```bash
npm install --save-dev google-flow-cli
```

*Note: Playwright is dynamically resolved. If you don't have Playwright installed on your machine yet, install it once: `npm install -g playwright`.*

### 2. Launch Native Chrome with Remote Debugging

Launch Google Chrome with a persistent user data profile:

```bash
flow launch
```

*(Alternatively, use the included shell launcher: `./scripts/launch_chrome.sh`)*

Log in to your Google Account on `flow.google.com`. This is a one-time operation—your session will remain authenticated.

### 3. Run Environment Diagnostics

Verify that Chrome CDP, Playwright, and authentication are operational:

```bash
flow doctor
```

Example healthy output:
```text
=== Google Flow Doctor Diagnostics ===
Node.js Version:      v24.18.1
Operating System:    linux
Playwright:          OK (Discovered)
Chrome Binary:       /usr/bin/google-chrome
CDP Port 9222:       OPEN & ACCEPTING CONNECTIONS
Google Auth Status:  AUTHENTICATED & READY
Active URL:          https://flow.google.com/project/547683bf-5c5e-4ad3-8943-d2df0a4575c5
Active Project ID:   547683bf-5c5e-4ad3-8943-d2df0a4575c5
```

### 4. Initialize a Project

Scaffold a `flow.json` in your current working directory:

```bash
flow init
```

### 5. Generate a Video Scene

```bash
flow scene \
  -s "assets/frames/scene_01_start.png" \
  -e "assets/frames/scene_01_end.png" \
  -p "Minimalist Swiss motion graphic: camera zooms smoothly into target." \
  -M "Veo 3.1 - Fast" \
  --generate \
  -w \
  -t 300 \
  -o "assets/videos/scene_01.mp4"
```

---

## 📖 CLI Command Reference

### Commands

| Command | Subcommand | Description |
|---|---|---|
| `flow init` | `[dir]` | Scaffold a new `flow.json` in target directory |
| `flow doctor` | - | Diagnose Playwright, Chrome binary, CDP port, and auth status |
| `flow status` | - | Inspect active project URL, settings pill, frame chips, and prompt |
| `flow config` | - | Update generation settings (media type, model, aspect, duration, etc.) |
| `flow scene` | - | Configure keyframes, prompt, and optionally trigger scene generation |
| `flow run` | - | Execute declarative scene pipeline from `flow.json` |
| `flow videos` | `list` | List all videos in the active project with signed CDN URLs |
| `flow videos` | `download-latest` | Download the most recently generated video in the project |
| `flow launch` | - | Start native Google Chrome with CDP port 9222 enabled |

### Options & Flags

| Flag | Long Flag | Description | Default |
|---|---|---|---|
| - | `--media <type>` | Media generation type: `video` or `image` | `video` |
| `-M` | `--model <name>` | AI model family: `Omni 1.1 Flash`, `Veo 3.1 - Fast`, `Nano Banana Pro`, etc. | `Omni 1.1 Flash` |
| `-s` | `--start <path>` | Path to Start keyframe image (for Frames mode) | `null` |
| `-e` | `--end <path>` | Path to End keyframe image (for Frames mode) | `null` |
| `-p` | `--prompt <text>`| Text prompt injected into ProseMirror editor | `""` |
| `-o` | `--output <path>`| Output file path for generated MP4 video or PNG image | `./assets/videos/...` |
| `-r` | `--resolution <r>`| Video resolution: `720p` or `360p` (video only) | `720p` |
| `-d` | `--duration <d>` | Clip duration: `4s`, `6s`, `8s`, or `10s` (video only) | `8s` |
| `-a` | `--aspect <ratio>`| Aspect ratio: `9:16`, `16:9` (video/image); `1:1`, `4:3`, `3:4` (image only) | `9:16` |
| `-m` | `--mode <mode>` | Generation mode: `Frames` or `Ingredients` | `Frames` |
| `-B` | `--batch <x>` | Number of concurrent variations: `x1`, `x2`, `x3`, `x4` | `x1` |
| `-w` | `--wait` | Wait for generation to complete | `true` (for run) |
| `-t` | `--timeout <sec>`| Generation timeout in seconds | `300` |
| - | `--dry-run` | Preview and validate execution plan without spending credits | `false` |
| - | `--scene <name>` | Execute only a specific scene by name from `flow.json` | `all` |
| `-f` | `--force` | Force overwrite existing files | `false` |
| `-j` | `--json` | Output machine-readable JSON | `false` |
| `-h` | `--help` | Show command usage and flags | - |

---

## 🤖 AI Models & Media Settings

Google Flow features two distinct media generation pipelines with specialized model families:

### Video Models (`--media video`)

| Exact Model Name | CLI Aliases | Best For | Default Audio |
|---|---|---|---|
| **`Omni 1.1 Flash`** | `omni`, `flash` | Multimodal scenes with synchronized speech, sound effects, and ambient audio | Yes |
| **`Veo 3.1 - Fast`** | `veo-fast`, `fast`, `veo` | High-speed iterations and draft animation sequences | No |
| **`Veo 3.1 - Lite`** | `veo-lite`, `lite` | Resource-efficient generation with minimal quota usage | No |
| **`Veo 3.1 - Quality`**| `veo-quality`, `quality` | Maximum photorealism, fine material physics, and prompt fidelity | No |

### Image Models (`--media image`)

| Exact Model Name | CLI Aliases | Best For | Aspect Ratios |
|---|---|---|---|
| **`Nano Banana 2.1`** | `banana-2.1`, `banana`, `imagen` | Balanced keyframe generation and concept exploration | `9:16`, `16:9`, `1:1`, `4:3`, `3:4` |
| **`Nano Banana Pro`** | `banana-pro`, `pro-image` | High prompt fidelity, sharp typography, and final assets | `9:16`, `16:9`, `1:1`, `4:3`, `3:4` |
| **`Nano Banana 2 Lite`**| `banana-lite`, `fast-image` | Ultra-fast concept drafts and rapid experimentation | `9:16`, `16:9`, `1:1`, `4:3`, `3:4` |

*For complete details, decision trees, and parameter rules, consult [`references/models-and-settings.md`](references/models-and-settings.md).*

---

## 📁 Declarative Pipelines (`flow.json`)

`flow.json` enables fully automated, reproducible video and image generation pipelines.

```json
{
  "$schema": "https://flow.google/schema/v1.json",
  "version": "1.0.0",
  "name": "brand-campaign-vertical",
  "project": {
    "id": "547683bf-5c5e-4ad3-8943-d2df0a4575c5",
    "url": "https://flow.google.com/project/547683bf-5c5e-4ad3-8943-d2df0a4575c5"
  },
  "defaults": {
    "mediaType": "video",
    "model": "Veo 3.1 - Fast",
    "resolution": "720p",
    "duration": "8s",
    "aspect": "9:16",
    "mode": "Frames",
    "batches": "x1",
    "timeout": 300
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
      "start": "assets/frames/s01_end.png",
      "end": "assets/frames/s02_end.png",
      "prompt": "Photorealistic close-up with volumetric lighting and subtle ambient motion.",
      "output": "assets/videos/s02.mp4"
    }
  ]
}
```

### Chained Keyframe Interpolation
Notice how `scene_02_feature.start` uses `assets/frames/s01_end.png`. This pattern guarantees continuous visual cohesion across multiple video cuts without jarring transition jumps.

---

## 💻 Programmatic Node.js SDK

You can import `FlowClient` directly in Node.js applications:

```javascript
const { FlowClient } = require("google-flow-cli");

async function runPipeline() {
  const client = new FlowClient({
    port: 9222,
    autoLaunch: true
  });

  // 1. Connect and verify status
  const status = await client.status();
  console.log("Current Project ID:", status.projectId);

  // 2. Configure video parameters
  await client.configure({
    mediaType: "video",
    model: "Veo 3.1 - Fast",
    resolution: "720p",
    duration: "8s",
    aspect: "9:16",
    mode: "Frames"
  });

  // 3. Execute scene generation
  const result = await client.runScene({
    start: "assets/frames/scene_01_start.png",
    end: "assets/frames/scene_01_end.png",
    prompt: "Cinematic Swiss motion graphic: golden turkey transforms into dark obsidian.",
    generate: true,
    wait: true,
    timeout: 300,
    output: "assets/videos/scene_01.mp4"
  });

  console.log("Downloaded generated video:", result.download.path);
  await client.disconnect();
}

runPipeline().catch(console.error);
```

---

## 🛠️ Maintenance & Future Updates Guide

Google frequently iterates on Labs user interfaces. If Google Flow updates its DOM structure or styling in the future, follow this maintenance checklist:

### 1. Angular CDK Overlay & Backdrop Rules
- **Pointer Interception**: When Google Flow opens modal dialogs (model menus, asset pickers, settings overlays), Angular CDK attaches `.cdk-overlay-backdrop`.
- **Always Dismiss Overlays**: Use `await page.keyboard.press("Escape")` with a short `waitForTimeout(250)` before and after modal clicks.
- **Secondary Dropdown Menu**: Clicking `button[aria-label="Select model family"]` opens a secondary `.cdk-overlay-pane`. If you click a menu item or need to abort, press `Escape` to close the dropdown before interacting with parent controls.

### 2. Updating Selectors in `src/dom.js`
The primary DOM anchors are documented in [`references/selectors.md`](references/selectors.md). If Google updates element classes:
- **Settings Trigger**: `button[aria-label="Settings trigger"], button.settings-trigger-button`
- **Model Selector Dropdown**: `button[aria-label="Select model family"], button.mat-mdc-menu-trigger`
- **ProseMirror Editor**: `.ProseMirror, [contenteditable="true"]`
- **Start/End Keyframe Chips**: `button.empty-chip:has-text('Start')`, `button.empty-chip:has-text('End')`
- **Video Tiles & Virtual Scroll**: `flow-video-tile, cdk-virtual-scroll-viewport flow-video-tile`

### 3. Adding New Model Families
When Google adds new models to Google Flow:
1. Run `flow status` and inspect the options in the live model menu.
2. Add the new model name and its normalized aliases to `normalizeModelName()` in `src/dom.js`.
3. Add the model enum to `schemas/flow.schema.json`.
4. Update the catalog table in `references/models-and-settings.md`.

---

## 🔒 Security & Credentials

### Strict Zero-Credential Policy
- **No API Keys or Secrets in Git**: `google-flow-cli` stores zero credentials. All authentication resides in your local Chrome user profile directory (`~/.config/google-chrome-flow`).
- **Comprehensive `.gitignore`**: Environment variables (`.env*`), private keys (`*.key`, `*.pem`), user profiles (`.config/`), and generated binary media are strictly excluded.
- **Pre-Commit Secret Scanning**: This repository is integrated with **Crenox Pro** (`crenox`) to verify staged commits against credential leakage.

To install pre-commit security hooks:
```bash
crenox hook install
```

To run a manual secret scan before publishing:
```bash
crenox scan
```

---

## 🧠 Claude Code Skill Integration

This repository includes a native Claude Code skill definition in `skills/google-flow/SKILL.md`.

To install it into your local Claude Code skills:

```bash
mkdir -p ~/.claude/skills/google-flow
cp -r skills/google-flow/* ~/.claude/skills/google-flow/
```

Claude Code will then automatically discover the `/google-flow` skill and execute autonomous generation pipelines.

---

## 📄 License

MIT License. Copyright (c) 2026 Zahed Rastgar. See [LICENSE](LICENSE) for full details.
