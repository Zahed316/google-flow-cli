# AGENTS.md - Operational Guide for AI Coding Agents

Operational protocol for autonomous AI coding agents (Claude Code, OpenAI Codex, Cursor Agent, Antigravity, OpenCode) interacting with `google-flow-cli`.

---

## 1. System Architecture & Operating Principles

Google Flow (`flow.google.com`) enforces strict anti-bot protections. Traditional headless browser automation (`puppeteer.launch()`, `chromium.launch()`) injects flags (`--enable-automation`, `navigator.webdriver = true`) that immediately trigger Google Account authentication rejections.

`google-flow-cli` decouples the browser runtime from automation:
1. **Host Chrome**: A genuine, native Chrome instance runs with remote debugging enabled on port `9222` (`--remote-debugging-port=9222`) and a persistent profile (`~/.config/google-chrome-flow`).
2. **CDP Bridge**: Playwright attaches non-intrusively over Chrome DevTools Protocol (`http://127.0.0.1:9222`).
3. **Zero Bot Signature**: Real user cookies, real canvas rendering, and zero automation flags.

As an AI agent, you must interact with this system via:
- **CLI Commands with `--json`** (`flow <command> --json`)
- **Stdio MCP Server** (`flow-mcp` using tools `flow_session_status`, `flow_generate_video`, etc.)
- **Programmatic SDK** (`const { FlowClient } = require('google-flow-cli')`)

---

## 2. Agent Execution Lifecycle & State Machine

Always follow this 5-stage state machine:

```
[1. PRE-FLIGHT DIAGNOSTICS] ──> [2. CANVAS INSPECTION] ──> [3. CONFIGURATION & FRAMES]
         │                                                            │
         ▼ (If CDP/Auth down)                                         ▼
   [Remediate / Prompt]                                     [4. TRIGGER GENERATION]
                                                                      │
                                                                      ▼
                                                            [5. VERIFY & RETRIEVE]
```

### Stage 1: Pre-Flight Diagnostics
**Mandatory step before any mutation or generation.**
Run:
```bash
flow doctor --json
```
or call MCP tool `flow_session_status`.

**Inspection Criteria:**
- `cdpOpen: true`: Chrome is running and listening on port 9222. If `false`, launch Chrome using `flow launch` or `google-chrome --remote-debugging-port=9222 --user-data-dir=~/.config/google-chrome-flow https://flow.google.com &`.
- `playwright: true`: Playwright is available in the environment.
- `googleAuthenticated: true`: Active tab has valid Google login session. If `false`, notify the user that manual login is required in the Chrome window.
- `projectId`: Check if an active project canvas is already open.

### Stage 2: Canvas State Inspection
Inspect current canvas state before acting:
```bash
flow status --json
```
or call MCP tool `flow_session_status`.

**Parse the JSON response:**
- `isDashboard: true`: Browser is currently at `flow.google.com/` (project list). You must switch to a project (`flow project switch <id>`) or create one (`flow project create <title>`) before configuring scenes.
- `canGenerate`: Indicates whether prompt and required keyframe chips allow generation.
- `hasSpinner`: If `true`, a generation is **already in progress**. Do not submit a new generation until the active spinner completes.
- `startFrame.set` / `endFrame.set`: Whether Start and End keyframe chips currently hold images.
- `mediaType`: Shows whether active configuration is `video` or `image`.

---

## 3. Safe Video & Image Generation

### Model Family Matrix

| Task | Recommended Model | Alternative Models | Valid Modes | Valid Resolutions |
| :--- | :--- | :--- | :--- | :--- |
| **High-Speed Video** | `Veo 3.1 - Fast` | `Veo 3.1 - Lite`, `Omni 1.1 Flash` | Frames, Ingredients | 720p, 360p |
| **Cinematic Video** | `Veo 3.1 - Quality` | `Veo 3.1 - Fast` | Frames, Ingredients | 720p, 360p |
| **Static Keyframes** | `Nano Banana Pro` | `Nano Banana 2.1`, `Nano Banana 2 Lite` | Direct Prompt | 9:16, 16:9, 1:1, 4:3, 3:4 |

### Angular CDK Overlay & Backdrop Management
Google Flow is built with Angular Material and Angular CDK. Dropdowns, model menus, and media selectors render inside `.cdk-overlay-container`.

**Rules for Agents:**
1. Opening settings or menus creates a `.cdk-overlay-backdrop`. If left open, this backdrop intercepts all click events with `pointer-events: auto`, blocking interaction with the main canvas.
2. The CLI and SDK automatically issue `Escape` key events (`dom.dismissOverlays(page)`) after applying settings or keyframes.
3. If scripting raw Playwright calls, **always dismiss overlays** before clicking buttons on the canvas.

### Virtual-Scroll & Lazy-Tile Mounting
Google Flow displays generated assets in a `cdk-virtual-scroll-viewport`. To save memory, video and image DOM elements inside unrendered tiles remain unmounted until hovered or scrolled into view.

**Rules for Agents:**
- When retrieving video URLs (`flow videos list --json` or `FlowClient.getVideos()`), the system automatically hovers the top video tiles to trigger lazy mounting.
- Signed Google Cloud CDN URLs (`flow-content.google/video/...`) are extracted directly and can be downloaded via `curl` with resume capability.

