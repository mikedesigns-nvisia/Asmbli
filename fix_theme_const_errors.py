#!/usr/bin/env python3
"""Fix all const errors related to theme and dynamic values in Flutter code."""

import re
import os
from pathlib import Path

def remove_const_from_dynamic_widgets(content):
    """Remove const from widgets that use dynamic/theme values."""
    
    # Track if we made changes
    original = content
    
    # Pattern 1: Remove const from any widget containing 'theme.'
    # This catches theme.colorScheme, theme.textTheme, etc.
    content = re.sub(
        r'\bconst\s+(\w+\s*\([^{}]*\btheme\.[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Pattern 2: Remove const from any widget containing ThemeColors, SemanticColors, TextStyles
    content = re.sub(
        r'\bconst\s+(\w+\s*\([^{}]*(?:ThemeColors|SemanticColors|TextStyles)\s*\([^)]*\)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Pattern 3: Remove const from Text widgets with string interpolation
    content = re.sub(
        r'\bconst\s+(Text\s*\([^)]*\$[^)]*\))',
        r'\1',
        content
    )
    
    # Pattern 4: Remove const from widgets with color properties using theme
    content = re.sub(
        r'\bconst\s+((?:Icon|Text|Container|DecoratedBox|Card)\s*\([^)]*color:\s*[^,)]*(?:theme\.|colors\.|ThemeColors|SemanticColors)[^)]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Pattern 5: Remove const from Padding/EdgeInsets with SpacingTokens
    content = re.sub(
        r'\bconst\s+(Padding\s*\(\s*padding:\s*(?:const\s+)?EdgeInsets[^)]*SpacingTokens[^)]*\))',
        lambda m: m.group(1).replace('const EdgeInsets', 'EdgeInsets'),
        content,
        flags=re.DOTALL
    )
    
    # Pattern 6: Remove const from SizedBox with SpacingTokens
    content = re.sub(
        r'\bconst\s+(SizedBox\s*\([^)]*SpacingTokens[^)]*\))',
        r'\1',
        content
    )
    
    # Pattern 7: Remove nested const from EdgeInsets when parent isn't const
    content = re.sub(
        r'padding:\s*const\s+(EdgeInsets[^)]*SpacingTokens[^)]*\))',
        r'padding: \1',
        content
    )
    
    # Pattern 8: Remove const from any widget with .withValues (our new color API)
    content = re.sub(
        r'\bconst\s+(\w+\s*\([^{}]*\.withValues\s*\([^)]*\)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Pattern 9: Fix specific error patterns seen in compilation
    # Remove const from widgets that have dynamic function calls
    content = re.sub(
        r'\bconst\s+((?:Center|Column|Row|Stack|Container|Padding)\s*\([^{}]*(?:CircularProgressIndicator|ErrorMessage)\s*\([^)]*(?:ThemeColors|SemanticColors|theme\.)[^)]*\)[^{}]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Pattern 10: Remove const from widgets with callbacks/functions that reference external variables
    content = re.sub(
        r'\bconst\s+((?:ErrorMessage|InkWell|GestureDetector|IconButton)\s*\([^{}]*(?:onTap|onPressed|onRetry):\s*\([^}]*(?:ref\.|context\.|setState)[^}]*\}[^)]*\))',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Pattern 11: Clean up double const (const const)
    content = re.sub(r'\bconst\s+const\b', 'const', content)
    
    # Pattern 12: Fix specific pattern where Padding has const EdgeInsets but uses theme
    content = re.sub(
        r'(Padding\s*\(\s*padding:\s*)const\s+(EdgeInsets[^,)]+),(\s*child:[^)]*theme\.)',
        r'\1\2,\3',
        content,
        flags=re.DOTALL
    )
    
    return content != original, content

def fix_file(file_path):
    """Fix const issues in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        changed, new_content = remove_const_from_dynamic_widgets(content)
        
        if changed:
            # Make backup
            backup_path = str(file_path) + '.bak'
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            # Write fixed content
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
    
    if not lib_dir.exists():
        print(f"Directory {lib_dir} not found!")
        return
    
    fixed_files = []
    total_files = 0
    
    for dart_file in lib_dir.rglob('*.dart'):
        # Skip generated files
        if '.g.dart' in str(dart_file) or '.freezed.dart' in str(dart_file):
            continue
            
        total_files += 1
        if fix_file(dart_file):
            fixed_files.append(dart_file)
    
    print(f"Processed {total_files} files")
    print(f"Fixed const/theme issues in {len(fixed_files)} files")
    
    if fixed_files:
        print("\nFixed files:")
        for f in fixed_files[:20]:  # Show first 20
            print(f"  ✓ {f.name}")
        if len(fixed_files) > 20:
            print(f"  ... and {len(fixed_files) - 20} more")
    
    print("\nBackup files created with .bak extension")
    print("Run 'flutter analyze' to check remaining issues")

if __name__ == '__main__':
    main()