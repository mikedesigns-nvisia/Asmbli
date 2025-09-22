#!/usr/bin/env python3
"""Fix deprecated withOpacity() calls in Flutter code."""

import os
import re
from pathlib import Path

def fix_with_opacity_in_file(file_path):
    """Fix withOpacity() calls in a single file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match .withOpacity(value)
    # This regex captures the color expression and the opacity value
    pattern = r'(\w+(?:\.\w+)*?)\.withOpacity\(([\d.]+)\)'
    
    def replace_with_values(match):
        color_expr = match.group(1)
        opacity = match.group(2)
        return f'{color_expr}.withValues(alpha: {opacity})'
    
    # Count replacements for reporting
    original_content = content
    content = re.sub(pattern, replace_with_values, content)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def fix_all_dart_files(directory):
    """Fix all Dart files in a directory."""
    fixed_files = []
    dart_files = list(Path(directory).rglob('*.dart'))
    
    for file_path in dart_files:
        if fix_with_opacity_in_file(file_path):
            fixed_files.append(file_path)
    
    return fixed_files

if __name__ == '__main__':
    desktop_app_path = r'C:\Asmbli\apps\desktop'
    
    print('Fixing deprecated withOpacity() calls...')
    fixed_files = fix_all_dart_files(desktop_app_path)
    
    if fixed_files:
        print(f'\nFixed {len(fixed_files)} files:')
        for file in fixed_files:
            print(f'  - {file.relative_to(Path(desktop_app_path))}')
    else:
        print('\nNo files needed fixing!')