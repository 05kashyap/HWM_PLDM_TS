# This file downloads the original datasets and render them

# Auto-detect project root based on this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DIVERSE_MAZE_ROOT="${PROJECT_ROOT}/pldm_envs/diverse_maze"
DATASETS_DIR="${DIVERSE_MAZE_ROOT}/datasets"

# Download datasets from HF into pldm_envs/diverse_maze/datasets.
python "${DIVERSE_MAZE_ROOT}/data_generation/download_ds_from_hf.py" \
    --out-dir "${DATASETS_DIR}"

DATA_PATHS=(
    "${DATASETS_DIR}/maze2d_large_diverse_25maps"
    "${DATASETS_DIR}/maze2d_large_diverse_probe"
)

# render the datasets. save images as numpy
for DATA_PATH in "${DATA_PATHS[@]}"; do
    python "${DIVERSE_MAZE_ROOT}/data_generation/render_data.py" --data_path "$DATA_PATH"
    python "${DIVERSE_MAZE_ROOT}/data_generation/postprocess_images.py" --data_path "$DATA_PATH"
done
