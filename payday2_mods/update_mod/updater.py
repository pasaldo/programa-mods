# Nombre del archivo: updater.py

import json
import requests
import os
import shutil
import zipfile

# Configura estos valores
GITHUB_USER = "pasaldo"
GITHUB_REPO = "programa-mods"
GITHUB_BRANCH = "main"  # o "master", dependiendo de tu configuración
MODS_JSON_PATH = "update_mod/mod.json"
PAYDAY2_MODS_PATH = "../PAYDAY2/mods"

def get_remote_mods():
    url = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/{MODS_JSON_PATH}?ref={GITHUB_BRANCH}"
    response = requests.get(url)
    if response.status_code == 200:
        content = response.json()['content']
        import base64
        decoded_content = base64.b64decode(content).decode('utf-8')
        return json.loads(decoded_content)
    return []

def get_local_mods():
    if os.path.exists(MODS_JSON_PATH):
        with open(MODS_JSON_PATH, 'r') as f:
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
        import base64
        decoded_zip = base64.b64decode(zip_content)
        
        # Guarda el archivo zip temporalmente
        temp_zip_path = f"temp_{mod['name']}.zip"
        with open(temp_zip_path, 'wb') as f:
            f.write(decoded_zip)
        
        # Extrae el contenido del zip en la carpeta de mods de Payday 2
        with zipfile.ZipFile(temp_zip_path, 'r') as zip_ref:
            zip_ref.extractall(os.path.join(PAYDAY2_MODS_PATH, mod['name']))
        
        # Elimina el archivo zip temporal
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
    
    # Actualiza el archivo JSON local
    with open(MODS_JSON_PATH, 'w') as f:
        json.dump(remote_mods, f, indent=2)

if __name__ == "__main__":
    update_mods()