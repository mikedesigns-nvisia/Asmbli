import os
import re

def fix_syntax_errors():
    """Fix syntax errors from incorrect regex replacements."""
    
    # Directory to scan
    base_dir = r"C:\Asmbli\apps\desktop\lib"
    
    # Patterns to fix
    patterns = [
        # Fix escaped single quotes in Text widgets
        (r"Text\(\\'([^']*)'", r"Text('\1'"),
        # Fix any other escaped quotes
        (r"\\'([^']*)'", r"'\1'"),
    ]
    
    files_processed = 0
    files_fixed = 0
    
    # Walk through all Dart files
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                files_processed += 1
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    original_content = content
                    
                    # Apply fixes
                    for pattern, replacement in patterns:
                        content = re.sub(pattern, replacement, content)
                    
                    if content != original_content:
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(content)
                        files_fixed += 1
                        print(f"Fixed: {file_path}")
                        
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")
    
    print(f"\nProcessed {files_processed} files")
    print(f"Fixed {files_fixed} files")

if __name__ == "__main__":
    fix_syntax_errors()