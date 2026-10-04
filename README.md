# Filtre de Sobel 3×3 en VHDL

Détection de contours (Sobel) en flux continu : un pixel en entrée par cycle d'horloge, un pixel en sortie par cycle.

## Fonctionnement

- Deux buffers de ligne mémorisent les lignes r-1 et r-2.
- Une fenêtre 3×3 en registres à décalage avance d'une colonne à chaque pixel.
- Gx et Gy sont calculés, puis la sortie vaut `|Gx| + |Gy|`, saturée à 255.

Pipeline sur 3 étages : fenêtre, puis gradients, puis sortie.

## Interface

| Generic | Défaut | Description |
|---|---|---|
| `N` | 64 | Nombre de lignes |
| `M` | 64 | Nombre de colonnes |

| Port | Direction | Description |
|---|---|---|
| `clk` | in | Horloge |
| `pixel_in` | in | Pixel 8 bits (niveaux de gris) |
| `pixel_in_valid` | in | Pixel d'entrée valide |
| `pixel_out` | out | Magnitude du gradient, 8 bits |
| `pixel_out_valid` | out | Pixel de sortie valide |

## Comportement

- **Latence** : environ une ligne (M + 3 cycles), inhérente à une fenêtre 3×3 en flux ligne par ligne.
- **Bords gauche/droit** : mis à 0, une sortie par cycle sans trou à l'intérieur de l'image.
- **Lignes du haut et du bas** : non calculées, la sortie fait M × (N-2) pixels.
- Les pixels doivent arriver ligne par ligne, exactement N × M par image (pas de reset).

## Simulation (ModelSim / Questa)

```bash
vlib work
vcom src/image_filter.vhd
vcom sim/tb_image_filter.vhd
vsim tb_image_filter
```

