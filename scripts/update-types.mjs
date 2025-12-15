#!/usr/bin/env node
import fs from "fs/promises";
import { createWriteStream } from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import { Readable } from "stream";
import { pipeline as pipelinePromises } from "stream/promises";
import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const versionsPath = path.join(repoRoot, "openiap-versions.json");
const targetFile = path.join(repoRoot, "src", "types.ts");

if (typeof fetch !== "function") {
  console.error("Node 18+ with global fetch is required to run this script.");
  process.exit(1);
}

const toNodeStream = (body) =>
  body instanceof Readable ? body : Readable.fromWeb(body);

async function readDefaultTag() {
  try {
    const raw = await fs.readFile(versionsPath, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed.gql) {
      throw new Error("Missing 'gql' entry in openiap-versions.json");
    }
    return parsed.gql;
  } catch (error) {
    throw new Error(
      `Unable to read default tag from ${versionsPath}: ${error.message}`,
    );
  }
}

function buildCandidateTags(inputTag) {
  if (inputTag.startsWith("gql-")) {
    return [inputTag];
  }
  return [`gql-${inputTag}`, inputTag];
}

async function downloadZip(url, destination) {
  const response = await fetch(url);
  if (!response.ok || !response.body) {
    throw new Error(`HTTP ${response.status} when fetching ${url}`);
  }
  await pipelinePromises(toNodeStream(response.body), createWriteStream(destination));
}

async function extractTypes(zipPath, destinationDir) {
  await execFileAsync("unzip", ["-o", zipPath, "types.ts", "-d", destinationDir]);
  const extracted = path.join(destinationDir, "types.ts");
  return fs.readFile(extracted, "utf8");
}

async function updateTypes() {
  const requestedTag = process.argv[2] || (await readDefaultTag());
  const candidateTags = buildCandidateTags(requestedTag);

  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "openiap-types-"));
  const zipPath = path.join(tempDir, "openiap-dart.zip");

  let resolvedTag = null;
  for (const tag of candidateTags) {
    const url = `https://github.com/hyodotdev/openiap/releases/download/${tag}/openiap-dart.zip`;
    try {
      console.log(`Attempting to download types from tag ${tag}...`);
      await downloadZip(url, zipPath);
      const contents = await extractTypes(zipPath, tempDir);

      await fs.mkdir(path.dirname(targetFile), { recursive: true });
      await fs.writeFile(targetFile, contents);
      resolvedTag = tag;
      console.log(`Updated src/types.ts from tag ${tag}`);
      break;
    } catch (error) {
      console.warn(
        `Failed to update types for tag ${tag}: ${error.message}. Falling back...`,
      );
    }
  }

  await fs.rm(tempDir, { recursive: true, force: true });

  if (!resolvedTag) {
    console.error(
      `Failed to update types. Tried tags: ${candidateTags.join(", ")}`,
    );
    process.exit(1);
  }
}

updateTypes().catch((error) => {
  console.error(error);
  process.exit(1);
});
