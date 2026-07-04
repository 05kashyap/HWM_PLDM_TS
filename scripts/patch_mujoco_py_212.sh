#!/usr/bin/env bash
set -euo pipefail

# Patch MuJoCo 2.1.2 + mujoco-py 2.1.2.14 for this repo's D4RL renderer.
#
# Usage:
#   source scripts/setup_pldm_env.sh
#   scripts/patch_mujoco_py_212.sh
#
# Optional overrides:
#   MUJOCO_PY_MUJOCO_PATH=$HOME/.mujoco/mujoco-2.1.2
#   PYTHON_BIN=/path/to/conda/env/bin/python

MUJOCO_DIR="${MUJOCO_PY_MUJOCO_PATH:-$HOME/.mujoco/mujoco-2.1.2}"
PYTHON_BIN="${PYTHON_BIN:-python}"

if [ ! -f "$MUJOCO_DIR/include/mjmodel.h" ]; then
  echo "MuJoCo header not found: $MUJOCO_DIR/include/mjmodel.h" >&2
  echo "Set MUJOCO_PY_MUJOCO_PATH to your MuJoCo 2.1.2 directory." >&2
  exit 1
fi

"$PYTHON_BIN" - "$MUJOCO_DIR" <<'PY'
from __future__ import annotations

import pathlib
import site
import sys

mujoco_dir = pathlib.Path(sys.argv[1]).expanduser()

site_dirs = []
try:
    site_dirs.extend(site.getsitepackages())
except AttributeError:
    pass
user_site = site.getusersitepackages()
if user_site:
    site_dirs.append(user_site)

site_packages = None
for path in site_dirs:
    candidate = pathlib.Path(path) / "mujoco_py"
    if candidate.exists():
        site_packages = pathlib.Path(path)
        break

if site_packages is None:
    raise SystemExit(
        "Could not find mujoco_py in this Python environment. "
        "Activate the pldm env or set PYTHON_BIN."
    )

mujoco_py_dir = site_packages / "mujoco_py"
header_path = mujoco_dir / "include" / "mjmodel.h"
pxd_path = mujoco_py_dir / "pxd" / "mjmodel.pxd"
eglshim_path = mujoco_py_dir / "gl" / "eglshim.c"

for path in (pxd_path, eglshim_path):
    if not path.exists():
        raise SystemExit(f"Expected mujoco_py file not found: {path}")


def backup_once(path: pathlib.Path) -> None:
    backup = path.with_name(path.name + ".hwm-pldm.bak")
    if not backup.exists():
        backup.write_text(path.read_text())


