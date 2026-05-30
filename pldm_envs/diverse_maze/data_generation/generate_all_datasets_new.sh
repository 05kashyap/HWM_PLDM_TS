# This file generates new datasets for the large diverse maze environments

# Auto-detect project root based on this script location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DIVERSE_MAZE_ROOT="${PROJECT_ROOT}/pldm_envs/diverse_maze"
DATASETS_DIR="${DIVERSE_MAZE_ROOT}/datasets"
CONFIGS_DIR="${DIVERSE_MAZE_ROOT}/configs"

# Generate dataset for 25maps setting.
python "${DIVERSE_MAZE_ROOT}/data_generation/generate_data.py" \
    --output_path "${DATASETS_DIR}/maze2d_large_diverse_25maps" \
    --config "${CONFIGS_DIR}/maze2d_large/25maps.yaml"

# Generate dataset for OOD evaluation (probe) setting.
python "${DIVERSE_MAZE_ROOT}/data_generation/generate_data.py" \
    --output_path "${DATASETS_DIR}/maze2d_large_diverse_probe" \
    --config "${CONFIGS_DIR}/maze2d_large/probe.yaml" \
    --exclude_map_path "${DATASETS_DIR}/maze2d_large_diverse_25maps/train_maps.pt"

DATA_PATHS=(
    "${DATASETS_DIR}/maze2d_large_diverse_25maps"
    "${DATASETS_DIR}/maze2d_large_diverse_probe"
)

# render the datasets. save images as numpy
for DATA_PATH in "${DATA_PATHS[@]}"; do
    python "${DIVERSE_MAZE_ROOT}/data_generation/render_data.py" --data_path "$DATA_PATH"
    python "${DIVERSE_MAZE_ROOT}/data_generation/postprocess_images.py" --data_path "$DATA_PATH"
done

# Generate OOD evaluation trials for the 5 maps setting
python "${DIVERSE_MAZE_ROOT}/evaluation/generate_starts_targets.py" \
    --data_path "${DATASETS_DIR}/maze2d_large_diverse_probe"
