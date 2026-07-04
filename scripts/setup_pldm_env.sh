#!/usr/bin/env bash
# Usage: source scripts/setup_pldm_env.sh [--rebuild]
# - Default: activate env, set env vars, patch native MuJoCo/mujoco_py files,
#   and create symlinks.
# - --rebuild: also clears mujoco_py cache and forces a rebuild.

# Ensure the script is sourced so env vars persist.
if ! (return 0 2>/dev/null); then
  echo "Please source this script: source scripts/setup_pldm_env.sh [--rebuild]"
  exit 1
fi

# Try to load conda if not already available.
if ! command -v conda >/dev/null 2>&1; then
  if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
  elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    . "$HOME/anaconda3/etc/profile.d/conda.sh"
  fi
fi

if command -v conda >/dev/null 2>&1; then
  conda activate "${PLDM_CONDA_ENV:-pldm}"
else
  echo "Warning: conda not found in PATH. Skipping conda activation."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUJOCO_DIR="${MUJOCO_PY_MUJOCO_PATH:-$HOME/.mujoco/mujoco-2.1.2}"
export MUJOCO_GL=egl
export MUJOCO_PY_MUJOCO_PATH="$MUJOCO_DIR"
export D4RL_SUPPRESS_IMPORT_ERROR=1

# Add a path to LD_LIBRARY_PATH if missing.
_add_to_ld_path() {
  if [ -d "$1" ]; then
    case ":${LD_LIBRARY_PATH:-}:" in
      *":$1:"*) : ;; # already present
      *) export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:$1" ;;
    esac
  fi
}

_add_to_ld_path "$MUJOCO_DIR/bin"
_add_to_ld_path "/usr/lib/nvidia"

# Ensure expected MuJoCo/GLEW symlinks exist for mujoco_py.
if [ -d "$MUJOCO_DIR/bin" ]; then
  ln -sf ../lib/libmujoco.so "$MUJOCO_DIR/bin/libmujoco210.so"
  ln -sf ../lib/libglewegl.so "$MUJOCO_DIR/bin/libglewegl.so"
fi

if [ -f "$SCRIPT_DIR/patch_mujoco_py_212.sh" ]; then
  PYTHON_BIN="${PYTHON_BIN:-python}" "$SCRIPT_DIR/patch_mujoco_py_212.sh"
fi

if [ "${1-}" = "--rebuild" ]; then
  rm -rf "$HOME/.cache/mujoco_py"
  MUJOCO_PY_FORCE_REBUILD=1 python -c "import mujoco_py"
fi
