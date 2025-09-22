import os
import re

def fix_agent_config_errors():
    """Fix agent configuration screen syntax errors."""
    
    file_path = r"C:\Asmbli\apps\desktop\lib\features\agents\presentation\screens\agent_configuration_screen.dart"
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Fix specific broken strings
        fixes = [
            # Fix line 253 - title string
            (r"title: 'Choose your agent's brain',", r"title: 'Choose your agent\\'s brain',"),
            # Fix line 1073 - tooltip string  
            (r"tooltip: 'Choose your agent's personality and communication style, or write custom instructions for advanced users.',", 
             r"tooltip: 'Choose your agent\\'s personality and communication style, or write custom instructions for advanced users.',"),
            # Fix line 1154 - Text content string
            (r"'We'll create the perfect instructions for your agent based on these choices',", 
             r"'We\\'ll create the perfect instructions for your agent based on these choices',"),
        ]
        
        for old, new in fixes:
            content = content.replace(old, new)
        
        # Also fix any other instances of unescaped apostrophes in strings
        content = re.sub(r"'([^']*[a-zA-Z]+)'(s|ll|re|ve|d)\s", r"'\1\\'\\2 ", content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {file_path}")
        else:
            print("No changes needed")
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_agent_config_errors()