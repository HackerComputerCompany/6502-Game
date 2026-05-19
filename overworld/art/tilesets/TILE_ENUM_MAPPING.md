# Tile enum → shared_tileset atlas column

Atlas source ID `0`; each tile is `Vector2i(enum_value, 0)` at 16×16 px (Stardew-scale).

| `town_map.gd` Tile | Column | Visual (procgen) |
|--------------------|--------|------------------|
| GRASS (0) | 0 | Grass |
| PATH (1) | 1 | Dirt path |
| WALL_BROWN (2) | 2 | Brown wall |
| WALL_BEIGE (3) | 3 | Beige wall |
| WALL_GRAY (4) | 4 | Gray wall |
| ROOF_RED (5) | 5 | Red roof |
| ROOF_GRAY (6) | 6 | Gray roof |
| DOOR (7) | 7 | Door (decoration layer) |
| WATER (8) | 8 | Water |
| FENCE (9) | 9 | Fence |
| TREE (10) | 10 | Tree |
| SIGN (11) | 11 | Sign |
| BLANK (12) | 12 | Empty |
| SIDEWALK (13) | 13 | Sidewalk |

Regenerate: `godot --path . -s overworld/tools/build_maps.gd`
