#!/usr/bin/env bash
set -euo pipefail

export WANDB_MODE=disabled

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SMOKE_ROOT="$ROOT/checkpoint/maze2d_large_diverse_smoke"
L1_DIR="$SMOKE_ROOT/maze2d_large_diverse"
L2_DIR="$SMOKE_ROOT/l2_wo_encoder/maze2d_large_diverse"

cd "$ROOT/pldm"

# Smoke test: short sequences, one epoch, one batch, and lightweight eval.
python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" base_lr=0.001 \
  output_root="$SMOKE_ROOT" \
  data.d4rl_config.batch_size=128 \
  data.d4rl_config.crop_length=128 \
  data.d4rl_config.n_steps=4 \
  n_steps=4 \
  hjepa.l1_n_steps=4 \
  compile_model=false \
  epochs=1 \
  train_only=true \
  resume_if_possible=false \
  wandb=false \
  data.num_workers=0 \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
  --values root_path="$ROOT" base_lr=0.001 \
  output_root="$SMOKE_ROOT/l2_wo_encoder" \
  data.d4rl_config.batch_size=128 \
  data.d4rl_config.crop_length=128 \
  data.d4rl_config.n_steps=4 \
  data.d4rl_config.l2_step_skip=4 \
  data.d4rl_config.l2_n_steps=2 \
  n_steps=4 \
  hjepa.l1_n_steps=4 \
  l2_step_skip=4 \
  hjepa.step_skip=4 \
  compile_model=false \
  epochs=1 \
  train_only=true \
  resume_if_possible=false \
  wandb=false \
  data.num_workers=0 \
  eval_cfg.probing.epochs=1 \
  eval_cfg.probing.epochs_enc=1 \
  eval_cfg.probing.epochs_latent=1 \
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
  load_checkpoint_path="$L1_DIR" \
  load_l1_only=true \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
  --values root_path="$ROOT" base_lr=0.001 \
  output_root="$SMOKE_ROOT/l2_wo_encoder" \
  data.d4rl_config.batch_size=128 \
  data.d4rl_config.crop_length=128 \
  data.d4rl_config.n_steps=4 \
  data.d4rl_config.l2_step_skip=4 \
  data.d4rl_config.l2_n_steps=2 \
  n_steps=4 \
  hjepa.l1_n_steps=4 \
  l2_step_skip=4 \
  hjepa.step_skip=4 \
  compile_model=false \
  eval_only=true \
  resume_if_possible=false \
  wandb=false \
  data.num_workers=0 \
  eval_cfg.probing.epochs=1 \
  eval_cfg.probing.epochs_enc=1 \
  eval_cfg.probing.epochs_latent=1 \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  hjepa.level2.backbone.arch=mlp \
  hjepa.level2.backbone.backbone_subclass=512-512 \
  hjepa.level2.predictor.predictor_arch=mlp \
  hjepa.level2.predictor.predictor_subclass=512-512 \
  objectives_l2.objectives='[PredictionObs]' \
  load_l1_only=false \
  load_checkpoint_path="$L2_DIR" \
  eval_cfg.disable_planning=true \
  eval_cfg.disable_l2_planning=true \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" base_lr=0.001 \
  output_root="$SMOKE_ROOT" \
  data.d4rl_config.batch_size=128 \
  data.d4rl_config.crop_length=128 \
  data.d4rl_config.n_steps=4 \
  n_steps=4 \
  hjepa.l1_n_steps=4 \
  compile_model=false \
  eval_only=true \
  resume_if_possible=false \
  wandb=false \
  data.num_workers=0 \
  eval_cfg.probing.epochs=1 \
  eval_cfg.probing.epochs_enc=1 \
  eval_cfg.probing.epochs_latent=1 \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  load_checkpoint_path="$L1_DIR" \
  eval_cfg.disable_planning=true \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512
