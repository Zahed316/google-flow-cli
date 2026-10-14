# Contributing to Google Flow CLI

Thank you for your interest in contributing to `google-flow-cli`! This project provides a universal, declarative command-line interface and programmatic Node.js SDK for Google Flow (`flow.google.com`).

Contributions in the form of bug reports, feature requests, new model mappings, DOM selector updates, and pull requests are welcomed.

---

## Architecture Overview

Google Flow CLI automates Google Flow without triggering Google automated-browser security flags by separating browser lifecycle from automation logic:

```
+---------------------------------------------------------------+
| Native Google Chrome (zero automation flags)                  |
| Launched on CDP port 9222 with persistent profile directory   |
+-------------------------------+-------------------------------+
                                |
                    Chrome DevTools Protocol (CDP)
                                |
+-------------------------------v-------------------------------+
| google-flow-cli                                               |
|                                                               |
|  bin/flow.js       Executable CLI entrypoint                  |
|  src/cli.js        Command router and flag parser             |
|  src/client.js     High-level GoogleFlowClient orchestration  |
|  src/dom.js        Playwright CDP bridge & Angular CDK DOM    |
|  src/config.js     Declarative flow.json parser & scaffolder  |
|  schemas/          JSON Schema Draft-07 specification         |
|  templates/        Starter project configurations             |
+---------------------------------------------------------------+
```

### Key Architectural Concepts

1. **CDP Connection (`src/dom.js`)**:
   Connects to an existing Chrome instance on port 9222 via `chromium.connectOverCDP()`. This keeps your Google session authenticated forever without storing credentials.
2. **Angular CDK & MDC Selectors (`src/dom.js`, `references/selectors.md`)**:
   Google Flow is built with Angular Material and Angular CDK. Overlay panels (`.cdk-overlay-pane`) and backdrops (`.cdk-overlay-backdrop`) must be dismissed with keyboard `Escape` events after menu selections to avoid pointer interception.
3. **Model Selection**:
   Models are grouped in Google Flow's UI under video models (Veo 3.1, Omni 1.1) and image models (Nano Banana). Model names are mapped and normalized via `normalizeModelName()` in `src/dom.js`.
4. **Declarative Pipelines (`src/config.js`, `schemas/flow.schema.json`)**:
   Pipelines are defined in `flow.json` and validated against `schemas/flow.schema.json`.

---

## Local Development Setup

### 1. Prerequisites

- Node.js >= 18.0.0
- Google Chrome installed (`google-chrome`, `google-chrome-stable`, or `chromium`)
- Playwright (installed globally via `npm i -g playwright` or locally)

### 2. Clone and Inspect

```bash
git clone https://github.com/Zahed316/google-flow-cli.git
cd google-flow-cli
npm pack --dry-run
```

Because `google-flow-cli` is dependency-free at runtime, no `npm install` step is required unless you are installing optional developer tooling.

### 3. Launching Test Chrome Instance

Launch Chrome with remote debugging enabled on port 9222:

```bash
./scripts/launch_chrome.sh
```

Or run directly:

```bash
google-chrome --remote-debugging-port=9222 --user-data-dir="$HOME/.config/google-chrome-flow" "https://flow.google.com" &
```

Log in to your Google Account once. Subsequent runs retain authentication.

---

## Testing & Diagnostics

### Run Doctor Diagnostics

The doctor command verifies your local environment, Node.js version, Chrome binary, CDP connectivity, and Google authentication status:

```bash
node bin/flow.js doctor
```

Output formatted as JSON:

```bash
node bin/flow.js doctor --json
```

### Run Schema Validation & Syntax Check

```bash
npm test
npm run lint
npm run validate:schema
```

### CLI Dry-Run Testing

Verify CLI command parsing and schema compliance without triggering real generation requests:

```bash
node bin/flow.js --help
node bin/flow.js status --help
node bin/flow.js project --help
node bin/flow.js run --dry-run
```

---

## How to Contribute

### 1. Adding New DeepMind or Google Flow Models

When Google adds a new model to `flow.google.com`:

1. Run `node bin/flow.js status` to inspect active options in the live model dropdown.
2. Add the UI name and CLI aliases to `normalizeModelName()` in `src/dom.js`.
3. Add the model name and aliases to the `enum` in `schemas/flow.schema.json`.
4. Update the model table in `references/models-and-settings.md`.
5. Run `npm test` to verify schema validation.

### 2. Updating DOM Selectors

If Google updates Angular classes or button labels:

1. Refer to `references/selectors.md` to see the expected component hierarchy.
2. Update the corresponding selector constant or query in `src/dom.js`.
3. Test using `node bin/flow.js status` and `node bin/flow.js config`.
4. Document the updated selector in `references/selectors.md`.

### 3. Enhancing the CLI or SDK

- Keep the core package zero-dependency. Do not add heavy external libraries for simple utility functions.
- Maintain compatibility with Node.js 18, 20, and 22.
- Ensure all commands support `--json` when applicable for machine readability.

---

## Pull Request Guidelines

1. **Branch Naming**: Use descriptive branch names like `feat/new-model-veo-3.2`, `fix/overlay-dismissal-selector`, or `docs/update-readme`.
2. **Code Style**: Follow standard JavaScript syntax. Run `npm run lint` before committing.
3. **Tests**: Ensure `npm test` passes.
4. **No Secrets**: Never commit cookies, tokens, project IDs, or credentials. Verify with `crenox scan` or equivalent secret scanning before committing.
5. **PR Description**: Use the provided PR template, explain what changed, and link any related issues.
