#!/bin/bash
# Code metrics for Asmbli

echo "📊 Asmbli Code Metrics"
echo "===================="
echo ""

# Navigate to desktop app
cd apps/desktop 2>/dev/null || cd .

# Lines of Dart code
echo "📝 Lines of Code:"
echo -n "  Dart code: "
find lib -name "*.dart" -type f -exec cat {} \; | wc -l | tr -d ' '

# File counts
echo ""
echo "📁 File Counts:"
echo -n "  Dart files: "
find lib -name "*.dart" -type f | wc -l | tr -d ' '
echo -n "  Service files: "
find lib -name "*service*.dart" -type f | wc -l | tr -d ' '
echo -n "  Screen files: "
find lib -name "*screen*.dart" -type f | wc -l | tr -d ' '
echo -n "  Test files: "
find test -name "*.dart" -type f 2>/dev/null | wc -l | tr -d ' '

# Large files
echo ""
echo "⚠️  Large Files (>1000 lines):"
find lib -name "*.dart" -type f -exec wc -l {} \; | awk '$1 > 1000 {print "  " $2 ": " $1 " lines"}' | sort -k3 -nr

# Services count
echo ""
echo "🔧 Service Analysis:"
echo -n "  Total services registered: "
grep -E "(registerSingleton|registerLazySingleton|registerFactory)" lib/core/di/service_locator.dart 2>/dev/null | wc -l | tr -d ' '

# Test coverage
echo ""
echo "🧪 Test Coverage:"
if [ -f coverage/lcov.info ]; then
    echo -n "  Current coverage: "
    # Simple coverage calculation from lcov.info
    grep -o "LF:[0-9]*" coverage/lcov.info | cut -d: -f2 | awk '{s+=$1} END {print s}' | tr -d ' '
    echo " lines"
else
    echo "  No coverage data found. Run: flutter test --coverage"
fi

# TODO/FIXME count
echo ""
echo "📋 Technical Debt Markers:"
echo -n "  TODOs: "
grep -r "TODO" lib --include="*.dart" 2>/dev/null | wc -l | tr -d ' '
echo -n "  FIXMEs: "
grep -r "FIXME" lib --include="*.dart" 2>/dev/null | wc -l | tr -d ' '
echo -n "  Deprecated: "
grep -r "@deprecated" lib --include="*.dart" 2>/dev/null | wc -l | tr -d ' '

# Dependencies
echo ""
echo "📦 Dependencies:"
echo -n "  Direct dependencies: "
grep -E "^[[:space:]]+[a-z_]+:" pubspec.yaml | grep -v "flutter:" | wc -l | tr -d ' '
echo -n "  Dev dependencies: "
grep -A 100 "dev_dependencies:" pubspec.yaml | grep -E "^[[:space:]]+[a-z_]+:" | wc -l | tr -d ' '

echo ""
echo "✨ Run 'flutter analyze' for detailed code quality report"