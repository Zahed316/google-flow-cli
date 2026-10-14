#!/usr/bin/env node
/**
 * validate-schema.js - Validates JSON schemas and template configurations
 */

const fs = require("fs");
const path = require("path");

const rootDir = path.resolve(__dirname, "..");
const schemaPath = path.join(rootDir, "schemas", "flow.schema.json");
const templatesDir = path.join(rootDir, "templates");

function validate() {
  console.log("Validating schemas and templates...");

  // 1. Validate flow.schema.json
  const schemaRaw = fs.readFileSync(schemaPath, "utf-8");
  const schema = JSON.parse(schemaRaw);
  if (!schema.$schema || !schema.required || !schema.properties) {
    throw new Error("flow.schema.json is missing required schema root fields ($schema, required, properties)");
  }
  console.log("✓ schemas/flow.schema.json is valid Draft-07 schema");

  // 2. Validate templates
  const templateFiles = fs.readdirSync(templatesDir).filter((f) => f.endsWith(".json"));
  for (const file of templateFiles) {
    const fullPath = path.join(templatesDir, file);
    const content = JSON.parse(fs.readFileSync(fullPath, "utf-8"));
    for (const req of schema.required) {
      if (!content[req]) {
        throw new Error(`Template ${file} is missing required field: ${req}`);
      }
    }
    if (!Array.isArray(content.scenes) || content.scenes.length === 0) {
      throw new Error(`Template ${file} must have at least one scene in scenes array`);
    }
    console.log(`✓ templates/${file} validates against required schema fields`);
  }

  console.log("All schemas and templates validated successfully.");
}

try {
  validate();
} catch (err) {
  console.error(`Validation failed: ${err.message}`);
  process.exit(1);
}
