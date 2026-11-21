import assert from "node:assert/strict";
import test from "node:test";
import { selectDownload } from "../../docs/site/releases.js";

import { listing, beta, newerBeta, stable } from "./release-fixtures.mjs";

test("resolves the published beta DMG and skips its checksum", () => {
  const checksum = {
    ...beta.assets[0],
    name: beta.assets[0].name + ".sha256",
    browser_download_url: beta.assets[0].browser_download_url + ".sha256",
  };
  assert.equal(selectDownload([{ ...beta, assets: [checksum, ...beta.assets] }]).url, beta.assets[0].browser_download_url);
});

test("orders stable and beta releases by publication time regardless of API order", () => {
  const draft = { ...stable, draft: true, published_at: "2026-12-31T10:00:00Z" };
  assert.equal(selectDownload([beta, draft, newerBeta]).url, newerBeta.assets[0].browser_download_url);
  assert.equal(selectDownload([beta, stable, newerBeta]).url, stable.assets[0].browser_download_url);
  const laterBeta = { ...newerBeta, published_at: "2026-12-19T10:00:00Z" };
  assert.equal(selectDownload([stable, laterBeta]).tag, laterBeta.tag_name);
});

test("falls back for missing, ambiguous, incomplete or mismatched assets", () => {
  const other = { ...newerBeta.assets[0], name: "Intel.dmg", browser_download_url: `${listing}/download/${newerBeta.tag_name}/Intel.dmg` };
  for (const assets of [
    [],
    [...newerBeta.assets, other],
    [{ ...other, state: "new" }],
    [{ ...other, size: 0 }],
    [{ ...other, browser_download_url: "https://example.com/Intel.dmg" }],
    [{ ...other, browser_download_url: `${listing}/download/${beta.tag_name}/Intel.dmg` }],
  ]) {
    assert.equal(selectDownload([beta, { ...newerBeta, assets }]), undefined);
  }
  assert.equal(selectDownload({ message: "rate limited" }), undefined);
});
