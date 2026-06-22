/**
 * Capture screenshots of a running demo's admin UI for the READMEs.
 *
 * Prerequisites: the demo stack is up (`./run.sh`) so the UI is served at
 * UI_URL and the decree REST API at API_URL.
 *
 * Usage (`npm install` then `npx playwright install chromium` once):
 *   UI_URL=http://localhost:3000 API_URL=http://localhost:8080 \
 *   ROLE=superadmin OUT_DIR=assets/screenshots \
 *   SHOTS='[{"name":"overview","path":"/"}]' \
 *   npm run screenshots
 *
 * SHOTS is a JSON array of {name, path, wait?}. A `{tenantName}` token in a
 * path is replaced with that tenant's UUID (looked up via the API).
 */
import { chromium } from "@playwright/test";
import { mkdirSync } from "node:fs";

const UI_URL = process.env.UI_URL ?? "http://localhost:3000";
const API_URL = process.env.API_URL ?? "http://localhost:8080";
const OUT_DIR = process.env.OUT_DIR ?? "assets/screenshots";
const ROLE = process.env.ROLE ?? "superadmin";
const SUBJECT = process.env.SUBJECT ?? "admin";
const SHOTS = JSON.parse(process.env.SHOTS ?? "[]");

const headers = { "x-subject": SUBJECT, "x-role": ROLE };

async function tenantMap() {
	const res = await fetch(`${API_URL}/v1/tenants`, { headers });
	if (!res.ok) throw new Error(`GET /v1/tenants: ${res.status}`);
	const body = await res.json();
	return new Map((body.tenants ?? []).filter((t) => t.id && t.name).map((t) => [t.name, t.id]));
}

// Only look up tenant IDs when a shot path needs one (a `{tenantName}` token).
const tenants = SHOTS.some((s) => s.path.includes("{")) ? await tenantMap() : new Map();
mkdirSync(OUT_DIR, { recursive: true });

const browser = await chromium.launch();
const context = await browser.newContext({
	viewport: { width: 1440, height: Number(process.env.VIEWPORT_H) || 900 },
	colorScheme: "dark",
});
await context.addInitScript(
	({ subject, role }) => {
		localStorage.setItem("decree-auth", JSON.stringify({ subject, role }));
		localStorage.setItem("decree-dark-mode", "true");
	},
	{ subject: SUBJECT, role: ROLE },
);
const page = await context.newPage();

for (const shot of SHOTS) {
	const path = shot.path.replace(/\{([^}]+)\}/g, (_, name) => {
		const id = tenants.get(name);
		if (!id) throw new Error(`tenant "${name}" not found`);
		return id;
	});
	await page.goto(`${UI_URL}${path}`, { waitUntil: "networkidle" });
	await page.waitForTimeout(shot.wait ?? 1000);
	await page.screenshot({ path: `${OUT_DIR}/${shot.name}.png`, fullPage: true });
	console.log(`saved ${OUT_DIR}/${shot.name}.png  <-  ${path}`);
}

await browser.close();
