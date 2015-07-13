# Maxscript
Repository of small scripts for 3DStudio max

## collapse_materials.ms 
Gets an object with several materials, and created a new texture with all diffuse textures baked as a single material.

Usage:
```
cd = TCollapseMaterials resolution:512
cd.collapseDiffuse $
```
