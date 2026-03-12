# Contributing to PomoDaddy

## Development Setup

1. Install dependencies:
   ```bash
   make setup
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open PomoDaddy.xcodeproj
   ```

## Development Workflow

### Building

```bash
make build
```

### Testing

```bash
make test
```

### Linting

```bash
make lint
```

### Formatting

```bash
make format        # Auto-format
make format-check  # Check only
```

## Pull Request Process

1. Fork the repository and create a feature branch
2. Make your changes
3. Run `make lint` and `make test` to ensure everything passes
4. Submit a pull request with a clear description of changes

## XcodeGen Note

The `.xcodeproj` is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). Do not edit the project file directly. Run `xcodegen generate` after changing `project.yml`.

## Code Style

- Follow existing patterns in the codebase
- SwiftLint and SwiftFormat configurations are included
- Use `@Observable` for state management
- Use the coordinator pattern for cross-cutting concerns
