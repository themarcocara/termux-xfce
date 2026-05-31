# termux-xfce

Setup scripts for an XFCE development environment on native Termux.

## GPU Acceleration

Verify that GPU acceleration is active by running:

```bash
export DISPLAY=:1
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TU_DEBUG=noconform

glxinfo | grep -i "renderer"

# Success: OpenGL renderer string: zink (Turnip Adreno (TM) 830)
```
