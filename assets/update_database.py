import json
import os

def update_database():
    # Read the existing database
    file_path = 'clinical_experience_database_clean.json'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Debug: Print structure to understand JSON format
    print("Keys in the root object:", list(data.keys()))
    if 'parts' in data:
        print("Number of parts:", len(data['parts']))
        print("First part keys:", list(data['parts'][0].keys()))
    
    # Find the General Surgery part
    general_surgery_part = None
    for part in data.get('parts', []):
        if part.get('part_name') == 'General Surgery':
            general_surgery_part = part
            break
    
    if general_surgery_part and 'cases' in general_surgery_part:
        # Add the new General Surgery procedures at the beginning
        new_procedures = [
            {
                "name": "esophagogastroduodenoscopy (EGD)",
                "physical_status": "ASA II",
                "position": "Left Lateral Decubitus",
                "anatomical_category": "Intra-abdominal",
                "anesthesia_type": "Monitored Anesthesia Care (MAC)",
                "anesthesia_procedures": "IV sedation"
            },
            {
                "name": "Colonoscopy",
                "physical_status": "ASA II",
                "position": "Left Lateral Decubitus",
                "anatomical_category": "Intra-abdominal",
                "anesthesia_type": "Monitored Anesthesia Care (MAC)",
                "anesthesia_procedures": "IV sedation"
            },
            {
                "name": "Colonoscopy & esophagogastroduodenoscopy (EGD)",
                "physical_status": "ASA II",
                "position": "Left Lateral Decubitus",
                "anatomical_category": "Intra-abdominal",
                "anesthesia_type": "Monitored Anesthesia Care (MAC)",
                "anesthesia_procedures": "IV sedation"
            },
            {
                "name": "Percutaneous Endoscopic Gastrostomy (PEG) Tube",
                "physical_status": "ASA II",
                "position": "Supine",
                "anatomical_category": "Intra-abdominal",
                "anesthesia_type": "Monitored Anesthesia Care (MAC)",
                "anesthesia_procedures": "IV sedation"
            }
        ]
        
        # Insert at the beginning
        general_surgery_part['cases'] = new_procedures + general_surgery_part['cases']
        print("Added 4 new General Surgery procedures")
    else:
        print("Could not find General Surgery part or it doesn't have 'cases'")
    
    # Find the Cardiac Surgery part
    cardiac_surgery_part = None
    for part in data.get('parts', []):
        if part.get('part_name') == 'Cardiac Surgery':
            cardiac_surgery_part = part
            break
    
    if cardiac_surgery_part and 'cases' in cardiac_surgery_part:
        # Add the new TEE procedure at the beginning
        cardiac_tee_procedure = {
            "name": "Transesophageal Echocardiogram (TEE)",
            "physical_status": "ASA III",
            "position": "Supine",
            "anatomical_category": "Heart: Closed Heart",
            "anesthesia_type": "Monitored Anesthesia Care (MAC)",
            "anesthesia_procedures": "IV sedation, transesophageal echocardiography (TEE)"
        }
        
        cardiac_surgery_part['cases'].insert(0, cardiac_tee_procedure)
        print("Added TEE procedure to Cardiac Surgery")
    else:
        print("Could not find Cardiac Surgery part or it doesn't have 'cases'")
    
    # Find and modify the Cardiac Ablation Surgery
    ablation_found = False
    for part in data.get('parts', []):
        if 'cases' not in part:
            continue
            
        for i, case in enumerate(part['cases']):
            if case.get('name') == 'Cardiac Ablation Surgery':
                # Replace with AFib Ablation
                part['cases'][i]['name'] = 'Atrial Fibrillation (AFib) Ablation'
                
                # Add the other two ablation types
                a_flutter_case = dict(part['cases'][i])
                a_flutter_case['name'] = 'Atrial Flutter (A Flutter) Ablation'
                
                svt_case = dict(part['cases'][i])
                svt_case['name'] = 'Supraventricular Tachycardia (SVT) Ablation'
                
                part['cases'].insert(i+1, a_flutter_case)
                part['cases'].insert(i+2, svt_case)
                ablation_found = True
                print("Modified Cardiac Ablation Surgery to AFib, A Flutter, and SVT ablations")
                break
                
        if ablation_found:
            break
    
    if not ablation_found:
        print("Could not find Cardiac Ablation Surgery")
    
    # Find and modify the Tibial Plateau Fracture Repair
    fracture_found = False
    for part in data.get('parts', []):
        if 'cases' not in part:
            continue
            
        for i, case in enumerate(part['cases']):
            if case.get('name') == 'Tibial Plateau Fracture Repair':
                # Replace with ORIF version
                part['cases'][i]['name'] = 'Open Reduction Internal Fixation (ORIF) Tibial Plateau Fracture Repair'
                fracture_found = True
                print("Modified Tibial Plateau Fracture Repair")
                break
                
        if fracture_found:
            break
    
    if not fracture_found:
        print("Could not find Tibial Plateau Fracture Repair")
    
    # Write the updated database
    with open('clinical_experience_database_clean_updated.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)
    
    print("Database updated successfully. Saved as 'clinical_experience_database_clean_updated.json'")

if __name__ == "__main__":
    # Change to the assets directory if needed
    if not os.path.exists('clinical_experience_database_clean.json'):
        os.chdir('assets')
    update_database() 