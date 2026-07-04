#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e 

export WANDB_MODE=disabled

# ==========================================
# SHARED ENVIRONMENT VARIABLES
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRAIN_DATA_ROOT="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps"

TRAIN_DATA_PATH="$TRAIN_DATA_ROOT/data.p"
TRAIN_IMAGES_PATH="$TRAIN_DATA_ROOT/images.npy"
PROBE_DATA_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/data.p"
PROBE_IMAGES_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/images.npy"

# Navigate to project code
cd "$ROOT/pldm"


# ==========================================
# STAGE 1: BASELINE L1 TRAINING (10 Epochs)
# ==========================================
echo "=========================================="
echo "STAGE 1: Starting L1 Baseline Training..."
echo "=========================================="

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" base_lr=0.0003 data.d4rl_config.batch_size=128 epochs=10 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  objectives_l1.vicreg_obs.projector=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  wandb=false data.d4rl_config.crop_length=600000 data.num_workers=0


# ==========================================
# STAGE 2: TEMPORAL STRAIGHTENING L1 TRAINING (10 Epoch)
# ==========================================
echo "=========================================="
echo "STAGE 2: Starting L1 Training with Temporal Straightening..."
echo "=========================================="

# Isolate the experiment outputs
TS_EXPERIMENT_ROOT="$ROOT/temporal_straightening_l1"
mkdir -p "$TS_EXPERIMENT_ROOT"

# Since we override output_root, train.py appends output_dir ("maze2d_large_diverse")
TS_L1_DIR="$TS_EXPERIMENT_ROOT/maze2d_large_diverse"

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" output_root="$TS_EXPERIMENT_ROOT" base_lr=0.0003 \
  data.d4rl_config.batch_size=128 epochs=10 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs,TemporalStraighteningObs]' \
  objectives_l1.temporal_straightening_obs.curv_coeff=0.1 \
  objectives_l1.idm.arch=512-512 \
  objectives_l1.vicreg_obs.projector=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  wandb=false data.d4rl_config.crop_length=600000 data.num_workers=0

echo "=========================================="
echo "All experiments completed successfully!"
echo "=========================================="
