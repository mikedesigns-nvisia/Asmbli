import os
import re

def fix_remaining_syntax_errors():
    """Fix remaining syntax errors from incorrect regex replacements."""
    
    # Directory to scan
    base_dir = r"C:\AgentEngine\apps\desktop\lib"
    
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
                    
                    # Fix common issues from broken regex
                    
                    # Fix broken strings with escaped quotes that should be normal strings
                    content = re.sub(r"'([^']*)\\'([^']*)'", r"'\1'\2'", content)
                    content = re.sub(r"'([^']*)\\'", r"'\1'", content)
                    
                    # Fix issues with JavaScript/TypeScript-like syntax that got broken
                    # Fix 'react' references that got broken
                    content = re.sub(r"from 'react\\'", r"from 'react'", content)
                    content = re.sub(r"import React from 'react\\'", r"import React from 'react'", content)
                    
                    # Fix interface declarations that got broken
                    content = re.sub(r"interface\\{\\}", r"interface{}", content)
                    
                    # Fix other common patterns
                    content = re.sub(r"'node\\'", r"'node'", content)
                    content = re.sub(r"'data\\'", r"'data'", content)
                    
                    # Fix malformed strings in contentPreview
                    # Look for patterns like: contentPreview: '// Button Component\nimport React from 'react\';\n\ninterface ButtonProps {\n variant: 'primary\' | 'secondary\';\n children: React.ReactNode;\n}'
                    content = re.sub(r"contentPreview: '([^']*)\\'([^']*)\\'([^']*)'", r"contentPreview: '\1'\2'\3'", content)
                    
                    # Fix more specific patterns
                    content = re.sub(r"from 'react\\';\n", r"from 'react';\n", content)
                    content = re.sub(r"variant: 'primary\\' \| 'secondary\\'", r"variant: 'primary' | 'secondary'", content)
                    content = re.sub(r"testEnvironment: 'node\\'", r"testEnvironment: 'node'", content)
                    
                    # Fix any remaining escaped quotes in string literals
                    # This is more aggressive - fix any \' that appears to be in the middle of a string
                    content = re.sub(r"(['\"])([^'\"]*)\\'([^'\"]*)\1", r"\1\2'\3\1", content)
                    
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
    fix_remaining_syntax_errors()