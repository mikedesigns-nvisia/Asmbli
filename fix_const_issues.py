#!/usr/bin/env python3
"""Fix const issues in Flutter files where non-const functions are called."""

import re
import os
from pathlib import Path

def fix_const_issues(file_path):
    """Remove const where non-const functions or variables are used."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Pattern 1: const Icon with function calls
    # Remove const from Icon widgets that use function calls
    content = re.sub(
        r'const\s+(Icon\s*\([^)]*_get[^)]*\))',
        r'\1',
        content
    )
    
    # Pattern 2: const Text with interpolation
    # Remove const from Text widgets with string interpolation
    content = re.sub(
        r'const\s+(Text\s*\([^)]*\$[^)]*\))',
        r'\1',
        content
    )
    
    # Pattern 3: const with color/theme function calls
    content = re.sub(
        r'const\s+(Icon\s*\([^)]*(?:color|Color)\s*:\s*[^,)]*(?:colors\.|theme\.|colorScheme\.|_get)[^,)]*)',
        r'\1',
        content,
        flags=re.IGNORECASE
    )
    
    # Pattern 4: Remove const from widgets with dynamic properties
    # Match widgets that have dynamic color properties
    content = re.sub(
        r'const\s+((?:Container|Padding|SizedBox|Column|Row|Expanded|Flexible)\s*\([^)]*(?:colors\.|theme\.|colorScheme\.)[^)]*\))',
        r'\1',
        content
    )
    
    # Pattern 5: Fix EdgeInsets with non-const values  
    content = re.sub(
        r'const\s+(EdgeInsets\.(?:all|symmetric|only)\s*\([^)]*Spacing[^)]*\))',
        r'\1',
        content
    )
    
    # Pattern 6: Fix BorderRadius with non-const values
    content = re.sub(
        r'const\s+(BorderRadius\.(?:circular|all|only)\s*\([^)]*BorderRadius[^)]*\))',
        r'\1',
        content
    )
    
    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    """Process all Dart files in the Flutter desktop app."""
    lib_dir = Path('apps/desktop/lib')
    
    fixed_files = []
    for dart_file in lib_dir.rglob('*.dart'):
        if fix_const_issues(dart_file):
            fixed_files.append(dart_file)
    
    print(f"Fixed const issues in {len(fixed_files)} files")
    for f in fixed_files[:10]:  # Show first 10
        print(f"  - {f}")
    if len(fixed_files) > 10:
        print(f"  ... and {len(fixed_files) - 10} more")

if __name__ == '__main__':
    main()