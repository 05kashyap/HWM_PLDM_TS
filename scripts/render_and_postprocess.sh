#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/render_and_postprocess.sh [SOURCE_DATA_PATH] [OUTPUT_ROOT] [WORKERS]
# Default SOURCE_DATA_PATH: pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps
# Default OUTPUT_ROOT: /media/shanveen-ortho-clinic/datadrv1/maze2d_large_diverse_25maps
# Default WORKERS: 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DATA_PATH="${1:-$REPO_ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps}"
OUTPUT_ROOT="${2:-/media/shanveen-ortho-clinic/datadrv1/maze2d_large_diverse_25maps}"
WORKERS="${3:-4}"
PYTHON_BIN="${PYTHON_BIN:-}"
RENDER_SCRIPT="$REPO_ROOT/pldm_envs/diverse_maze/data_generation/render_data.py"
POSTPROCESS_SCRIPT="$REPO_ROOT/pldm_envs/diverse_maze/data_generation/postprocess_images.py"
SOURCE_IMAGES_DIR="$SOURCE_DATA_PATH/images"
OUTPUT_IMAGES_DIR="$OUTPUT_ROOT/images"
LOG_DIR="$OUTPUT_ROOT/render_logs"

echo "Source data path: $SOURCE_DATA_PATH"
echo "Output root: $OUTPUT_ROOT"
echo "Workers: $WORKERS"

mount_source="$(findmnt -n -o SOURCE -T "$OUTPUT_ROOT" 2>/dev/null || true)"
mount_target="$(findmnt -n -o TARGET -T "$OUTPUT_ROOT" 2>/dev/null || true)"
if [ -z "$mount_source" ] || [ "$mount_target" != /media/shanveen-ortho-clinic/datadrv1 ]; then
  echo "Error: OUTPUT_ROOT must live on the external drive mounted at /media/shanveen-ortho-clinic/datadrv1."
  echo "Current mount target: ${mount_target:-<none>}"
  echo "Current source: ${mount_source:-<none>}"
  exit 1
fi

export MUJOCO_GL="${MUJOCO_GL:-egl}"
export MUJOCO_PY_MUJOCO_PATH="${MUJOCO_PY_MUJOCO_PATH:-$HOME/.mujoco/mujoco-2.1.2}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/lib/nvidia:/usr/lib/x86_64-linux-gnu/nvidia:$MUJOCO_PY_MUJOCO_PATH/bin"
export D4RL_SUPPRESS_IMPORT_ERROR="${D4RL_SUPPRESS_IMPORT_ERROR:-1}"

if [ -z "$PYTHON_BIN" ]; then
  if command -v conda >/dev/null 2>&1 && conda env list | awk '{print $1}' | grep -qx pldm; then
    PYTHON_BIN="conda run -n pldm python"
  else
    PYTHON_BIN="python"
  fi
fi

echo "Python runner: $PYTHON_BIN"

mkdir -p "$OUTPUT_ROOT" "$LOG_DIR"

if [ -e "$SOURCE_IMAGES_DIR" ] && [ ! -L "$SOURCE_IMAGES_DIR" ]; then
  echo "Error: $SOURCE_IMAGES_DIR already exists and is not a symlink."
  echo "Move it aside first, or delete it if you want the images to live on the drive."
  exit 1
fi

mkdir -p "$OUTPUT_IMAGES_DIR"
ln -sfn "$OUTPUT_IMAGES_DIR" "$SOURCE_IMAGES_DIR"

chown -R "${USER}:${USER}" "$OUTPUT_ROOT" 2>/dev/null || true

echo "Starting $WORKERS render workers..."
declare -a pids
for i in $(seq 0 $((WORKERS-1))); do
  log="$LOG_DIR/worker_${i}.log"
  echo "Starting worker $i -> $log"
  $PYTHON_BIN "$RENDER_SCRIPT" \
    --data_path "$SOURCE_DATA_PATH" --workers_num "$WORKERS" --worker_id "$i" \
    > "$log" 2>&1 &
  pids[$i]=$!
done

echo "Waiting for workers to finish..."
for pid in "${pids[@]}"; do
  wait "$pid"
done

echo "All workers finished. Postprocessing images..."
post_log="$LOG_DIR/postprocess.log"
$PYTHON_BIN "$POSTPROCESS_SCRIPT" --data_path "$SOURCE_DATA_PATH" --save_path "$OUTPUT_ROOT" > "$post_log" 2>&1

echo "Postprocess finished. Summary:" 
echo "- logs: $LOG_DIR"
echo -n "- png count: " && find "$OUTPUT_IMAGES_DIR" -type f -name '*.png' 2>/dev/null | wc -l
if [ -f "$OUTPUT_ROOT/images.npy" ]; then
  $PYTHON_BIN - <<PY
import numpy as np
import os
p='''$OUTPUT_ROOT/images.npy'''
try:
    a=np.load(p, mmap_mode='r')
    print('- images.npy shape:', a.shape)
except Exception as e:
    print('- images.npy exists but failed to load:', e)
PY
else
  echo "- images.npy not found"
fi

echo "Done. If you want, run L2 training/eval with the source dataset path $SOURCE_DATA_PATH and point image consumers at $OUTPUT_ROOT."
