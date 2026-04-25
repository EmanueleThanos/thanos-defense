# Thanos Defense - Project Context

## Project Overview
Thanos Defense is a game project developed using the **Godot Engine (v4.6)**. The project is currently in its early initialization phase, with the core configuration established but no game assets (scenes, scripts, or resources) implemented yet.

### Key Technologies
- **Engine:** Godot 4.6
- **Physics Engine:** Jolt Physics (configured in `project.godot`)
- **Renderer:** GL Compatibility (using D3D12 driver on Windows)
- **Version Control:** Git (with standard Godot ignore patterns)

## Building and Running
As a Godot project, development and execution are primarily handled through the Godot Editor.

### Key Commands
- **Run Project:** Use the Godot Editor or execute `godot --path .` from the terminal.
- **Test Scenes:** F6 (in editor) to run the current scene (once created).
- **Main Scene:** F5 (in editor) to run the project. Note: A main scene has not yet been defined in `project.godot`.

## Development Conventions
- **Naming Conventions:** Follow standard Godot style guides (PascalCase for Nodes/Classes, snake_case for files and variables).
- **Physics:** Ensure compatibility with the Jolt Physics engine when implementing 3D physics.
- **Formatting:** Configured to use `utf-8` via `.editorconfig`.

## Project Structure
- `project.godot`: Main configuration file.
- `.godot/`: Editor metadata and cache (ignored by Git).
- `icon.svg`: Default Godot project icon.