### Generation Timeout Management
- Veo 3.1 and Omni 1.1 Flash generations take between 45 and 180 seconds depending on server load.
- **Never set a timeout below 120 seconds**. The default CLI timeout is `300` seconds (`-t 300`).
- Always pass `--wait` (`-w`) or `wait: true` to poll until the generation finishes.

---

## 4. Credit & Quota Protection

1. **Batch Multiplier Awareness**:
   - Google Flow generates 2 video variants per submission by default (`x1` batch multiplier).
   - Setting `-B x2` generates 4 variants, consuming double the quota.
   - For automated agent workflows, always default to `x1` unless explicitly requested.

2. **Always Dry-Run Pipelines First**:
   - Before executing a multi-scene `flow.json` pipeline, run:
     ```bash
     flow run --dry-run --json
     ```
   - Validate scene order, keyframe asset existence on disk, model compatibility, and prompt text before consuming generation quota.

3. **Rate Limiting & Polling**:
   - Polling loops should query state every 5 seconds.
   - Do not issue concurrent generation requests on the same project canvas.

---

## 5. Declarative Pipelines (`flow.json`) & Chained Keyframes

### The Chained Keyframe Convention
To produce coherent continuous video narratives, agents must enforce chained keyframes:
- **Scene 1**: Starts at `frame_01_start.png`, ends at `frame_01_end.png`.
- **Scene 2**: Starts at `frame_01_end.png` (or the last extracted frame of Scene 1), ends at `frame_02_end.png`.
- **Scene 3**: Starts at `frame_02_end.png`, ends at `frame_03_end.png`.

```
[Start Frame A] ──Scene 1──> [End Frame B]
                                  │ (Chain)
                             [Start Frame B] ──Scene 2──> [End Frame C]
                                                               │ (Chain)
                                                          [Start Frame C] ──Scene 3──> [End Frame D]
```

### Pipeline Schema Specification
A valid `flow.json` must adhere to `schemas/flow.schema.json`:

```json
{
  "name": "cinematic-narrative",
  "project": "547683bf-5c5e-4ad3-8943-d2df0a4575c5",
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
      "name": "scene_01",
      "start": "assets/frames/scene_01_start.png",
      "end": "assets/frames/scene_01_end.png",
      "prompt": "Cinematic camera tilt up revealing golden architecture under dark overcast sky.",
      "output": "assets/videos/scene_01.mp4"
    },
    {
      "name": "scene_02",
      "start": "assets/frames/scene_01_end.png",
      "end": "assets/frames/scene_02_end.png",
      "prompt": "Camera pushes forward through golden archway into dark obsidian courtyard.",
      "output": "assets/videos/scene_02.mp4"
    }
  ]
}
```

---

## 6. Model Context Protocol (MCP) Integration

`google-flow-cli` includes a native stdio MCP server for direct tool-use by LLMs:

```bash
# Add to Claude Code
claude mcp add google-flow npx google-flow-cli flow-mcp

# Add to Cursor (~/.cursor/mcp.json)
{
  "mcpServers": {
    "google-flow": {
      "command": "npx",
      "args": ["google-flow-cli", "flow-mcp"]
    }
  }
}
```

### Tool Mapping Reference

| MCP Tool | CLI Equivalent | Description |
| :--- | :--- | :--- |
| `flow_session_status` | `flow doctor -j && flow status -j` | Complete diagnostics, auth check, active project canvas status |
| `flow_generate_video` | `flow scene [flags] --generate -w` | Video generation with Veo 3.1 / Omni 1.1 Flash |
| `flow_generate_image` | `flow scene --media image [flags] --generate -w` | Static keyframe generation with Nano Banana |
| `flow_list_projects` | `flow project list --json` | List user projects with IDs and URLs |
| `flow_switch_project` | `flow project switch <id> --json` | Switch active canvas to project ID |
| `flow_run_pipeline` | `flow run [--dry-run] --json` | Execute or dry-run declarative pipeline |

---

## 7. Failure Mode Remediation Playbook

| Error Condition | Root Cause | Immediate Agent Action |
| :--- | :--- | :--- |
| `ECONNREFUSED 127.0.0.1:9222` | Chrome is not running or CDP port closed | Run `flow launch` or start Chrome with `--remote-debugging-port=9222`. |
| `googleAuthenticated: false` | User session expired or signed out | Notify user: *"Please open the Chrome window on port 9222 and sign in to Google Flow."* |
| `Cannot generate: button is disabled` | Prompt missing, or invalid frames | Run `flow status --json`. Verify `promptText` is not empty and keyframe chips match mode requirements. |
| `Timed out after 300s waiting for generation` | Heavy Google GPU queue load | Check if video completed in UI (`flow videos list --json`). Download manually using `flow videos download-latest`. |
| `Settings trigger button not found` | Canvas is on Dashboard, not in Project | Run `flow project list --json`, then `flow project switch <id>`. |
| `Asset index out of range` | Keyframe upload failed or asset library empty | Ensure keyframe image paths are valid absolute paths on the local filesystem. |
