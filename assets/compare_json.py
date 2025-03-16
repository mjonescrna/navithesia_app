import json
import os

def count_cases(json_file):
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        total_cases = 0
        case_names = []
        
        for part in data.get('parts', []):
            cases = part.get('cases', [])
            total_cases += len(cases)
            for case in cases:
                if 'name' in case:
                    case_names.append(case['name'])
        
        return total_cases, case_names
    except Exception as e:
        print(f"Error processing {json_file}: {e}")
        return 0, []

def merge_json_files(file1, file2, output_file):
    try:
        # Load both files
        with open(file1, 'r', encoding='utf-8') as f1:
            data1 = json.load(f1)
        
        with open(file2, 'r', encoding='utf-8') as f2:
            data2 = json.load(f2)
        
        # Create a merged structure
        merged_data = {"parts": []}
        
        # Create a dictionary to track parts by name
        parts_dict = {}
        
        # Process parts from first file
        for part in data1.get('parts', []):
            part_name = part.get('part_name')
            if part_name:
                parts_dict[part_name] = {"part_name": part_name, "cases": []}
                # Add all cases from this part
                for case in part.get('cases', []):
                    parts_dict[part_name]['cases'].append(case)
        
        # Process parts from second file
        for part in data2.get('parts', []):
            part_name = part.get('part_name')
            if part_name:
                # If part doesn't exist in merged data, create it
                if part_name not in parts_dict:
                    parts_dict[part_name] = {"part_name": part_name, "cases": []}
                
                # Check for new cases
                existing_case_names = [case.get('name') for case in parts_dict[part_name]['cases'] if 'name' in case]
                for case in part.get('cases', []):
                    case_name = case.get('name')
                    if case_name and case_name not in existing_case_names:
                        parts_dict[part_name]['cases'].append(case)
                        existing_case_names.append(case_name)
        
        # Convert dictionary to list for final output
        merged_data['parts'] = list(parts_dict.values())
        
        # Write merged data to output file
        with open(output_file, 'w', encoding='utf-8') as out:
            json.dump(merged_data, out, indent=4)
        
        print(f"Successfully created merged file: {output_file}")
        return True
    except Exception as e:
        print(f"Error merging files: {e}")
        return False

# Main execution
if __name__ == "__main__":
    base_path = os.path.dirname(os.path.abspath(__file__))
    
    file1 = os.path.join(base_path, "clinical_experience_database_clean.json")
    file2 = os.path.join(base_path, "clinical_experience_database_clean_updated.json")
    output_file = os.path.join(base_path, "clinical_experience_database_unified.json")
    
    # Count cases in both files
    count1, names1 = count_cases(file1)
    count2, names2 = count_cases(file2)
    
    print(f"File 1 ({file1}) contains {count1} cases")
    print(f"File 2 ({file2}) contains {count2} cases")
    
    # Find unique cases in each file
    unique_to_file1 = set(names1) - set(names2)
    unique_to_file2 = set(names2) - set(names1)
    
    print(f"Cases unique to File 1: {len(unique_to_file1)}")
    if unique_to_file1:
        print("Examples:", list(unique_to_file1)[:5])
    
    print(f"Cases unique to File 2: {len(unique_to_file2)}")
    if unique_to_file2:
        print("Examples:", list(unique_to_file2)[:5])
    
    # Merge the files
    success = merge_json_files(file1, file2, output_file)
    
    if success:
        # Verify the merged file
        count_merged, _ = count_cases(output_file)
        print(f"Merged file contains {count_merged} cases")
        print(f"Expected: {len(set(names1).union(set(names2)))} cases") 