#!/usr/bin/env python3

import re
import sys

def fix_const_errors(file_path):
    """Fix const constructor errors in Dart file."""
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    original_content = content
    
    # Pattern to find const constructors that shouldn't be const
    # This looks for const widgets that have dynamic references
    patterns_to_fix = [
        # Remove const from widgets that use Theme.of(context) or ThemeColors(context)
        (r'const\s+(Container|Column|Row|Center|Padding|SizedBox)\s*\(([^}]+(?:Theme\.of\(context\)|ThemeColors\(context\))[^}]*)\)', r'\1(\2)'),
        
        # Remove const from widgets that reference SpacingTokens
        (r'const\s+(Container|Column|Row|Center|Padding|SizedBox)\s*\(([^}]+SpacingTokens[^}]*)\)', r'\1(\2)'),
        
        # Remove const from decorations that use theme colors
        (r'const\s+(BoxDecoration|Border|BorderRadius)\s*\(([^}]+(?:Theme\.of\(context\)|ThemeColors\(context\))[^}]*)\)', r'\1(\2)'),
    ]
    
    changes_made = 0
    
    for pattern, replacement in patterns_to_fix:
        new_content, count = re.subn(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
        if count > 0:
            content = new_content
            changes_made += count
            print(f"Applied pattern fix: {count} changes")
    
    # More specific fixes based on the error lines
    specific_fixes = [
        # Fix const Center with dynamic children
        (r'child:\s+const\s+Center\s*\(\s*child:\s+Container\s*\(\s*constraints:\s+const\s+BoxConstraints', 'child: Center(\n        child: Container(\n          constraints: BoxConstraints'),
        
        # Fix const Container with theme references
        (r'const\s+Container\s*\(\s*([^}]*(?:Theme\.of\(context\)|ThemeColors\(context\))[^}]*)\)', r'Container(\1)'),
        
        # Fix const BorderRadius with theme references  
        (r'const\s+BorderRadius\s*\.\s*circular\s*\([^)]*\)', r'BorderRadius.circular(8)'),
        
        # Fix const Border with theme references
        (r'const\s+Border\s*\.\s*all\s*\([^}]*(?:Theme\.of\(context\)|ThemeColors\(context\))[^}]*\)', r'Border.all(color: Theme.of(context).colorScheme.outline)'),
    ]
    
    for pattern, replacement in specific_fixes:
        new_content, count = re.subn(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)
        if count > 0:
            content = new_content
            changes_made += count
            print(f"Applied specific fix: {count} changes")
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)
        print(f"Fixed {changes_made} const errors in {file_path}")
        return True
    else:
        print(f"No const errors found to fix in {file_path}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fix_const_errors.py <dart_file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    fix_const_errors(file_path)