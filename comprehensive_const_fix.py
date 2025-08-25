#!/usr/bin/env python3
"""Comprehensive fix for const issues in Flutter code."""

import re
import os
from pathlib import Path

def remove_problematic_const(content):
    """Remove const from expressions that cannot be const."""
    
    # Remove const when using theme/color functions
    patterns = [
        # Remove const with ThemeColors, SemanticColors, TextStyles etc
        (r'const\s+((?:EdgeInsets|Padding|Container|SizedBox|Icon|Text|Column|Row|Expanded).*?(?:ThemeColors|SemanticColors|TextStyles|SpacingTokens|BorderRadiusTokens)\([^)]*\)[^,;)]*)', r'\1'),
        
        # Remove const from widgets containing theme references
        (r'const\s+((?:Container|Padding|SizedBox|Column|Row|Expanded|Flexible|Center|Align|Stack|Positioned|Card|InkWell|GestureDetector|Material|DecoratedBox|ClipRRect)\s*\([^{}]*theme\.[^{}]*\))', r'\1'),
        
        # Remove const from Icon/Text with dynamic colors
        (r'const\s+((?:Icon|Text)\s*\([^)]*(?:color|Color)\s*:\s*[^,)]*(?:colors\.|theme\.|colorScheme\.|SemanticColors\.|ThemeColors)[^,)]*)', r'\1'),
        
        # Remove const from widgets with function calls in them
        (r'const\s+((?:Icon|Text|Container|Padding)\s*\([^)]*_get[^)]*\))', r'\1'),
        
        # Remove const from Text with string interpolation  
        (r'const\s+(Text\s*\([^)]*\$[^)]*\))', r'\1'),
        
        # Remove const from EdgeInsets/BorderRadius with token references
        (r'const\s+(EdgeInsets\.(?:all|symmetric|only|fromLTRB)\s*\([^)]*(?:SpacingTokens|spacing)[^)]*\))', r'\1'),
        (r'const\s+(BorderRadius\.(?:circular|all|only|vertical|horizontal)\s*\([^)]*(?:BorderRadiusTokens|radius)[^)]*\))', r'\1'),
        
        # Remove const from Padding/Container with SpacingTokens
        (r'const\s+(Padding\s*\(\s*padding\s*:\s*[^,)]*SpacingTokens[^,)]*)', r'\1'),
        
        # Remove const from SizedBox with SpacingTokens
        (r'const\s+(SizedBox\s*\([^)]*SpacingTokens[^)]*\))', r'\1'),
    ]
    
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content, flags=re.DOTALL | re.MULTILINE)
    
    return content

def fix_file(file_path):
    """Fix const issues in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        content = remove_problematic_const(content)
        
        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Process all Dart files."""
    lib_dir = Path('apps/desktop/lib')
    
    fixed_files = []
    total_files = 0
    
    for dart_file in lib_dir.rglob('*.dart'):
        total_files += 1
        if fix_file(dart_file):
            fixed_files.append(dart_file)
    
    print(f"Processed {total_files} files")
    print(f"Fixed const issues in {len(fixed_files)} files")
    
    if fixed_files:
        print("\nFixed files (first 10):")
        for f in fixed_files[:10]:
            print(f"  - {f.relative_to(Path.cwd())}")
        if len(fixed_files) > 10:
            print(f"  ... and {len(fixed_files) - 10} more")

if __name__ == '__main__':
    main()