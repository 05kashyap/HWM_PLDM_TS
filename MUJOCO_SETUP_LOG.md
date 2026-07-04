# MuJoCo 2.1.2 Setup Log

This repository uses `d4rl==1.1` through `mujoco-py==2.1.2.14`. That combination is old and does not build cleanly with a stock MuJoCo 2.1.2 install on this machine without three local native-file patches.

The patches have been recovered and automated in:

```bash
scripts/patch_mujoco_py_212.sh
```

The normal entry point is:

```bash
source scripts/setup_pldm_env.sh --rebuild
```

## What The Patch Does

`scripts/patch_mujoco_py_212.sh` edits three files in-place and creates one-time `.hwm-pldm.bak` backups.

### 1) `$HOME/.mujoco/mujoco-2.1.2/include/mjmodel.h`

MuJoCo 2.1.2 defines the `mjVisual` child structs anonymously inside `struct mjVisual_`. `mujoco_py` needs named C types for those child structs.

The patch replaces the anonymous child structs with named typedefs:

- `mjVisual_global_`
- `mjVisual_quality`
- `mjVisual_headlight`
- `mjVisual_map`
- `mjVisual_scale`
- `mjVisual_rgba`

Then `struct mjVisual_` uses those named types for `global`, `quality`, `headlight`, `map`, `scale`, and `rgba`.

### 2) `<conda-env>/lib/python3.9/site-packages/mujoco_py/pxd/mjmodel.pxd`

The patch adds Cython declarations for the same `mjVisual_*` structs and changes the `mjVisual` declaration to:

```cython
ctypedef struct mjVisual:
    mjVisual_global_ global_ "global"
    mjVisual_quality quality
    mjVisual_headlight headlight
    mjVisual_map map
    mjVisual_scale scale
    mjVisual_rgba rgba
```

The `global_ "global"` alias avoids using Python's `global` keyword as the Cython field name while still binding to the C field.

### 3) `<conda-env>/lib/python3.9/site-packages/mujoco_py/gl/eglshim.c`

The patch makes the EGL shim compile with stricter C compilers by:

- adding missing includes:
  - `<GL/glew.h>`
  - `<stdio.h>`
  - `<string.h>`
- casting `eglGetProcAddress(...)` results to:
  - `PFNEGLQUERYDEVICESEXTPROC`
  - `PFNEGLGETPLATFORMDISPLAYEXTPROC`
- casting `glMapBufferARB(...)` results to:
  - `GLubyte*`
  - `GLushort*`

## Fresh Setup Order

From a clean machine:

```bash
conda create -n pldm python=3.9 -y
conda activate pldm

pip install -r requirements.txt
pip install -e .
```

Install native deps:

```bash
conda install -c conda-forge glew mesa-libgl-devel mesa-libegl-devel libglu patchelf
```

Ubuntu packages that may also be needed:

```bash
sudo apt-get update
sudo apt-get install -y build-essential libglew-dev libgl1-mesa-dev libegl1-mesa-dev libosmesa6-dev patchelf
```

Install MuJoCo 2.1.2:

```bash
mkdir -p "$HOME/.mujoco"
cd "$HOME/.mujoco"
wget https://mujoco.org/download/mujoco-2.1.2-linux-x86_64.tar.gz
tar -xzf mujoco-2.1.2-linux-x86_64.tar.gz
```

Patch and rebuild:

```bash
cd /path/to/HWM_PLDM_TS
source scripts/setup_pldm_env.sh --rebuild
```

For later shells:

```bash
cd /path/to/HWM_PLDM_TS
source scripts/setup_pldm_env.sh
```

## Runtime Environment

`scripts/setup_pldm_env.sh` exports:

```bash
export MUJOCO_GL=egl
export MUJOCO_PY_MUJOCO_PATH="$HOME/.mujoco/mujoco-2.1.2"
export D4RL_SUPPRESS_IMPORT_ERROR=1
```

It also adds `$MUJOCO_PY_MUJOCO_PATH/bin` and `/usr/lib/nvidia` to `LD_LIBRARY_PATH`, and creates:

```bash
$HOME/.mujoco/mujoco-2.1.2/bin/libmujoco210.so -> ../lib/libmujoco.so
$HOME/.mujoco/mujoco-2.1.2/bin/libglewegl.so -> ../lib/libglewegl.so
```

## Verification

After `source scripts/setup_pldm_env.sh --rebuild`, this should work:

```bash
python -c "import mujoco_py; print('mujoco_py ok')"
python -c "import d4rl; print('d4rl ok')"
```

Then generate or download datasets:

```bash
cd pldm_envs/diverse_maze
bash data_generation/generate_all_datasets_og.sh
```

And run a short training/eval sanity check:

```bash
bash scripts/run_smoke.sh
```

## Notes

- If `mujoco_py` is reinstalled, rerun `source scripts/setup_pldm_env.sh --rebuild`.
- If MuJoCo is installed somewhere other than `$HOME/.mujoco/mujoco-2.1.2`, set `MUJOCO_PY_MUJOCO_PATH` before sourcing the setup script.
- The patch script is idempotent; rerunning it normalizes the same three files.
