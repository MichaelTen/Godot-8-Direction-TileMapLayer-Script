# Godot-8-Direction-TileMapLayer-Script
Godot-8-Direction-TileMap-Layer-Script

# Godot 4.5 Isometric 8-Direction Movement Demo (4-Direction Sprite)

This project demonstrates smooth 8-direction movement in a **2D isometric-style world**, using a **4-direction animated sprite sheet**.  
It mimics the classic movement style of *Ultima Online* — the player remains centered while the world scrolls underneath.

The scene uses **Godot 4.5.1**, with a simple tilemap, a camera-centered player, and a GDScript that handles input, animation, and direction mapping.

---

## 🎮 Features

- 8-direction movement via right mouse button  
- Uses a 4-direction sprite sheet (N, E, S, W)  
- Maps diagonals to the nearest facing direction  
- Player stays centered; world moves below  
- 3×3 subgrid for smooth fractional stepping  
- Lightweight 2D implementation (no 3D or physics)  
- Clear and commented `player.gd` script  

---

## 🧩 Node Tree

```

Universe Node2D
├── TileMapLayer            (TileMapLayer)
└── Player Node2D
├── AnimatedSprite2D    (Character animation)
└── Camera2D            (Centers on player)

```

- `TileMapLayer` → handles terrain and tile visuals  
- `Player Node2D` → main player logic  
- `AnimatedSprite2D` → uses 4×4 sprite sheet with N/E/S/W rows  
- `Camera2D` → keeps the player centered at all times  

---

## 📁 Folder Structure

```

res://
├── assets/
│   ├── player/
│   │   └── male425.png           # 4×4 sprite sheet (N,E,S,W)
│   └── terrain/
│       └── dirt-tile-88-v0.png   # base tile
├── scenes/
│   └── universe.tscn             # main scene
├── scripts/
│   └── player.gd                 # movement + animation script
├── icon.svg
└── main.tscn

```

---

## ⚙️ Setup Instructions

1. Open the project in **Godot 4.5.1** (or later).  
2. Load `scenes/universe.tscn`.  
3. Verify the `spritesheet_path` in `player.gd` points to `res://assets/player/male425.png`.  
4. Check the **Import Settings** for `male425.png`:
   - Filter: **Off**  
   - Mipmaps: **Off**  
   - Repeat: **Disabled**  
   - Then click **Reimport**
5. Run the project — right-click and hold to move the player around the map.

---

## 🧠 Direction Mapping Overview

| Direction (Grid) | dir8 Index | Animation Row | Facing (on Sprite) |
|------------------|-------------|----------------|--------------------|
| East             | 0           | 1              | E |
| Southeast        | 1           | 2              | S |
| South            | 2           | 2              | S |
| Southwest        | 3           | 3              | W |
| West             | 4           | 3              | W |
| Northwest        | 5           | 0              | N |
| North            | 6           | 0              | N |
| Northeast        | 7           | 1              | E |

Each diagonal uses the nearest cardinal animation row from the 4-direction sprite sheet.

---

## 📜 License

This demo and the included `player.gd` script are released under the **MIT License**.  
You’re free to use, modify, and redistribute it for your own Godot projects.

---

## 📸 Preview

<img width="1164" height="732" alt="image" src="https://github.com/user-attachments/assets/eaa90164-fa9b-41c3-9085-a6807703be3f" />

*(The player stays centered while the tilemap scrolls underneath.)*

---

**Created with ❤️ in Godot 4.5.1**