HEADER_VISUAL_BLOCK = """//---------------------------------- mjVisual ------------------------------------------------------

// Named sub-structs to match mujoco_py Cython bindings.
typedef struct mjVisual_global_ { // global parameters
  float fovy;                   // y-field of view (deg) for free camera
  float ipd;                    // inter-pupilary distance for free camera
  float linewidth;              // line width for wireframe and ray rendering
  float glow;                   // glow coefficient for selected body
  int offwidth;                 // width of offscreen buffer
  int offheight;                // height of offscreen buffer
} mjVisual_global_;

typedef struct mjVisual_quality { // rendering quality
  int   shadowsize;             // size of shadowmap texture
  int   offsamples;             // number of multisamples for offscreen rendering
  int   numslices;              // number of slices for builtin geom drawing
  int   numstacks;              // number of stacks for builtin geom drawing
  int   numquads;               // number of quads for box rendering
} mjVisual_quality;

typedef struct mjVisual_headlight { // head light
  float ambient[3];             // ambient rgb (alpha=1)
  float diffuse[3];             // diffuse rgb (alpha=1)
  float specular[3];            // specular rgb (alpha=1)
  int   active;                 // is headlight active
} mjVisual_headlight;

typedef struct mjVisual_map {   // mapping
  float stiffness;              // mouse perturbation stiffness (space->force)
  float stiffnessrot;           // mouse perturbation stiffness (space->torque)
  float force;                  // from force units to space units
  float torque;                 // from torque units to space units
  float alpha;                  // scale geom alphas when transparency is enabled
  float fogstart;               // OpenGL fog starts at fogstart * mjModel.stat.extent
  float fogend;                 // OpenGL fog ends at fogend * mjModel.stat.extent
  float znear;                  // near clipping plane = znear * mjModel.stat.extent
  float zfar;                   // far clipping plane = zfar * mjModel.stat.extent
  float haze;                   // haze ratio
  float shadowclip;             // directional light: shadowclip * mjModel.stat.extent
  float shadowscale;            // spot light: shadowscale * light.cutoff
  float actuatortendon;         // scale tendon width
} mjVisual_map;

typedef struct mjVisual_scale { // scale of decor elements relative to mean body size
  float forcewidth;             // width of force arrow
  float contactwidth;           // contact width
  float contactheight;          // contact height
  float connect;                // autoconnect capsule width
  float com;                    // com radius
  float camera;                 // camera object
  float light;                  // light object
  float selectpoint;            // selection point
  float jointlength;            // joint length
  float jointwidth;             // joint width
  float actuatorlength;         // actuator length
  float actuatorwidth;          // actuator width
  float framelength;            // bodyframe axis length
  float framewidth;             // bodyframe axis width
  float constraint;             // constraint width
  float slidercrank;            // slidercrank width
} mjVisual_scale;

typedef struct mjVisual_rgba {  // color of decor elements
  float fog[4];                 // fog
  float haze[4];                // haze
  float force[4];               // external force
  float inertia[4];             // inertia box
  float joint[4];               // joint
  float actuator[4];            // actuator, neutral
  float actuatornegative[4];    // actuator, negative limit
  float actuatorpositive[4];    // actuator, positive limit
  float com[4];                 // center of mass
  float camera[4];              // camera object
  float light[4];               // light object
  float selectpoint[4];         // selection point
  float connect[4];             // auto connect
  float contactpoint[4];        // contact point
  float contactforce[4];        // contact force
  float contactfriction[4];     // contact friction force
  float contacttorque[4];       // contact torque
  float contactgap[4];          // contact point in gap
  float rangefinder[4];         // rangefinder ray
  float constraint[4];          // constraint
  float slidercrank[4];         // slidercrank
  float crankbroken[4];         // used when crank must be stretched/broken
} mjVisual_rgba;

struct mjVisual_ {              // visualization options
  mjVisual_global_ global;      // global parameters
  mjVisual_quality quality;     // rendering quality
  mjVisual_headlight headlight; // head light
  mjVisual_map map;             // mapping
  mjVisual_scale scale;         // scale of decor elements
  mjVisual_rgba rgba;           // color of decor elements
};
typedef struct mjVisual_ mjVisual;

"""

PXD_VISUAL_TYPES = """cdef extern from "mjmodel.h" nogil:
    cdef struct mjVisual_global_:   # global parameters
        float fovy                  # y-field of view (deg) for free camera
        float ipd                   # inter-pupilary distance for free camera
        float linewidth             # line width for wireframe rendering
        float glow                  # glow coefficient for selected body
        int offwidth                # width of offscreen buffer
        int offheight               # height of offscreen buffer

    cdef struct mjVisual_quality:   # rendering quality
        int   shadowsize            # size of shadowmap texture
        int   offsamples            # number of multisamples for offscreen rendering
        int   numslices             # number of slices for Glu drawing
        int   numstacks             # number of stacks for Glu drawing
        int   numquads              # number of quads for box rendering

    cdef struct mjVisual_headlight: # head light
        float ambient[3]            # ambient rgb (alpha=1)
        float diffuse[3]            # diffuse rgb (alpha=1)
        float specular[3]           # specular rgb (alpha=1)
        int   active                # is headlight active

    cdef struct mjVisual_map:       # mapping
        float stiffness             # mouse perturbation stiffness (space->force)
        float stiffnessrot          # mouse perturbation stiffness (space->torque)
        float force                 # from force units to space units
        float torque                # from torque units to space units
        float alpha                 # scale geom alphas when transparency is enabled
        float fogstart              # OpenGL fog starts at fogstart * mjModel.stat.extent
        float fogend                # OpenGL fog ends at fogend * mjModel.stat.extent
        float znear                 # near clipping plane = znear * mjModel.stat.extent
        float zfar                  # far clipping plane = zfar * mjModel.stat.extent
        float haze                  # haze ratio
        float shadowclip            # directional light: shadowclip * mjModel.stat.extent
        float shadowscale           # spot light: shadowscale * light.cutoff
        float actuatortendon        # scale tendon width

    cdef struct mjVisual_scale:     # scale of decor elements relative to mean body size
        float forcewidth            # width of force arrow
        float contactwidth          # contact width
        float contactheight         # contact height
        float connect               # autoconnect capsule width
        float com                   # com radius
        float camera                # camera object
        float light                 # light object
        float selectpoint           # selection point
        float jointlength           # joint length
        float jointwidth            # joint width
        float actuatorlength        # actuator length
        float actuatorwidth         # actuator width
        float framelength           # bodyframe axis length
        float framewidth            # bodyframe axis width
        float constraint            # constraint width
        float slidercrank           # slidercrank width

    cdef struct mjVisual_rgba:      # color of decor elements
        float fog[4]                # external force
        float haze[4]               # haze
        float force[4]              # external force
        float inertia[4]            # inertia box
        float joint[4]              # joint
        float actuator[4]           # actuator
        float actuatornegative[4]   # actuator, negative limit
        float actuatorpositive[4]   # actuator, positive limit
        float com[4]                # center of mass
        float camera[4]             # camera object
        float light[4]              # light object
        float selectpoint[4]        # selection point
        float connect[4]            # auto connect
        float contactpoint[4]       # contact point
        float contactforce[4]       # contact force
        float contactfriction[4]    # contact friction force
        float contacttorque[4]      # contact torque
        float contactgap[4]         # contact point in gap
        float rangefinder[4]        # rangefinder ray
        float constraint[4]         # constraint
        float slidercrank[4]        # slidercrank
        float crankbroken[4]        # used when crank must be stretched/broken

"""

