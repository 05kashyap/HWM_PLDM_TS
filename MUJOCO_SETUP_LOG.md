# MuJoCo 2.1.2 Setup Log (Local Build)

This log captures the fixes and build steps needed to run the Diverse Maze data pipeline and training with MuJoCo 2.1.2 on this machine.

## Summary of Changes Made

### Repo scripts and configs
- Auto-derived project root in dataset scripts so they work from any checkout:
  - pldm_envs/diverse_maze/data_generation/generate_all_datasets_og.sh
  - pldm_envs/diverse_maze/data_generation/generate_all_datasets_new.sh
- Removed hardcoded /scratch root in configs and switched to relative root:
  - pldm/configs/diverse_maze/icml/large_diverse_25maps.yaml
  - pldm/configs/diverse_maze/icml/large_diverse_25maps_l2.yaml
- Updated images_path in both configs to point at the local datasets folder.

### Local environment fixes (not committed to repo)
- MuJoCo 2.1.2 installed under: $HOME/.mujoco/mujoco-2.1.2
- MuJoCo headers patched to match mujoco_py bindings (mjVisual sub-structs):
  - $HOME/.mujoco/mujoco-2.1.2/include/mjmodel.h
- mujoco_py Cython headers patched so mjVisual sub-structs come from the MuJoCo headers:
  - <conda-env>/lib/python3.9/site-packages/mujoco_py/pxd/mjmodel.pxd
- eglshim.c patched for missing includes and correct GL pointer casts:
  - <conda-env>/lib/python3.9/site-packages/mujoco_py/gl/eglshim.c
- Symlinks added so mujoco_py finds MuJoCo and GLEW libs:
  - $HOME/.mujoco/mujoco-2.1.2/bin/libmujoco210.so -> ../lib/libmujoco.so
  - $HOME/.mujoco/mujoco-2.1.2/bin/libglewegl.so -> ../lib/libglewegl.so
- Extra build tools and headers installed:
  - glew
  - mesa-libgl-devel, mesa-libegl-devel, libglu
  - patchelf

## From-Scratch Setup (Order Matters)

### 1) Create and activate the environment
```
conda create -n pldm python=3.9 -y
conda activate pldm
pip install -r requirements.txt
pip install -e .
```

### 2) Install MuJoCo 2.1.2
```
mkdir -p "$HOME/.mujoco"
cd "$HOME/.mujoco"
# Place the extracted folder at: $HOME/.mujoco/mujoco-2.1.2
```

### 3) Install build deps (conda)
```
conda install -c conda-forge glew mesa-libgl-devel mesa-libegl-devel libglu patchelf
```

### 4) Set runtime env vars (per shell)
```
export MUJOCO_GL=egl
export MUJOCO_PY_MUJOCO_PATH="$HOME/.mujoco/mujoco-2.1.2"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/.mujoco/mujoco-2.1.2/bin"
export D4RL_SUPPRESS_IMPORT_ERROR=1
```

### 5) Apply local header and mujoco_py patches
- Patch $HOME/.mujoco/mujoco-2.1.2/include/mjmodel.h
- Patch <conda-env>/lib/python3.9/site-packages/mujoco_py/pxd/mjmodel.pxd
- Patch <conda-env>/lib/python3.9/site-packages/mujoco_py/gl/eglshim.c

### 6) Add symlinks for MuJoCo and GLEW
```
cd "$HOME/.mujoco/mujoco-2.1.2/bin"
ln -sf ../lib/libmujoco.so libmujoco210.so
ln -sf ../lib/libglewegl.so libglewegl.so
```

### 7) Clean and rebuild mujoco_py once
```
rm -rf "$HOME/.cache/mujoco_py"
MUJOCO_PY_FORCE_REBUILD=1 python -c "import mujoco_py"
```

## End-to-End Run Order

### A) Generate datasets (OG download path)
```
cd pldm_envs/diverse_maze
bash data_generation/generate_all_datasets_og.sh
```

### B) Render + postprocess images (required for train/eval)
```
python data_generation/render_data.py --data_path datasets/maze2d_large_diverse_25maps
python data_generation/postprocess_images.py --data_path datasets/maze2d_large_diverse_25maps --skip_bad_episodes

python data_generation/render_data.py --data_path datasets/maze2d_large_diverse_probe
python data_generation/postprocess_images.py --data_path datasets/maze2d_large_diverse_probe --skip_bad_episodes
```

### C) (Optional) Generate OOD trials
```
python evaluation/generate_starts_targets.py --data_path datasets/maze2d_large_diverse_probe
```

### D) Run evaluation / training
```
cd ../../pldm
python train.py --config configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
  --values root_path=/home/shanveen-ortho-clinic/Documents/Projects/worldmodels/HWM_PLDM_TS \
  eval_only=true load_l1_only=false \
  load_checkpoint_path=/home/shanveen-ortho-clinic/Documents/Projects/worldmodels/HWM_PLDM_TS/pldm/pretrained/load_from_l1248-seed248_epoch=5_sample_step=10789632.ckpt
```

## Notes
- The local patches in the conda env and MuJoCo headers are required for mujoco_py to build with MuJoCo 2.1.2.
- If mujoco_py rebuilds again, re-apply the same patches and rerun the rebuild step.
