# AGENTS

This document outlines the coding conventions and patterns used in this project.

Before writing any new function:
1. Search the codebase for similar functionality
2. If a match exists, reuse it
3. If extending behavior, modify the existing function instead
4. Do NOT create duplicate utilities

## Project Structure

The project follows a clear modular structure:
- `MainViews`: Contains main application views and components
- `HelperViews`: Utility views and components
- `Persistence`: Database and storage related code
- `Utils`: Utility functions and classes
- `Localizations`: Localization files

## Code Style Conventions

### File Naming
- Files are named using PascalCase (e.g., `FilenFotoApp.swift`)
- View files end with `View` suffix when appropriate (e.g., `ContentView.swift`)

### Variable and Function Naming
- Use descriptive names that clearly indicate purpose
- Use `camelCase` for variables and functions
- Use `PascalCase` for types (classes, structs, enums)
- Prefix private properties with underscore (e.g., `_privateProperty`)
- Use `dbAsset` instead of `asset` when referring to database assets

### Code Organization
- Group related functionality together
- Use comments to separate logical sections
- Keep functions small and focused on a single responsibility
- Use meaningful variable names over abbreviations
- Place extension methods with their primary type

### Documentation
- Add comments to explain complex logic or non-obvious code
- Use Swift doc comments (///) for public APIs
- Include brief descriptions of what functions do
- Document parameters and return values for public functions

### Code Patterns
- Use `guard let` and `if let` patterns for optional unwrapping
- Use `try?` and `do-catch` for error handling when appropriate
- Use `assert()` in DEBUG builds for development-time checks
- Use `@available(*, deprecated)` for deprecated functions
- Prefer immutable structures (`let`) over mutable ones (`var`) when possible