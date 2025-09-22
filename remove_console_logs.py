#!/usr/bin/env python3
"""Remove console.log statements from production code."""

import os
import re
from pathlib import Path

def remove_console_logs_in_file(file_path):
    """Remove console.log/error/warn statements from a file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    modified = False
    new_lines = []
    
    for line in lines:
        # Check if line contains console.log/error/warn
        if re.search(r'console\.(log|error|warn)\(', line):
            # Replace with a comment preserving indentation
            indent = len(line) - len(line.lstrip())
            new_line = ' ' * indent + '// Console output removed for production\n'
            new_lines.append(new_line)
            modified = True
        else:
            new_lines.append(line)
    
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        return True
    return False

def process_directory(directory, extensions):
    """Process all files with given extensions in directory."""
    fixed_files = []
    
    for ext in extensions:
        for file_path in Path(directory).rglob(f'*.{ext}'):
            # Skip node_modules, .next, and other build directories
            if any(part in str(file_path) for part in ['node_modules', '.next', 'dist', 'build', '.dart_tool']):
                continue
            
            if remove_console_logs_in_file(file_path):
                fixed_files.append(file_path)
    
    return fixed_files

if __name__ == '__main__':
    root_path = r'C:\AgentEngine'
    
    print('Removing console.log statements from production code...')
    
    # Process TypeScript/JavaScript files
    ts_files = process_directory(root_path, ['ts', 'tsx', 'js', 'jsx'])
    
    if ts_files:
        print(f'\nFixed {len(ts_files)} TypeScript/JavaScript files')
    else:
        print('\nNo console statements found in TypeScript/JavaScript files')