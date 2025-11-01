# Contributing to QuikxChat

Thank you for your interest in contributing! All contributions are welcome.

## Guidelines

### Pull Requests
- Create a Pull Request for any changes
- Keep PRs focused on one thing
- Use clear, descriptive titles

### Code Style
- Run `flutter format lib` before committing
- Run `dart run import_sorter:main --no-comments` to sort imports
- Keep code simple and maintainable
- Follow Material Design 3 guidelines for UI
- Use ModernBackButton for navigation

### Commits
- Use clear commit messages
- Sign your commits (optional but appreciated)
- Prefer conventional commits format: `feat:`, `fix:`, `docs:`, etc.

### Before Starting
- For small changes (typos, small fixes): just do it
- For bigger changes: open an issue first to discuss

## Development Setup

### Running with AI Features

1. Create `.env` file:
```bash
V2T_SECRET_KEY=your_key
V2T_SERVER_URL=https://your-server.com
```

2. Run:
```bash
./run_linux.sh
```

### Testing

- Test on multiple platforms (Linux, Windows, Android)
- Test with and without AI features enabled
- Test desktop two-column layout
- Test voice message playback and transcription

## What to Contribute

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🌍 Translations
- 🎨 UI/UX improvements (Material Design 3)
- ⚡ Performance optimizations
- 🤖 AI features improvements
- 🖥️ Desktop experience enhancements

## Questions?

Open an issue if you're unsure about anything. Better to ask than to waste time!

## Code of Conduct

Be respectful and constructive. That's it.
