#!/usr/bin/env python3

import os
import re

def fix_import_paths():
    # List of files to fix (from the find command output)
    files_to_fix = [
        "apps/desktop/lib/core/services/default_mcp_setup.dart",
        "apps/desktop/lib/core/services/detection_configuration_service.dart",
        "apps/desktop/lib/core/services/integration_backup_service.dart",
        "apps/desktop/lib/core/services/integration_installation_service.dart",
        "apps/desktop/lib/core/services/integration_templates_service.dart",
        "apps/desktop/lib/core/services/integration_testing_service.dart",
        "apps/desktop/lib/core/services/mcp_registry.dart",
        "apps/desktop/lib/core/services/mcp_template_service.dart",
        "apps/desktop/lib/features/agent_wizard/models/agent_wizard_state.dart",
        "apps/desktop/lib/features/settings/presentation/screens/settings_screen.dart",
        "apps/desktop/lib/features/settings/presentation/tabs/mcp_servers_tab.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/custom_mcp_server_modal.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/enhanced_integrations_tab.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/enhanced_mcp_dashboard.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/enhanced_mcp_server_wizard.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/integration_center/integration_cards_grid.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/manual_mcp_server_modal.dart",
        "apps/desktop/lib/features/settings/presentation/widgets/mcp_server_dialog.dart",
    ]
    
    for file_path in files_to_fix:
        try:
            # Determine correct path based on file location
            if "/core/services/" in file_path:
                correct_import = "import '../models/mcp_server_config.dart';"
            elif "/features/" in file_path:
                # Count directory levels to determine correct path
                parts = file_path.split("/")
                # Find index of 'features'
                features_idx = parts.index("features") if "features" in parts else -1
                if features_idx != -1:
                    # Count how many levels down from features
                    levels_down = len(parts) - features_idx - 2  # -2 for lib and features
                    prefix = "../" * (levels_down + 1)  # +1 to get out of features
                    correct_import = f"import '{prefix}core/models/mcp_server_config.dart';"
                else:
                    continue
            else:
                continue
                
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace the wrong import
            old_import = "import '../core/models/mcp_server_config.dart';"
            if old_import in content:
                new_content = content.replace(old_import, correct_import)
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                    
                print(f"Fixed: {file_path}")
                print(f"  Changed: {old_import}")
                print(f"  To:      {correct_import}")
            
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_import_paths()