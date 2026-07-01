# Flutter Doctor Pro 🩺

A production-ready Dart CLI package that acts as a Chief Medical Officer for your Flutter projects. It scans your entire codebase, analyzes multiple metrics, generates a 100-point Health Score, and can automatically fix issues for you!

[![pub package](https://img.shields.io/pub/v/flutter_doctor_pro.svg)](https://pub.dev/packages/flutter_doctor_pro)

## Features ✨

Flutter Doctor Pro comes with a set of powerful scanners to detect code anomalies and anti-patterns:

* **Asset Scanner**: Finds unused, oversized, or unoptimized image assets.
* **Code Quality Scanner**: Detects linter warnings, outdated Dart patterns, and oversized classes.
* **Package/Dependencies Scanner**: Identifies unused packages in your `pubspec.yaml` by scanning your code's AST.
* **Performance Scanner**: Flags inefficient list rendering, oversized widgets, and poor animation practices.
* **Localization Scanner**: Checks if all strings used in code exist in `.arb` files and warns on missing translations.
* **Theme Scanner**: Warns about hardcoded colors and text styles, encouraging proper Theme usage.
* **Widget Complexity Scanner**: Detects deep widget trees and overly complex `build` methods.
* **Build Analyzer**: Highlights slow build times and build cache issues.

## Installation 🚀

Activate the CLI globally so you can run it from any Flutter project:

```bash
dart pub global activate flutter_doctor_pro
```

## Available Commands 🛠️

Once activated, simply run `flutter_doctor_pro <command>` in the root of your Flutter project.

### 1. `doctor`
Runs a comprehensive health check on your Flutter project and prints a summary of all critical issues.
```bash
flutter_doctor_pro doctor
```

### 2. `check`
Runs a quick, non-intrusive scan without failing on scores. Perfect for CI/CD checks to just display warnings.
```bash
flutter_doctor_pro check
```

### 3. `score`
Calculates a normalized 100-point Health Score based on configured weights. It also generates a `score_report.json`.
```bash
flutter_doctor_pro score
```

### 4. `fix`
The Auto-Fix Engine automatically removes unused packages, deletes unused assets, and safely applies Dart fixes!
```bash
flutter_doctor_pro fix
```

### 5. `clean`
Interactively clean unused or duplicate files from the project.
```bash
flutter_doctor_pro clean
```

### 6. `report`
Generates reports in multiple formats (`JSON`, `HTML`, `Markdown`, `CSV`). If no format is specified, generates all. Reports are saved in `.flutter_doctor_pro/reports/`.
```bash
flutter_doctor_pro report
```

### 7. `backup` & `restore` & `undo`
A built-in Backup System that safely backs up your project before any destructive operations (`fix` or `clean`), allowing you to restore easily.
```bash
flutter_doctor_pro backup
flutter_doctor_pro restore
flutter_doctor_pro undo
```

## Custom Configuration ⚙️

Create a `flutter_doctor_pro.yaml` in the root of your project to customize weights, minimum scores, ignore paths, and max file sizes:

```yaml
# Paths to ignore during scanning
ignore:
  - "build/**"
  - ".dart_tool/**"

max_image_size_mb: 1.5

score:
  minimum: 85
  weights:
    assets: 15
    code_quality: 25
    complexity: 10
    theme: 10
    performance: 15
    dependencies: 15
    localization: 10
```

## Built With ❤️

Designed and built for developers who care about code quality.