PXD_VISUAL_BLOCK = """    #------------------------------ mjVisual -----------------------------------------------


    ctypedef struct mjVisual:
        mjVisual_global_ global_ "global"
        mjVisual_quality quality
        mjVisual_headlight headlight
        mjVisual_map map
        mjVisual_scale scale
        mjVisual_rgba rgba

"""


def replace_between(text: str, start: str, end: str, replacement: str) -> str:
    start_i = text.index(start)
    end_i = text.index(end, start_i)
    return text[:start_i] + replacement + text[end_i:]


backup_once(header_path)
header = header_path.read_text()
header = replace_between(
    header,
    "//---------------------------------- mjVisual",
    "//---------------------------------- mjStatistic",
    HEADER_VISUAL_BLOCK,
)
header_path.write_text(header)

backup_once(pxd_path)
pxd = pxd_path.read_text()
if "cdef struct mjVisual_global_" not in pxd:
    pxd = PXD_VISUAL_TYPES + pxd
pxd = replace_between(
    pxd,
    "    #------------------------------ mjVisual",
    "    #------------------------------ mjStatistic",
    PXD_VISUAL_BLOCK,
)
pxd_path.write_text(pxd)

backup_once(eglshim_path)
egl = eglshim_path.read_text()
if "#include <GL/glew.h>" not in egl:
    egl = egl.replace(
        '#include "eglext.h"\n',
        '#include "eglext.h"\n#include <GL/glew.h>\n#include <stdio.h>\n#include <string.h>\n',
        1,
    )
for include in ("#include <stdio.h>", "#include <string.h>"):
    if include not in egl:
        egl = egl.replace("#include <GL/glew.h>\n", f"#include <GL/glew.h>\n{include}\n", 1)
egl = egl.replace(
    'PFNEGLQUERYDEVICESEXTPROC eglQueryDevicesEXT =\n        eglGetProcAddress("eglQueryDevicesEXT");',
    'PFNEGLQUERYDEVICESEXTPROC eglQueryDevicesEXT =\n'
    '        (PFNEGLQUERYDEVICESEXTPROC)\n'
    '        eglGetProcAddress("eglQueryDevicesEXT");',
)
egl = egl.replace(
    'PFNEGLGETPLATFORMDISPLAYEXTPROC eglGetPlatformDisplayEXT =\n    eglGetProcAddress("eglGetPlatformDisplayEXT");',
    'PFNEGLGETPLATFORMDISPLAYEXTPROC eglGetPlatformDisplayEXT =\n'
    '    (PFNEGLGETPLATFORMDISPLAYEXTPROC)\n'
    '    eglGetProcAddress("eglGetPlatformDisplayEXT");',
)
egl = egl.replace(
    "GLubyte* src_rgb = glMapBufferARB(GL_PIXEL_PACK_BUFFER_ARB, GL_READ_ONLY_ARB);",
    "GLubyte* src_rgb = (GLubyte*) glMapBufferARB(GL_PIXEL_PACK_BUFFER_ARB, GL_READ_ONLY_ARB);",
)
egl = egl.replace(
    "GLushort* src_depth = glMapBufferARB(GL_PIXEL_PACK_BUFFER_ARB, GL_READ_ONLY_ARB);",
    "GLushort* src_depth = (GLushort*) glMapBufferARB(GL_PIXEL_PACK_BUFFER_ARB, GL_READ_ONLY_ARB);",
)
eglshim_path.write_text(egl)

print(f"Patched MuJoCo header: {header_path}")
print(f"Patched mujoco_py pxd: {pxd_path}")
print(f"Patched mujoco_py EGL shim: {eglshim_path}")
print("Backups use the .hwm-pldm.bak suffix and are created only once.")
PY
