#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e 

export WANDB_MODE=disabled

# ==========================================
# SHARED ENVIRONMENT VARIABLES
# ==========================================
ROOT=/home/shanveen-ortho-clinic/Documents/Projects/worldmodels/HWM_PLDM_TS
TRAIN_DATA_ROOT="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps"

TRAIN_DATA_PATH="$TRAIN_DATA_ROOT/data.p"
TRAIN_IMAGES_PATH="$TRAIN_DATA_ROOT/images.npy"
PROBE_DATA_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/data.p"
PROBE_IMAGES_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/images.npy"

# Navigate to project code
cd "$ROOT/pldm"

# ==========================================
# STAGE 1: BASELINE L2 TRAINING (10 Epochs)
# ==========================================
echo "=========================================="
echo "STAGE 1: Starting L2 Baseline Training..."
echo "=========================================="

# Isolate the baseline L2 experiment outputs
L2_BASELINE_EXPERIMENT_ROOT="$ROOT/baseline_l2"
mkdir -p "$L2_BASELINE_EXPERIMENT_ROOT"

# Define where your finished Baseline L1 checkpoint lives
L1_BASELINE_CKPT="$ROOT/checkpoint/maze2d_large_diverse/maze2d_large_diverse/epoch=10_sample_step=6599296.ckpt"

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
  --values root_path="$ROOT" output_root="$L2_BASELINE_EXPERIMENT_ROOT" base_lr=0.0003 \
  data.d4rl_config.batch_size=512 epochs=10 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  hjepa.level2.backbone.arch=mlp \
  hjepa.level2.backbone.backbone_norm=layer_norm \
  hjepa.level2.backbone.backbone_subclass=512-512 \
  hjepa.level2.predictor.predictor_arch=mlp \
  hjepa.level2.predictor.predictor_subclass=512-512 \
  objectives_l2.objectives='[PredictionObs]' \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  load_checkpoint_path="$L1_BASELINE_CKPT" load_l1_only=true \
  wandb=false data.d4rl_config.crop_length=1000000 data.num_workers=0

# ==========================================
# STAGE 2: TEMPORAL STRAIGHTENING L2 TRAINING (10 Epoch)
# ==========================================
echo "=========================================="
echo "STAGE 2: Starting L2 Training with Temporal Straightening..."
echo "=========================================="

# Isolate the experiment outputs
TS_EXPERIMENT_ROOT="$ROOT/temporal_straightening_l2"
mkdir -p "$TS_EXPERIMENT_ROOT"

# Define where your finished TS L1 checkpoint lives
L1_TS_CKPT="$ROOT/temporal_straightening_l1/maze2d_large_diverse/epoch=10_sample_step=6599296.ckpt" # <-- UPDATE THIS PATH


python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
  --values root_path="$ROOT" output_root="$TS_EXPERIMENT_ROOT" base_lr=0.0003 \
  data.d4rl_config.batch_size=512 epochs=10 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs,TemporalStraighteningObs]' \
  objectives_l1.idm.arch=512-512 \
  objectives_l1.temporal_straightening_obs.curv_coeff=0.1 \
  hjepa.level2.backbone.arch=mlp \
  hjepa.level2.backbone.backbone_norm=layer_norm \
  hjepa.level2.backbone.backbone_subclass=512-512 \
  hjepa.level2.predictor.predictor_arch=mlp \
  hjepa.level2.predictor.predictor_subclass=512-512 \
  objectives_l2.objectives='[PredictionObs,TemporalStraighteningObs]' \
  objectives_l2.temporal_straightening_obs.curv_coeff=0.1 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  load_checkpoint_path="$L1_TS_CKPT" load_l1_only=true \
  wandb=false data.d4rl_config.crop_length=1000000 data.num_workers=0

echo "=========================================="
echo "All L2 experiments completed successfully!"
echo "=========================================="