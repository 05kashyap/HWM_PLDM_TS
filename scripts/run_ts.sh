export WANDB_MODE=disabled

ROOT=/home/shanveen-ortho-clinic/Documents/Projects/worldmodels/HWM_PLDM_TS
TRAIN_DATA_ROOT=$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps
TRAIN_DATA_PATH="$TRAIN_DATA_ROOT/data.p"
TRAIN_IMAGES_PATH="$TRAIN_DATA_ROOT/images.npy"
PROBE_DATA_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/data.p"
PROBE_IMAGES_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/images.npy"

cd "$ROOT/pldm"

# 1. Isolate the experiment
TS_EXPERIMENT_ROOT="$ROOT/temporal_straightening_l1"
mkdir -p "$TS_EXPERIMENT_ROOT"

# Since we override output_root, train.py appends output_dir ("maze2d_large_diverse")
TS_L1_DIR="$TS_EXPERIMENT_ROOT/maze2d_large_diverse"

echo "Starting L1 Training with Temporal Straightening..."

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" output_root="$TS_EXPERIMENT_ROOT" base_lr=0.0003 \
  data.d4rl_config.batch_size=128 epochs=1 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs,TemporalStraighteningObs]' \
  objectives_l1.temporal_straightening_obs.curv_coeff=1.0 \
  objectives_l1.idm.arch=512-512 \
  objectives_l1.vicreg_obs.projector=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  wandb=false data.d4rl_config.crop_length=60000 data.num_workers=0
#   wandb=false data.d4rl_config.crop_length=600000 data.num_workers=0


echo "L1 evaluation..."

python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" output_root="$TS_EXPERIMENT_ROOT" base_lr=0.0003 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs,TemporalStraighteningObs]' \
  objectives_l1.temporal_straightening_obs.curv_coeff=1.0 \
  objectives_l1.idm.arch=512-512 \
  objectives_l1.vicreg_obs.projector=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  eval_only=true load_checkpoint_path="$TS_L1_DIR" \
  wandb=false data.d4rl_config.crop_length=60000 data.num_workers=0
  # wandb=false data.d4rl_config.crop_length=600000 data.num_workers=0