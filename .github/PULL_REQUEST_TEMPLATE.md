## Description

Provide a clear and concise description of what this PR accomplishes, including the motivation and context.

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] New model support (adds DeepMind / Google Flow model mapping)
- [ ] DOM selector update (fixes changes in flow.google.com UI)
- [ ] Documentation update
- [ ] CI / Tooling improvement

## Verification & Testing

Describe how you tested these changes:

- [ ] `npm test` passes locally
- [ ] `npm run lint` passes with no syntax errors
- [ ] `node bin/flow.js doctor` runs cleanly
- [ ] Schema validation passes (`npm run validate:schema`)
- [ ] Verified on Chrome CDP port 9222 with real session (if applicable)

```text
(Paste relevant test output or logs here)
```

## Security Checklist

- [ ] No API keys, passwords, or personal credentials committed
- [ ] No temporary files or test media checked in
- [ ] Staged files scanned (`crenox scan` or manual audit)
