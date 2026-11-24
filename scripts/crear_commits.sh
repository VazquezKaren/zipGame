#!/usr/bin/env bash
# Ejecutar una sola vez desde Terminal. --preview muestra los grupos sin escribir.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

mode="${1:-create}"
if [[ "$#" -gt 1 || ( "$mode" != create && "$mode" != --preview ) ]]; then
  printf 'Uso: bash scripts/crear_commits.sh [--preview]\n' >&2
  exit 1
fi

if [[ "$mode" == create ]]; then
  # Evitar mezclar este historial inicial con un repositorio existente.
  if [[ -e .git ]] || git rev-parse --git-dir >/dev/null 2>&1; then
    printf 'Ya existe un repositorio. Revisa git status antes de crear otros commits.\n' >&2
    exit 1
  fi
  for project in zip_game_api zip_game; do
    if [[ -e "$project/.git" ]]; then
      printf 'Hay un repositorio anidado en %s; revisa su historial primero.\n' "$project" >&2
      exit 1
    fi
  done
  if ! git var GIT_AUTHOR_IDENT >/dev/null 2>&1; then
    printf 'Configura tu identidad de Git (user.name y user.email) antes de continuar.\n' >&2
    exit 1
  fi
  git init -b main
fi

commit_group() {
  local message="$1"
  shift
  printf '\n%s\n' "$message"
  if [[ "$mode" == --preview ]]; then
    printf '  %s\n' "$@"
  else
    git add -- "$@"
    git diff --cached --stat
    git commit -m "$message"
  fi
}

commit_group 'chore(repo): configurar exclusiones y preparación del historial' \
  .gitignore scripts/crear_commits.sh

commit_group 'feat(api): implementar API de ZIP Game con persistencia y pruebas' \
  zip_game_api/.editorconfig zip_game_api/.env.example zip_game_api/.gitignore \
  zip_game_api/ace.js zip_game_api/adonisrc.ts zip_game_api/eslint.config.js \
  zip_game_api/package.json zip_game_api/package-lock.json zip_game_api/tsconfig.json \
  zip_game_api/app zip_game_api/bin zip_game_api/config zip_game_api/database \
  zip_game_api/start zip_game_api/tests

commit_group 'feat(app): implementar cliente Flutter con tablero y pruebas' \
  zip_game/.gitignore zip_game/.metadata zip_game/analysis_options.yaml \
  zip_game/pubspec.yaml zip_game/pubspec.lock \
  zip_game/android zip_game/web zip_game/lib zip_game/test

commit_group 'docs: documentar instalación, API y ajustes de la práctica' \
  README.md AJUSTES_IMPLEMENTACION.md zip_game/README.md \
  evidencias/API_DOCUMENTATION.md migraciones_kit_respaldo \
  'Practica_ZIP_Game_Alumnos (1).pdf'

commit_group 'docs(evidencias): agregar capturas y resultados de pruebas' \
  evidencias/capturas_app evidencias/peticionesEvidencias \
  zip_game_api/evidencias_backend.txt zip_game/evidencias_flutter.txt

if [[ "$mode" == create ]]; then
  printf '\nHistorial creado:\n'
  git log --oneline --reverse
  printf '\nEstado final (vacío significa limpio):\n'
  git status --short
fi
