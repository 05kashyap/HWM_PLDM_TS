
<h1 align="center"><em>Hierarchical Planning with Latent World Models</em></h1>

<p align="center">
  📄 <a href="https://arxiv.org/pdf/2604.03208">Paper</a> | 🌐 <a href="https://kevinghst.github.io/HWM/">Website</a>
</p>

<p align="center">
  <a href="https://kevinghst.github.io">Wancong Zhang</a>, <a href="https://scholar.google.com/citations?user=qUB-__0AAAAJ&hl=en">Basile Terver</a>, <a href="https://artemzholus.github.io">Artem Zholus</a>, <a href="https://soham-chitnis10.github.io">Soham Chitnis</a>, <a href="http://harsh-sutariya.github.io/">Harsh Sutaria</a>,<br/>
  <a href="https://www.midoassran.ca">Mido Assran</a>, <a href="https://www.amirbar.net">Amir Bar</a>, <a href="https://randallbalestriero.github.io">Randall Balestriero</a>, <a href="https://scholar.google.com/citations?user=SvRU8F8AAAAJ&hl=en">Adrien Bardes</a>, <a href="https://yann.lecun.org/ex/">Yann LeCun</a>*, <a href="https://scholar.google.com/citations?user=euUV4iUAAAAJ&hl=en">Nicolas Ballas</a>*
</p>


<p align="center">
  <img src="assets/episode_3.gif" alt="Episode 3" />
</p>

<p align="center">
  <img src="assets/episode_17.gif" alt="Episode 17" />
</p>


# Overview

- Implements **Hierarchical Planning with Latent World Models (HWM)**
- Demonstrates **long-horizon planning** in Diverse Maze (PLDM)
- Achieves higher success and lower planning cost vs flat planners

