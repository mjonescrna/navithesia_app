import json
import re

def fix_json_file(input_path, output_path):
    # Read the input file using utf-8-sig to handle BOM
    with open(input_path, 'r', encoding='utf-8-sig') as file:
        content = file.read()
    
    # Fix the problematic characters
    fixed_content = content
    
    # Replace fancy quotes with regular quotes
    fancy_quotes = ['\u201c', '\u201d', '\u2018', '\u2019'] # Unicode values for fancy quotes
    for quote in fancy_quotes:
        fixed_content = fixed_content.replace(quote, '"')
    
    # Fix common problematic patterns
    fixed_content = fixed_content.replace('IIâ€"III', 'II-III')
    fixed_content = fixed_content.replace('â€"', '-')  # Replace encoded dash
    fixed_content = fixed_content.replace('â€', '"')   # Replace encoded quotes
    fixed_content = fixed_content.replace('II""III', 'II-III')  # Direct fix
    
    # Manual fix for erroneous chars
    fixed_content = fixed_content.replace('€"', '-')
    fixed_content = fixed_content.replace('€', '-')
    
    # Fix specific problematic string
    fixed_content = fixed_content.replace('"ASA II"', '"ASA II-')
    fixed_content = fixed_content.replace('"III",', 'III",')
    
    # Explicitly fix the most problematic part based on line info
    problematic_pattern = '"physical_status": "ASA II""III"'
    fixed_pattern = '"physical_status": "ASA II-III"'
    fixed_content = fixed_content.replace(problematic_pattern, fixed_pattern)
    
    # Manual approach - save the content first with the replacements
    with open('temp_fixed.json', 'w', encoding='utf-8') as file:
        file.write(fixed_content)
    print("Saved temporary fixed content to temp_fixed.json")
    
    # Try a different approach if the automatic fixes don't work
    try:
        # Try to manually clean the JSON with a regex-based approach
        fixed_content = re.sub(r'([A-Z]+) ([IV]+)"+"([IV]+)', r'\1 \2-\3', fixed_content)
        
        # Try to parse the JSON
        try:
            json_data = json.loads(fixed_content)
            print("JSON is valid after fixes")
            
            # Save the fixed content
            with open(output_path, 'w', encoding='utf-8') as file:
                json.dump(json_data, file, ensure_ascii=False, indent=2)
            print(f"Fixed JSON saved to {output_path}")
            
        except json.JSONDecodeError as e:
            print(f"JSON is still invalid after fixes: {e}")
            print(f"Error at line {e.lineno}, column {e.colno}")
            
            # Show more information about the error
            lines = fixed_content.split('\n')
            if e.lineno <= len(lines):
                problematic_line = lines[e.lineno-1]
                print(f"Problematic line: {problematic_line}")
                if e.colno <= len(problematic_line):
                    # Get 10 characters before and after the error
                    start_pos = max(0, e.colno - 10)
                    end_pos = min(len(problematic_line), e.colno + 10)
                    char_slice = problematic_line[start_pos:end_pos]
                    print(f"Characters around error: '{char_slice}'")
                    if e.colno <= len(problematic_line):
                        print(f"Character at error: '{problematic_line[e.colno-1]}' (ord: {ord(problematic_line[e.colno-1])})")
                    
                    position_marker = ' ' * (e.colno-1) + '^'
                    print(f"Position: {position_marker}")
                    
                    # Show a bit more context
                    start = max(0, e.lineno - 3)
                    end = min(len(lines), e.lineno + 3)
                    
                    print("\nContext:")
                    for i in range(start, end):
                        line_num = i + 1
                        prefix = "-> " if line_num == e.lineno else "   "
                        print(f"{prefix}{line_num}: {lines[i]}")
                        
            # Handle the error with a brute force approach - edit the problematic lines directly
            print("\nTrying brute force approach...")
            with open(input_path, 'r', encoding='utf-8-sig') as file:
                lines = file.readlines()
            
            # Fix line 8 specifically (based on previous error reports)
            if len(lines) >= 8:
                lines[7] = '          "physical_status": "ASA II-III",\n'
                print("Fixed line 8 explicitly")
            
            # Write the manually fixed content
            with open('manual_fixed.json', 'w', encoding='utf-8') as file:
                file.writelines(lines)
            
            # Try to parse the manually fixed content
            try:
                with open('manual_fixed.json', 'r', encoding='utf-8') as file:
                    manual_content = file.read()
                json_data = json.loads(manual_content)
                print("JSON is valid after manual fix")
                
                # Save the fixed content
                with open(output_path, 'w', encoding='utf-8') as file:
                    json.dump(json_data, file, ensure_ascii=False, indent=2)
                print(f"Fixed JSON saved to {output_path}")
                
            except json.JSONDecodeError as e2:
                print(f"JSON is still invalid after manual fix: {e2}")
    
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    input_path = 'clinical_experience_database_fixed.json'
    output_path = 'clinical_experience_database_clean.json'
    fix_json_file(input_path, output_path) 