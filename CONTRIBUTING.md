# Contributing a Demo

Thanks for your interest in contributing! Adding a demo is one of the best ways to help people discover OpenDecree.

## What Makes a Good Demo

- **Self-contained** — `docker compose up` starts everything, `docker compose down -v` cleans up
- **Focused** — teaches one concept well, not five concepts poorly
- **Interactive** — gives the reader things to try, not just things to read
- **Tested** — includes a `test.sh` that CI can run to verify the demo works

## Demo Structure

Each demo lives in its own directory at the repo root:

```
your-demo/
├── README.md              # Follows the template below
├── docker-compose.yml     # Self-contained — starts decree + deps
├── test.sh                # Validation script for CI
└── ...                    # Demo-specific files (scripts, config, code)
```

All demos run against a **released Docker image** (`ghcr.io/opendecree/decree:<version>`), not built from source. This keeps demos simple and realistic.

## Demo README Template

Every demo README should follow this structure:

```markdown
# Demo Name

> One-sentence pitch — what you'll see and why it matters.

## What you'll learn

- Bullet point 1
- Bullet point 2
- Bullet point 3

## Prerequisites

- Docker and Docker Compose

(Add any demo-specific prerequisites here, like curl or a specific SDK.)

## Run it

\`\`\`bash
docker compose up
\`\`\`

## What's happening

Step-by-step walkthrough of what the demo does. Include commands
to interact with it and show expected output. Explain the flow,
not just the commands — help the reader build a mental model.

## Try it yourself

Suggested experiments that encourage exploration:
- "Change X in the schema and see what happens to validation"
- "Add a new tenant and give it different values"
- "Try rolling back to version 1"

This is the most important section — it turns a reader into a user.

## Clean up

\`\`\`bash
docker compose down -v
\`\`\`

## Next steps

- Links to related demos (harder or easier)
- Links to relevant SDK docs or API reference
- Link back to the main repo
```

### Why this structure?

| Section | Purpose |
|---------|---------|
| **What you'll learn** | Sets expectations — reader decides in 5 seconds if this is for them |
| **Run it** | Lowest possible barrier — one command |
| **What's happening** | Builds understanding, not just copy-paste muscle memory |
| **Try it yourself** | Turns passive reading into active exploration — the "taste for more" |
| **Next steps** | Funnels to deeper content — SDKs, docs, more demos |

## Adding a Demo

1. Fork the repository and create a branch
2. Create a new directory with a descriptive, lowercase name (e.g., `webhook-alerts/`)
3. Add the files listed above — use the README template
4. Add a `test.sh` that validates the demo works (CI will run it)
5. Test locally: `docker compose up` should work from a clean state
6. Open a pull request against `main`

## Running the Existing Demos

```bash
# Clone and enter the repo
git clone https://github.com/opendecree/demos.git
cd demos

# Pick a demo and follow its README
cd quickstart/
docker compose up
```

Or grab just one demo:

```bash
git clone --no-checkout https://github.com/opendecree/demos.git
cd demos
git sparse-checkout set quickstart
git checkout
```

## Questions?

Open a [Discussion](https://github.com/opendecree/decree/discussions) in the main repo — that's where the community hangs out.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
