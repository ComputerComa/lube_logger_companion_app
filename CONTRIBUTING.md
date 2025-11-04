# Contributing to LubeLogger Companion App

Thank you for your interest in contributing to the LubeLogger Companion App! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Be open to different perspectives

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Android Studio / VS Code with Flutter extensions
- Git

### Setting Up the Development Environment

1. **Fork the repository** and clone your fork:
   ```bash
   git clone https://github.com/your-username/lube_logger_companion_app.git
   cd lube_logger_companion_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Set up a LubeLogger instance** for testing:
   - You'll need a LubeLogger server instance to test the app
   - See [LubeLogger Documentation](https://docs.lubelogger.com/) for setup instructions
   - The instance should be publicly accessible or accessible via VPN

## Development Workflow

### Branch Naming

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `test/description` - Test additions/updates

### Making Changes

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards below

3. **Test your changes**:
   - Run the app and test manually
   - Ensure no lint errors: `flutter analyze`
   - Format your code: `flutter format .`

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

   Use conventional commit messages:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting, etc.)
   - `refactor:` - Code refactoring
   - `test:` - Test additions/changes
   - `chore:` - Build process or auxiliary tool changes

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub

## Coding Standards

### Dart/Flutter Style

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Run `flutter format .` before committing
- Fix all lint warnings with `flutter analyze`

### Code Structure

- Keep files focused and single-purpose
- Use descriptive names for variables, functions, and classes
- Add comments for complex logic
- Follow the existing project structure:
  ```
  lib/
  ├── core/          # Core utilities, constants, theme
  ├── data/          # Models, API client, repositories
  ├── providers/     # Riverpod state management
  ├── services/      # Business logic services
  └── presentation/  # UI screens and widgets
  ```

### State Management

- Use Riverpod for state management
- Prefer `Notifier` over `StateNotifier` for new code (Riverpod 3.0+)
- Use `FutureProvider` for async data fetching
- Keep providers focused and composable

### UI Guidelines

- Use Material Design 3 components
- Follow the app theme defined in `lib/core/theme/app_theme.dart`
- Ensure responsive design for different screen sizes
- Test on both Android and iOS when possible

### Error Handling

- Handle network errors gracefully
- Show user-friendly error messages
- Use try-catch blocks for async operations
- Validate user input before API calls

## Pull Request Process

1. **Update documentation** if needed
2. **Add tests** if applicable
3. **Ensure the app builds** without errors
4. **Fill out the PR template** completely
5. **Link any related issues**
6. **Request review** from maintainers

### PR Review Criteria

- Code follows style guidelines
- Changes are tested and working
- No breaking changes (or clearly documented)
- Documentation updated if needed
- No obvious bugs or security issues

## Reporting Issues

### Before Creating an Issue

1. Check if the issue already exists
2. Verify you're using the latest version
3. Try to reproduce the issue

### Bug Reports

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- Device/OS information
- App version

### Feature Requests

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- Clear description of the feature
- Use case and motivation
- Proposed implementation (if you have ideas)
- Any alternatives considered

## Testing

### Manual Testing Checklist

- [ ] Test on Android device/emulator
- [ ] Test on iOS device/simulator (if available)
- [ ] Test with different network conditions
- [ ] Test error scenarios (network failures, invalid input)
- [ ] Test with different LubeLogger server configurations

### Testing with Your LubeLogger Instance

1. Set up a test LubeLogger instance
2. Create test vehicles and records
3. Test all CRUD operations
4. Verify data syncs correctly
5. Test authentication flows

## Questions?

- Open a discussion for questions
- Check existing issues and discussions
- Review the [LubeLogger Documentation](https://docs.lubelogger.com/)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

