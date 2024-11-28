# Nombre del archivo: updater.py

import json
import requests
import os
import base64
import zipfile

# Configura estos valores
GITHUB_USER = "pasaldo"
GITHUB_REPO = "programa-mods"
GITHUB_BRANCH = "main"  # o "master", dependiendo de tu configuración
MODS_JSON_PATH = "mods.json"
PAYDAY2_MODS_PATH = "../../"

def get_remote_mods():
    url = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/{MODS_JSON_PATH}?ref={GITHUB_BRANCH}"
    response = requests.get(url)
    if response.status_code == 200:
        content = response.json()['content']
        decoded_content = base64.b64decode(content).decode('utf-8')
        return json.loads(decoded_content)
    return []

def get_local_mods():
    local_json_path = os.path.join(os.path.dirname(__file__), MODS_JSON_PATH)
    if os.path.exists(local_json_path):
        with open(local_json_path, 'r') as f:
            return json.load(f)
    return []

def compare_mods(local_mods, remote_mods):
    local_mod_names = [mod['name'] for mod in local_mods]
    return [mod for mod in remote_mods if mod['name'] not in local_mod_names]

def download_mod(mod):
    print(f"Descargando {mod['name']}")
    
    # Construye la URL del archivo zip del mod
    zip_url = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/update_mod/mods/{mod['name']}.zip?ref={GITHUB_BRANCH}"
    
    # Descarga el archivo zip
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
        
        print(f"Mod {mod['name']} instalado correctamente")
    else:
        print(f"Error al descargar {mod['name']}")


def update_mods():
    remote_mods = get_remote_mods()
    local_mods = get_local_mods()
    mods_to_update = compare_mods(local_mods, remote_mods)
    
    for mod in mods_to_update:
        download_mod(mod)
    
    local_json_path = os.path.join(os.path.dirname(__file__), MODS_JSON_PATH)
    with open(local_json_path, 'w') as f:
        json.dump(remote_mods, f, indent=2)

if __name__ == "__main__":
    update_mods()