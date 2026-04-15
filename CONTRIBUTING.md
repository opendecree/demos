# Contributing a Demo

Thanks for your interest in contributing! Adding a demo is one of the best ways to help people discover OpenDecree.

## What Makes a Good Demo

- **Self-contained** — `docker compose up` starts everything, `docker compose down` cleans up
- **Focused** — teaches one concept well, not five concepts poorly
- **Documented** — a README that explains *what* and *why*, not just *how*
- **Tested** — includes a `test.sh` that CI can run to verify the demo works

## Demo Structure

Each demo lives in its own directory at the repo root:

```
your-demo/
├── README.md              # What this demo shows and why you'd care
├── docker-compose.yml     # Extends the root compose or runs standalone
├── test.sh                # Validation script for CI
└── ...                    # Demo-specific files (scripts, config, code)
```

## Adding a Demo

1. Fork the repository and create a branch
2. Create a new directory with a descriptive, lowercase name (e.g., `webhook-alerts/`)
3. Add the files listed above
4. Test it locally: `docker compose up` should work from a clean state
5. Open a pull request against `main`

## Running the Existing Demos

```bash
# Clone and enter the repo
git clone https://github.com/opendecree/demos.git
cd demos

# Pick a demo and follow its README
cd quickstart/
docker compose up
```

## Questions?

Open a [Discussion](https://github.com/opendecree/decree/discussions) in the main repo — that's where the community hangs out.

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.
