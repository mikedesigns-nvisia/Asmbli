#!/usr/bin/env python3
"""Add const constructors where appropriate in Flutter code."""

import os
import re
from pathlib import Path

def add_const_constructors_in_file(file_path):
    """Add const to constructors where appropriate."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False
    original_content = content
    
    # Patterns to fix
    patterns = [
        # SizedBox without const
        (r'(\s+)SizedBox\(', r'\1const SizedBox('),
        # EdgeInsets without const
        (r'(\s+)EdgeInsets\.all\(', r'\1const EdgeInsets.all('),
        (r'(\s+)EdgeInsets\.symmetric\(', r'\1const EdgeInsets.symmetric('),
        (r'(\s+)EdgeInsets\.only\(', r'\1const EdgeInsets.only('),
        # Icon without const
        (r'(\s+)Icon\(', r'\1const Icon('),
        # Text with literal string without const
        (r'(\s+)Text\([\'"]', r'\1const Text(\''),
        # Padding without const
        (r'(\s+)Padding\(', r'\1const Padding('),
        # Center without const
        (r'(\s+)Center\(', r'\1const Center('),
        # Align without const
        (r'(\s+)Align\(', r'\1const Align('),
        # Duration without const
        (r'(\s+)Duration\(', r'\1const Duration('),
    ]
    
    for pattern, replacement in patterns:
        # Only add const if it's not already there
        # Check that const doesn't already exist before the pattern
        check_pattern = pattern.replace(r'(\s+)', r'(\s+)(?<!const )(?<!const\s)')
        content = re.sub(check_pattern, replacement, content)
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def process_dart_files(directory):
    """Process all Dart files in directory."""
    fixed_files = []
    dart_files = list(Path(directory).rglob('*.dart'))
    
    for file_path in dart_files:
        # Skip generated files
        if '.g.dart' in str(file_path) or '.freezed.dart' in str(file_path):
            continue
            
        if add_const_constructors_in_file(file_path):
            fixed_files.append(file_path)
    
    return fixed_files

if __name__ == '__main__':
    desktop_app_path = r'C:\AgentEngine\apps\desktop'
    
    print('Adding const constructors where appropriate...')
    fixed_files = process_dart_files(desktop_app_path)
    
    if fixed_files:
        print(f'\nFixed {len(fixed_files)} files')
    else:
        print('\nNo files needed const constructor fixes')