import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const manifestPath = path.join(root, "package.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const themeContributions = manifest.contributes?.themes ?? [];

if (themeContributions.length === 0) {
  throw new Error("package.json does not declare any themes");
}

for (const contribution of themeContributions) {
  const themePath = path.resolve(root, contribution.path);
  const theme = JSON.parse(fs.readFileSync(themePath, "utf8"));

  if (!theme.type || !["dark", "light"].includes(theme.type)) {
    throw new Error(`${contribution.path}: type must be \"dark\" or \"light\"`);
  }

  if (!theme.colors || typeof theme.colors !== "object") {
    throw new Error(`${contribution.path}: colors must be an object`);
  }

  if (!Array.isArray(theme.tokenColors)) {
    throw new Error(`${contribution.path}: tokenColors must be an array`);
  }

  for (const token of theme.tokenColors) {
    if (!token.settings || typeof token.settings !== "object") {
      throw new Error(`${contribution.path}: every token must have settings`);
    }

    if (token.settings.fontStyle === "") {
      throw new Error(`${contribution.path}: empty fontStyle values are not allowed`);
    }
  }
}

console.log(`Validated ${themeContributions.length} VS Code themes.`);
