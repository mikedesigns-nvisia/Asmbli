#!/usr/bin/env python3

import os
import re

def fix_mcp_imports():
    lib_dir = r"C:\Asmbli\apps\desktop\lib"
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                
                # Skip the main model file
                if 'mcp_server_config.dart' in file_path:
                    continue
                    
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Check if file uses MCPServerConfig but doesn't import it
                    if 'MCPServerConfig' in content and '../models/mcp_server_config.dart' not in content:
                        # Find the import section
                        import_lines = []
                        other_lines = []
                        in_imports = True
                        
                        for line in content.split('\n'):
                            if line.strip().startswith('import '):
                                import_lines.append(line)
                            elif line.strip() == '' and in_imports:
                                import_lines.append(line)
                            else:
                                if in_imports and line.strip() != '':
                                    in_imports = False
                                other_lines.append(line)
                        
                        # Calculate relative path to models from current file location
                        file_rel_path = os.path.relpath(file_path, lib_dir)
                        depth = file_rel_path.count(os.sep) - 1
                        relative_path = '../' * depth + 'core/models/mcp_server_config.dart'
                        
                        # Add the import
                        import_lines.append(f"import '{relative_path}';")
                        
                        # Reconstruct file
                        new_content = '\n'.join(import_lines + [''] + other_lines)
                        
                        with open(file_path, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        
                        print(f"Added import to {file_path}")
                        
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_mcp_imports()