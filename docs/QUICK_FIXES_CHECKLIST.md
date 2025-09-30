# ⚡ Quick Fixes Checklist

**Low-effort, high-impact improvements you can do RIGHT NOW**

---

## 🏃 5-Minute Fixes

### ✅ 1. Add Deprecation Warnings (5 min)
Pick any old service and add:
```dart
@Deprecated('Use MCPProtocolService instead. Will be removed in v2.0.0')
class MCPProtocolHandler {
  // existing code
}
```

**Files to mark**:
- `lib/core/services/mcp_protocol_handler.dart`
- `lib/core/services/mcp_communication_service.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/design_system/tokens/color_tokens.dart`

---

### ✅ 2. Fix One Hardcoded Color (5 min each)
```dart
// BEFORE
Container(color: Color(0xFF4ECDC4))

// AFTER
final colors = ThemeColors(context);
Container(color: colors.primary)
```

**20 files need this** - knock out 1 per day = done in 4 weeks

---

### ✅ 3. Remove Unused Import (2 min each)
Flutter analyzer shows 12 unused imports. Remove them:
```dart
// Find and delete lines like:
import 'dart:convert'; // ← Delete if unused
```

---

## ⏱️ 30-Minute Fixes

### ✅ 4. Write Your First Test (30 min)
Copy this template, fill in the blanks:

```dart
// test/unit/services/my_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyService', () {
    test('does basic operation', () {
      // ARRANGE
      final service = MyService();

      // ACT
      final result = service.doSomething();

      // ASSERT
      expect(result, isNotNull);
    });
  });
}
```

Run: `flutter test test/unit/services/my_service_test.dart`

---

### ✅ 5. Move a Test File (10 min)
Move one of the 23 root test files:
```bash
# Pick any test_*.dart file from root
mv test_real_integration.dart apps/desktop/test/integration/
```

---

### ✅ 6. Fix Deprecated withOpacity (30 min)
Update all 25 instances:
```dart
// BEFORE
color.withOpacity(0.5)

// AFTER
color.withValues(alpha: 0.5)
```

**Automated Fix**:
```bash
# Find all instances
grep -r "withOpacity" apps/desktop/lib
```

---

## 🕐 1-Hour Fixes

### ✅ 7. Create Test Helpers (60 min)
Copy from `docs/TESTING_BOOTSTRAP.md`:
1. Create `test/helpers/pump_app.dart`
2. Create `test/helpers/mock_services.dart`
3. Create `test/helpers/test_data.dart`

Now you can write tests 5x faster!

---

### ✅ 8. Export Missing Components (60 min)
Add to `lib/core/design_system/design_system.dart`:

```dart
// Add these 12 exports:
export 'components/asmbli_card_enhanced.dart';
export 'components/enhanced_template_browser.dart';
export 'components/auto_detect_button.dart';
export 'components/integration_status_indicators.dart';
export 'components/mcp_testing_widgets.dart';
export 'components/mcp_field_types.dart';
export 'components/quick_actions_dropdown.dart';
export 'components/oauth_fields.dart';
export 'components/smart_mcp_form.dart';
export 'components/service_detection_fields.dart';
export 'components/magical_progress_widget.dart';
export 'components/mcp_progress_widget.dart';
```

---

### ✅ 9. Add Lint Rules (45 min)
Update `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Style
    - prefer_single_quotes
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - sort_child_properties_last

    # Code Quality
    - avoid_print
    - avoid_relative_lib_imports
    - prefer_final_fields
    - unnecessary_null_checks

    # Design System Enforcement
    - avoid_types_on_closure_parameters
    - use_key_in_widget_constructors
```

Run: `flutter analyze`

---

## 🗓️ Daily Habits

### Monday: Write 2 Unit Tests (20 min)
- Pick any service
- Test 2 methods
- Coverage slowly climbs

### Tuesday: Fix 2 Deprecations (15 min)
- Find `SemanticColors.*`
- Replace with `ThemeColors(context)`

### Wednesday: Move 2 Test Files (10 min)
- Pick 2 root test files
- Move to `apps/desktop/test/`

### Thursday: Fix 1 Analyzer Warning (10 min)
- Run `flutter analyze`
- Fix top warning

### Friday: Celebrate Progress! (5 min)
- Run coverage report
- Post update in Slack
- High-five teammate 🙌

---

## 📊 Impact Tracker

Keep a simple log:

```markdown
## Week 1
- [X] Marked 5 services deprecated
- [X] Fixed 3 hardcoded colors
- [X] Wrote 4 unit tests
- [X] Moved 4 test files

Result: Coverage 9% → 11% (+22%)

## Week 2
- [ ] ...
```

---

## 🎯 Quick Win Targets

**End of Week 1:**
- [ ] 10 services marked deprecated
- [ ] 5 hardcoded colors fixed
- [ ] 10 unit tests written
- [ ] 10 test files moved
- [ ] 0 unused imports
- Coverage: 9% → 12%

**End of Week 2:**
- [ ] 20 services marked deprecated
- [ ] 10 hardcoded colors fixed
- [ ] 20 unit tests written
- [ ] All test files organized
- [ ] 0 analyzer warnings
- Coverage: 12% → 15%

---

## 🚀 Just Do One Thing Today

**Feeling overwhelmed? Pick ONE:**

1. ⭐ Write 1 test (any test!)
2. ⭐ Fix 1 hardcoded color
3. ⭐ Move 1 test file
4. ⭐ Add 1 deprecation warning
5. ⭐ Remove 1 unused import

**Every small fix compounds.** Do 1 thing today, another tomorrow. In 8 weeks, you'll be amazed at the progress.

---

## 💡 Pro Tips

### For Maximum Efficiency:
1. **Batch similar tasks** - Fix all colors in one sitting
2. **Use find/replace** - Don't manually update 38 files
3. **Test immediately** - Run tests after each change
4. **Commit often** - Small commits = easy rollback

### Avoid Burnout:
1. **Set timers** - Work in 30-min sprints
2. **Take breaks** - Stretch every hour
3. **Celebrate wins** - Each fix is progress!
4. **Ask for help** - Pair programming doubles speed

---

## 🎉 Motivation

**Current State**: Technical debt is scary
**After Week 1**: You've made measurable progress
**After Week 4**: Team velocity is improving
**After Week 8**: Codebase feels manageable
**After 12 Weeks**: You're proud of what you built

**Start small. Stay consistent. Ship improvements.**

---

**Next Action**: Pick ONE task from the "5-Minute Fixes" and do it RIGHT NOW. ⚡