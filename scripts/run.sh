export WANDB_MODE=disabled

ROOT=/home/shanveen-ortho-clinic/Documents/Projects/worldmodels/HWM_PLDM_TS
TRAIN_DATA_ROOT=/media/shanveen-ortho-clinic/datadrv1/maze2d_large_diverse_25maps
L1_DIR="$ROOT/checkpoint/maze2d_large_diverse/maze2d_large_diverse"
L2_DIR="$ROOT/checkpoint/maze2d_large_diverse/l2_wo_encoder/maze2d_large_diverse"
TRAIN_DATA_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps/data.p"
TRAIN_IMAGES_PATH="$TRAIN_DATA_ROOT/images.npy"
PROBE_DATA_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/data.p"
PROBE_IMAGES_PATH="$ROOT/pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/images.npy"

cd "$ROOT/pldm"
echo "L1 training..."
python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" base_lr=0.001 data.d4rl_config.batch_size=128 epochs=5\
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  wandb=false data.d4rl_config.crop_length=400000 data.num_workers=0

# echo "L2 training..."
# python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
#   --values root_path="$ROOT" base_lr=0.001 data.d4rl_config.batch_size=128 \
#   data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
#   hjepa.level1.backbone.arch=impala \
#   hjepa.level1.predictor.predictor_arch=mlp \
#   hjepa.level1.predictor.predictor_subclass=512-512 \
#   objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
#   objectives_l1.idm.arch=512-512 \
#   eval_cfg.probing.locations.arch=512-512 \
#   eval_cfg.probing.l2_locations.arch=512-512 \
#   hjepa.level2.backbone.arch=mlp \
#   hjepa.level2.backbone.backbone_norm=layer_norm \
#   hjepa.level2.backbone.backbone_subclass=512-512 \
#   hjepa.level2.predictor.predictor_arch=mlp \
#   hjepa.level2.predictor.predictor_subclass=512-512 \
#   objectives_l2.objectives='[PredictionObs]' \
#   load_checkpoint_path="$L1_DIR" load_l1_only=true \
#   wandb=false data.d4rl_config.crop_length=800000 data.num_workers=0

# echo "L2 evaluation..."
# python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
#   --values root_path="$ROOT" base_lr=0.001 \
#   data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
#   hjepa.level1.backbone.arch=impala \
#   hjepa.level1.predictor.predictor_arch=mlp \
#   hjepa.level1.predictor.predictor_subclass=512-512 \
#   objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
#   objectives_l1.idm.arch=512-512 \
#   eval_cfg.probing.locations.arch=512-512 \
#   eval_cfg.probing.l2_locations.arch=512-512 \
#   hjepa.level2.backbone.arch=mlp \
#   hjepa.level2.backbone.backbone_norm=layer_norm \
#   hjepa.level2.backbone.backbone_subclass=512-512 \
#   hjepa.level2.predictor.predictor_arch=mlp \
#   hjepa.level2.predictor.predictor_subclass=512-512 \
#   objectives_l2.objectives='[PredictionObs]' \
#   eval_only=true load_l1_only=false \
#   load_checkpoint_path="$L2_DIR" \
#   wandb=false data.d4rl_config.crop_length=800000 data.num_workers=0

echo "L1 evaluation..."
python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$ROOT" base_lr=0.001 \
  data.d4rl_config.path="$TRAIN_DATA_PATH" data.d4rl_config.images_path="$TRAIN_IMAGES_PATH" \
  hjepa.level1.backbone.arch=impala \
  hjepa.level1.predictor.predictor_arch=mlp \
  hjepa.level1.predictor.predictor_subclass=512-512 \
  objectives_l1.objectives='[VICRegObs,IDM,PredictionObs]' \
  objectives_l1.idm.arch=512-512 \
  eval_cfg.probing.locations.arch=512-512 \
  eval_cfg.probing.l2_locations.arch=512-512 \
  eval_only=true load_checkpoint_path="$L1_DIR" \
  wandb=false data.d4rl_config.crop_length=800000 data.num_workers=0