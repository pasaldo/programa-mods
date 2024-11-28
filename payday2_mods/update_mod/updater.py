# updater.py

import json
import requests
import os
import base64
import zipfile
import sys

# Configura estos valores
GITHUB_USER = "pasaldo"
GITHUB_REPO = "programa-mods"
GITHUB_BRANCH = "main"
MODS_JSON_PATH = "payday2_mods/update_mod/mods.json"
PAYDAY2_MODS_PATH = "../../"

def get_remote_mods():
    url = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/contents/{MODS_JSON_PATH}?ref={GITHUB_BRANCH}"
    response = requests.get(url)
    if response.status_code == 200:
        content = response.json()['content']
        decoded_content = base64.b64decode(content).decode('utf-8')
        return json.loads(decoded_content)
    return []

def get_local_mods():
    local_json_path = os.path.join(os.path.dirname(__file__), "mods.json")
    if os.path.exists(local_json_path):
        with open(local_json_path, 'r') as f:
            return json.load(f)
    return []

def compare_mods(local_mods, remote_mods):
    local_mod_names = [mod['name'] for mod in local_mods]
    return [mod for mod in remote_mods if mod['name'] not in local_mod_names]

def download_mod(mod):
    zip_url = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/contents/payday2_mods/update_mod/mods/{mod['name']}.zip?ref={GITHUB_BRANCH}"
    response = requests.get(zip_url)
    if response.status_code == 200:
        zip_content = response.json()['content']
        decoded_zip = base64.b64decode(zip_content)
        
        temp_zip_path = os.path.join(os.path.dirname(__file__), f"temp_{mod['name']}.zip")
        with open(temp_zip_path, 'wb') as f:
            f.write(decoded_zip)
        
        mod_path = os.path.join(PAYDAY2_MODS_PATH, mod['name'])
        with zipfile.ZipFile(temp_zip_path, 'r') as zip_ref:
            zip_ref.extractall(mod_path)
        
        os.remove(temp_zip_path)

def check_for_updates():
    remote_mods = get_remote_mods()
    local_mods = get_local_mods()
    mods_to_update = compare_mods(local_mods, remote_mods)
    return len(mods_to_update) > 0

def update_mods():
    remote_mods = get_remote_mods()
    local_mods = get_local_mods()
    mods_to_update = compare_mods(local_mods, remote_mods)
    
    for mod in mods_to_update:
        download_mod(mod)
    
    local_json_path = os.path.join(os.path.dirname(__file__), "mods.json")
    os.makedirs(os.path.dirname(local_json_path), exist_ok=True)
    with open(local_json_path, 'w') as f:
        json.dump(remote_mods, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "check":
            if check_for_updates():
                sys.exit(0)  # Updates available
            else:
                sys.exit(1)  # No updates
        elif sys.argv[1] == "download":
            update_mods()
    else:
        print("Usage: python updater.py [check|download]")