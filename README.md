# Flutter Doctor Pro 🩺

A production-ready Dart CLI package that acts as a Chief Medical Officer for your Flutter projects. It scans your entire codebase, generates a 100-point Health Score, and can automatically fix issues for you!

[![pub package](https://img.shields.io/pub/v/flutter_doctor_pro.svg)](https://pub.dev/packages/flutter_doctor_pro)

## Features ✨

* **`check`**: Scans Code Quality (Lints, Large Classes), Assets (Unused/Oversized), Packages (Unused), and Complexity.
* **`score`**: Calculates a normalized 100-point Health Score based on configured weights.
* **`report`**: Generates detailed Markdown and JSON reports in `.flutter_doctor_pro/reports/`.
* **`fix`**: The Auto-Fix Engine automatically removes unused packages, deletes unused assets, and safely applies Dart fixes!
* **`undo`**: A built-in Backup System that lets you revert the last auto-fix with a single command!

## Installation 🚀

Activate the CLI globally so you can run it from any Flutter project:

```bash
dart pub global activate flutter_doctor_pro
```

## Usage 🛠️

Once activated, simply run it in the root of your Flutter project:

```bash
# Run a full scan and see what's wrong
flutter_doctor_pro check

# Get your App's Health Score (out of 100)
flutter_doctor_pro score

# Automatically fix safe issues (Lints, Unused Packages, Unused Assets)
flutter_doctor_pro fix

# Undo the last fix if something went wrong
flutter_doctor_pro undo

# Generate detailed reports
flutter_doctor_pro report
```

## Custom Configuration ⚙️

Create a `flutter_doctor_pro.yaml` in the root of your project to customize weights, minimum scores, and max file sizes:

```yaml
max_image_size_mb: 2.0
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
