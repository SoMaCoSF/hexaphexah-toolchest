---
title: "Hexaphexah Material Properties - Marvelous Designer Integration"
version: "1.0.0"
description: "Material property mapping and conversion specifications for MD compatibility"
date: "2024-12-28"
---

# Material Property Mapping System

## Physical Properties (.psp) Specification

```json
{
  "material_properties": {
    "stretch_weft": 0.15,      // Low stretch due to titanium grid
    "stretch_warp": 0.15,
    "shear": 0.12,            // Limited by composite structure
    "bend_weft": 0.08,        // Controlled flexibility
    "bend_warp": 0.08,
    "bend_bias": 0.10,
    "friction": 0.45,         // Surface treatment dependent
    "thickness": 2.5,         // mm
    "density": 450            // g/m²
  }
}
```

## Fabric Definition (.zfab) Structure

```json
{
  "fabric_base": {
    "name": "Hexaphexah_Composite",
    "type": "technical",
    "version": "1.0.0"
  },
  "physical_properties": {
    "weight": 450,
    "thickness": 2.5,
    "drape_coefficient": 0.35
  },
  "thermal_properties": {
    "conductivity": 0.015,    // W/mK
    "max_temp": 400,          // °C
    "min_temp": -150         // °C
  },
  "surface_properties": {
    "roughness": 0.2,
    "specular": 0.3,
    "metallic": 0.5          // Due to Ti grid
  }
}
```

## Property Conversion Algorithms

```python
def convert_physical_properties(hexaphexah_props):
    """
    Convert Hexaphexah physical properties to MD format
    """
    return {
        "stretch_weft": map_stretch(hexaphexah_props.tensile_strength),
        "stretch_warp": map_stretch(hexaphexah_props.tensile_strength),
        "shear": calculate_shear(hexaphexah_props),
        "bend_weft": map_flexibility(hexaphexah_props.flex_radius),
        "bend_warp": map_flexibility(hexaphexah_props.flex_radius),
        "friction": hexaphexah_props.surface_friction,
        "thickness": hexaphexah_props.total_thickness
    }
```

## Layer Interaction Definitions

```json
{
  "layer_interactions": {
    "outer_polyimide": {
      "friction": 0.4,
      "separation": 0.0
    },
    "aerogel_composite": {
      "friction": 0.35,
      "separation": 0.0
    },
    "titanium_grid": {
      "friction": 0.5,
      "separation": 0.0
    },
    "d3o_layer": {
      "friction": 0.45,
      "separation": 0.0
    }
  }
}
```

## Simulation Parameters (.smp)

```json
{
  "simulation": {
    "particle_distance": 3.0,
    "iteration_count": 15,
    "pressure": 15.0,
    "time_step": 1/60,
    "gravity": true
  },
  "constraints": {
    "min_bend_angle": 45,
    "max_stretch": 0.15,
    "collision_margin": 0.5
  }
}
```

## Implementation Guidelines

1. Property Validation
```python
def validate_properties(props):
    """
    Validate property ranges for MD compatibility
    """
    checks = [
        (0.0 <= props.stretch <= 1.0, "Stretch out of range"),
        (props.thickness > 0, "Invalid thickness"),
        (0.0 <= props.friction <= 1.0, "Friction out of range")
    ]
    return all(check[0] for check in checks)
```

2. Export Process
```python
def export_to_md_format(hexaphexah_material):
    """
    Export Hexaphexah material to MD format
    """
    physical_props = convert_physical_properties(hexaphexah_material)
    fabric_def = create_fabric_definition(hexaphexah_material)
    simulation_params = generate_simulation_params(hexaphexah_material)
    
    return {
        "psp": physical_props,
        "zfab": fabric_def,
        "smp": simulation_params
    }
```

3. Layer Management
```python
class HexaphexahLayer:
    def __init__(self, layer_type, properties):
        self.type = layer_type
        self.properties = properties
        self.interactions = {}
    
    def add_interaction(self, other_layer, properties):
        self.interactions[other_layer] = properties
```

## Testing Protocol

1. Material Property Validation
2. Layer Interaction Verification
3. Simulation Parameter Testing
4. Export Format Validation
5. MD Import Testing

## Known Limitations

1. Thermal behavior approximation
2. Grid structure simplification
3. Impact response modeling
4. Multi-layer interaction complexity

