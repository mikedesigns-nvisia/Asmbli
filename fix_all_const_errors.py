#!/usr/bin/env python3
"""Comprehensive fix for ALL const errors in Flutter code."""

import re
import os
from pathlib import Path

def fix_const_errors(content):
    """Fix all types of const errors."""
    original = content
    
    # 1. Remove const from widgets with variable colors
    content = re.sub(
        r'\bconst\s+((?:SizedBox|Container|CircularProgressIndicator|Icon|Text)\s*\([^{}]*(?:valueColor|color):\s*[^,)]*\w+[^,)]*)',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # 2. Remove const from AlwaysStoppedAnimation with variables
    content = re.sub(
        r'\bconst\s+(SizedBox\s*\([^{}]*CircularProgressIndicator\s*\([^{}]*AlwaysStoppedAnimation[^{}]*\w+[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # 3. Fix specific patterns from errors
    # Remove const from Icon widgets with variable parameters
    content = re.sub(
        r'\bconst\s+(Icon\s*\(\s*\w+\s*,\s*size:\s*\d+\s*\))',
        r'\1',
        content
    )
    
    # 4. Remove const from widgets referencing variables (not constants)
    # This catches things like: const Text(variable)
    content = re.sub(
        r'\bconst\s+((?:Text|Icon|Container|SizedBox|Padding)\s*\(\s*\w+[^),]*\))',
        r'\1',
        content
    )
    
    # 5. Remove const from widgets with theme/color references
    content = re.sub(
        r'\bconst\s+((?:Widget\s+)?[\w<>]+\s*\([^{}]*(?:theme\.|colors\.|ThemeColors|SemanticColors|foregroundColor|backgroundColor)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # 6. Fix const with method invocations
    content = re.sub(
        r'\bconst\s+([\w<>]+\s*\([^{}]*\.[\w]+\([^)]*\)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # 7. Fix const with SpacingTokens and other design tokens
    content = re.sub(
        r'\bconst\s+((?:EdgeInsets|SizedBox|Padding|Container)\s*\([^{}]*(?:SpacingTokens|BorderRadiusTokens|TextStyles)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # 8. Remove const from complex expressions
    # This catches widgets with conditional expressions, function calls, etc.
    content = re.sub(
        r'\bconst\s+([\w<>]+\s*\([^{}]*(?:\?|\w+\([^)]*\)|\.[\w]+)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # 9. Fix specific error patterns seen in analyze output
    # Remove const from widgets with non-const constructors
    patterns_to_fix = [
        r'\bconst\s+(Card\s*\([^{}]*\))',
        r'\bconst\s+(AsmblCard[^{]*\([^{}]*\))',
        r'\bconst\s+(HeaderButton\s*\([^{}]*\))',
        r'\bconst\s+(AsmblButton[^{]*\([^{}]*\))',
    ]
    
    for pattern in patterns_to_fix:
        content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
    
    # 10. Clean up artifacts
    # Fix double spaces that might have been created
    content = re.sub(r'  +', ' ', content)
    
    return content != original, content

def fix_file(file_path):
    """Fix const issues in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        changed, new_content = fix_const_errors(content)
        
        if changed:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Process all Dart files in the Flutter desktop app."""
    lib_dir = Path('apps/desktop/lib')
    components_dir = Path('apps/desktop/lib/components')
    
    directories = [lib_dir, components_dir]
    
    fixed_files = []
    total_files = 0
    
    for directory in directories:
        if not directory.exists():
            continue
            
        for dart_file in directory.rglob('*.dart'):
            # Skip generated files and backups
            if any(suffix in str(dart_file) for suffix in ['.g.dart', '.freezed.dart', '.bak']):
                continue
                
            total_files += 1
            if fix_file(dart_file):
                fixed_files.append(dart_file)
    
    print(f"Processed {total_files} files")
    print(f"Fixed const issues in {len(fixed_files)} files")
    
    if fixed_files:
        print("\nFixed files:")
        for f in fixed_files:
            print(f"  * {f.name}")
    
    print("\nRun 'flutter analyze' to check remaining issues")

if __name__ == '__main__':
    main()