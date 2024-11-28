# updater.py
import os
import git
import logging

def update_mods():
    try:
        repo_path = os.path.dirname(os.path.realpath(__file__))
        repo = git.Repo(repo_path)
        
        logging.info("Verificando actualizaciones...")
        origin = repo.remotes.origin
        origin.pull()
        logging.info("Mods actualizados.")
    except Exception as e:
        logging.error(f"Error al actualizar: {str(e)}")

if __name__ == "__main__":
    logging.basicConfig(filename='updater.log', level=logging.INFO)
    update_mods()