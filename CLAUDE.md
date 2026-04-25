# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Thanos Defense** — a Godot 4.6 game project in early initialization. No scenes, scripts, or resources exist yet.

## Running

- **Open in editor:** launch Godot Editor and open this directory, or `godot --path .`
- **Run project:** F5 in editor (no main scene is defined yet — set one in Project Settings first)
- **Run current scene:** F6 in editor

## Configuration

- **Engine:** Godot 4.6
- **Physics:** Jolt Physics (3D) — ensure 3D physics code is compatible with Jolt rather than the default Godot Physics
- **Renderer:** GL Compatibility (D3D12 on Windows via `rendering_device/driver.windows="d3d12"`)
- `project.godot` is best edited through the Godot Editor UI, not directly

## Conventions

- PascalCase for Node types and class names; snake_case for file names and variables/functions
- File encoding: UTF-8 (enforced by `.editorconfig`)
- `.godot/` is editor cache — do not commit it (already in `.gitignore`)
