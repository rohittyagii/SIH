import os
import re

screens_dir = "/Users/rohittyagi/Desktop/SIH/lib/screens"

for filename in os.listdir(screens_dir):
    if filename.endswith(".dart"):
        filepath = os.path.join(screens_dir, filename)
        with open(filepath, "r") as f:
            content = f.read()
        
        # Only modify if it contains GestureDetector
        if "GestureDetector(" in content:
            # Replace GestureDetector with BouncyButton if it doesn't use onPanUpdate
            new_content = re.sub(r'GestureDetector\(', r'BouncyButton(', content)
            
            # If we replaced something, ensure the import is there
            if "BouncyButton(" in new_content and "bouncy_button.dart" not in new_content:
                # add import after the last import
                import_stmt = "import '../widgets/bouncy_button.dart';\n"
                
                lines = new_content.split('\n')
                last_import_idx = -1
                for i, line in enumerate(lines):
                    if line.startswith("import "):
                        last_import_idx = i
                
                if last_import_idx != -1:
                    lines.insert(last_import_idx + 1, import_stmt.strip())
                    new_content = '\n'.join(lines)
            
            with open(filepath, "w") as f:
                f.write(new_content)
                
print("Done!")
