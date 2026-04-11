#!/bin/bash
# Local CI check - mirrors GitHub Actions workflow
# Run this BEFORE pushing to save GitHub minutes

set -e  # Exit on first failure

echo "========================================="
echo "  Local CI Check (mirrors GitHub Actions)"
echo "========================================="
echo ""

echo "[1/4] flutter pub get"
flutter pub get
echo ""

echo "[2/4] flutter analyze"
flutter analyze --no-fatal-infos
echo ""

echo "[3/4] flutter test"
flutter test --coverage
echo ""

echo "[4/4] flutter build apk --release"
flutter build apk --release --split-per-abi
echo ""

echo "========================================="
echo "  ✅ All checks passed!"
echo "  Safe to push."
echo "========================================="