<em>Disclaimer: While HWM is evaluated across multiple world models (VJEPA2, DINO-WM, and PLDM), this repository provides a minimal implementation on PLDM (Diverse Maze). For full results across additional world models and tasks, see the [project page](https://kevinghst.github.io/HWM/) and [paper](https://arxiv.org/pdf/2604.03208).</em>

---

<p>
  Figure 1a: <strong>Hierarchical planning in latent space.</strong> A high-level planner optimizes macro-actions using a long-horizon world model to reach the goal; the first predicted latent state serves as a subgoal for a low-level planner, which optimizes primitive actions with a short-horizon world model. 
</p>
<p align="center">
  <img src="assets/figure_1a.png" alt="Figure 1a" />
</p>


<p>
Figure 1b: Hierarchical planning improves success on non-greedy, long-horizon tasks across multiple latent world models.
</p>
<p align="center">
  <img src="assets/figure_1b.png" alt="Figure 1b" />
</p>



# What Is In This Repo

- `pldm/`: world-model training, probing, and planning code.
- `pldm_envs/`: Diverse Maze dataset generation, rendering, D4RL-style dataset loading, and evaluation trial generation.
- `scripts/`: local setup, smoke tests, rendering helpers, and baseline/temporal-straightening experiment runners.
- `pldm/pretrained/`: expected location for pretrained checkpoints. You can populate it with `python pldm/download_ckpt_from_hf.py --out-dir pldm/pretrained`.
- `pldm_envs/diverse_maze/datasets/`: expected location for generated or downloaded datasets. This directory is created by the dataset scripts.

# Fresh Setup

This project is pinned around Python 3.9, `d4rl==1.1`, and `mujoco-py==2.1.2.14`. The legacy `mujoco-py` build is the fragile part: it needs MuJoCo 2.1.2, a few native build packages, and the local compatibility patches in `scripts/patch_mujoco_py_212.sh`.

## 1) Clone and create the Python env

```bash
git clone <repo-url>
cd HWM_PLDM_TS

conda create -n pldm python=3.9 -y
conda activate pldm

pip install -r requirements.txt
pip install -e .
```

## 2) Install native build/runtime deps

With conda:

```bash
conda install -c conda-forge glew mesa-libgl-devel mesa-libegl-devel libglu patchelf
```

On Ubuntu, these system packages are also commonly needed:

```bash
sudo apt-get update
sudo apt-get install -y build-essential libglew-dev libgl1-mesa-dev libegl1-mesa-dev libosmesa6-dev patchelf
```

## 3) Install MuJoCo 2.1.2

Put the extracted MuJoCo folder at `$HOME/.mujoco/mujoco-2.1.2`:

```bash
mkdir -p "$HOME/.mujoco"
cd "$HOME/.mujoco"
wget https://mujoco.org/download/mujoco-2.1.2-linux-x86_64.tar.gz
tar -xzf mujoco-2.1.2-linux-x86_64.tar.gz
```

If you already have the tarball locally, just extract it so this exists:

```bash
test -f "$HOME/.mujoco/mujoco-2.1.2/include/mjmodel.h"
```

## 4) Apply MuJoCo/mujoco-py patches and rebuild

From the repo root:

```bash
source scripts/setup_pldm_env.sh --rebuild
```

That script:

- activates the `pldm` conda env;
- exports `MUJOCO_GL=egl`, `MUJOCO_PY_MUJOCO_PATH=$HOME/.mujoco/mujoco-2.1.2`, and `D4RL_SUPPRESS_IMPORT_ERROR=1`;
- adds the MuJoCo `bin` directory to `LD_LIBRARY_PATH`;
- creates `libmujoco210.so` and `libglewegl.so` symlinks expected by `mujoco-py`;
- applies the recovered local patches to:
  - `$HOME/.mujoco/mujoco-2.1.2/include/mjmodel.h`
  - `<conda-env>/lib/python3.9/site-packages/mujoco_py/pxd/mjmodel.pxd`
  - `<conda-env>/lib/python3.9/site-packages/mujoco_py/gl/eglshim.c`
- clears `~/.cache/mujoco_py` and rebuilds `mujoco_py`.

The patcher creates `.hwm-pldm.bak` backups the first time it edits each native file.

For later shells, run this without rebuilding:

```bash
source scripts/setup_pldm_env.sh
```

# Data Setup

Download the paper datasets and render top-down image observations:

```bash
cd pldm_envs/diverse_maze
bash data_generation/generate_all_datasets_og.sh
```

This creates:

- `pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps/data.p`
- `pldm_envs/diverse_maze/datasets/maze2d_large_diverse_25maps/images.npy`
- `pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/data.p`
- `pldm_envs/diverse_maze/datasets/maze2d_large_diverse_probe/images.npy`

To generate new maze data instead of downloading the paper data:

```bash
cd pldm_envs/diverse_maze
bash data_generation/generate_all_datasets_new.sh
```

# Checkpoints

Download pretrained checkpoints:

```bash
python pldm/download_ckpt_from_hf.py --out-dir pldm/pretrained
```

Expected files:

- `pldm/pretrained/3-9-1-seed248_epoch=3_sample_step=15465472.ckpt`
- `pldm/pretrained/load_from_l1248-seed248_epoch=5_sample_step=10789632.ckpt`

# Run

Quick sanity check:

```bash
bash scripts/run_smoke.sh
```

Evaluate pretrained flat PLDM:

```bash
cd pldm
python train.py --configs configs/diverse_maze/icml/large_diverse_25maps.yaml \
  --values root_path="$(cd .. && pwd)" eval_only=true \
  load_checkpoint_path="$(cd .. && pwd)/pldm/pretrained/3-9-1-seed248_epoch=3_sample_step=15465472.ckpt"
```

Evaluate pretrained HWM:

```bash
cd pldm
python train.py --configs configs/diverse_maze/icml/large_diverse_25maps_l2.yaml \
  --values root_path="$(cd .. && pwd)" eval_only=true load_l1_only=false \
  load_checkpoint_path="$(cd .. && pwd)/pldm/pretrained/load_from_l1248-seed248_epoch=5_sample_step=10789632.ckpt"
```

Full local experiment scripts:

```bash
bash scripts/run.sh
bash scripts/run_l2.sh
bash scripts/run_ts.sh
```

# Troubleshooting

- If `import mujoco_py` fails after package reinstalls, rerun `source scripts/setup_pldm_env.sh --rebuild`.
- If rendering fails with EGL or GLEW errors, confirm `MUJOCO_GL=egl`, `LD_LIBRARY_PATH` includes `$HOME/.mujoco/mujoco-2.1.2/bin`, and the conda/native deps above are installed.
- If training cannot find data, confirm `data.p` and `images.npy` exist under `pldm_envs/diverse_maze/datasets/...`, or override `data.d4rl_config.path` and `data.d4rl_config.images_path` in the command.
