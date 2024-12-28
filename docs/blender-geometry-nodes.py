import bpy
import math
from mathutils import Vector

class HexaphexahGeometryNodes:
    def __init__(self):
        self.node_groups = {}
        
    def create_hex_grid_nodes(self):
        """Create node group for hexagonal grid generation"""
        group_name = "HexGrid"
        if group_name in bpy.data.node_groups:
            return bpy.data.node_groups[group_name]
            
        # Create node group
        node_group = bpy.data.node_groups.new(name=group_name, type='GeometryNodeTree')
        
        # Create input/output sockets
        node_group.inputs.new('NodeSocketFloat', "Scale")
        node_group.inputs.new('NodeSocketFloat', "Height")
        node_group.outputs.new('NodeSocketGeometry', "Geometry")
        
        # Create nodes
        nodes = node_group.nodes
        
        # Input node
        group_in = nodes.new('NodeGroupInput')
        group_in.location = Vector((-800, 0))
        
        # Create mesh grid
        mesh_grid = nodes.new('GeometryNodeMeshGrid')
        mesh_grid.location = Vector((-600, 0))
        mesh_grid.inputs[0].default_value = 10  # Vertices X
        mesh_grid.inputs[1].default_value = 10  # Vertices Y
        
        # Transform to hexagon pattern
        transform = nodes.new('GeometryNodeTransform')
        transform.location = Vector((-400, 0))
        
        # Instance on points
        instance = nodes.new('GeometryNodeInstanceOnPoints')
        instance.location = Vector((-200, 0))
        
        # Create hexagon mesh
        cylinder = nodes.new('GeometryNodeMeshCylinder')
        cylinder.location = Vector((-400, 200))
        cylinder.inputs[0].default_value = 6  # Vertices (hexagon)
        
        # Output node
        group_out = nodes.new('NodeGroupOutput')
        group_out.location = Vector((0, 0))
        
        # Create links
        links = node_group.links
        links.new(group_in.outputs["Scale"], transform.inputs[3])  # Scale
        links.new(group_in.outputs["Height"], cylinder.inputs[2])  # Height
        links.new(mesh_grid.outputs[0], transform.inputs[0])
        links.new(transform.outputs[0], instance.inputs[0])
        links.new(cylinder.outputs[0], instance.inputs[2])
        links.new(instance.outputs[0], group_out.inputs[0])
        
        return node_group
        
    def create_material_nodes(self, material_name, color, metallic=0.0, roughness=0.5):
        """Create material with nodes"""
        mat = bpy.data.materials.new(name=material_name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        # Clear default nodes
        nodes.clear()
        
        # Create nodes
        output = nodes.new('ShaderNodeOutputMaterial')
        principled = nodes.new('ShaderNodeBsdfPrincipled')
        
        # Position nodes
        output.location = Vector((300, 0))
        principled.location = Vector((0, 0))
        
        # Set properties
        principled.inputs['Base Color'].default_value = (*color, 1)
        principled.inputs['Metallic'].default_value = metallic
        principled.inputs['Roughness'].default_value = roughness
        
        # Create links
        links.new(principled.outputs['BSDF'], output.inputs['Surface'])
        
        return mat
        
    def setup_geometry_nodes(self, obj):
        """Setup geometry nodes modifier for object"""
        modifier = obj.modifiers.new(name="HexaphexahGeometry", type='NODES')
        
        # Create node group if it doesn't exist
        if "HexGrid" not in bpy.data.node_groups:
            self.create_hex_grid_nodes()
            
        modifier.node_group = bpy.data.node_groups["HexGrid"]
        
    def create_composite_layer(self, name, height, scale, color, metallic=0.0):
        """Create a single composite layer"""
        # Create base mesh
        mesh = bpy.data.meshes.new(name)
        obj = bpy.data.objects.new(name, mesh)
        
        # Add to scene
        bpy.context.scene.collection.objects.link(obj)
        
        # Setup geometry nodes
        self.setup_geometry_nodes(obj)
        
        # Set modifier properties
        obj.modifiers["HexaphexahGeometry"].node_group.inputs["Scale"].default_value = scale
        obj.modifiers["HexaphexahGeometry"].node_group.inputs["Height"].default_value = height
        
        # Create and assign material
        mat = self.create_material_nodes(f"{name}_material", color, metallic)
        obj.data.materials.append(mat)
        
        return obj
        
    def generate_composite(self):
        """Generate complete Hexaphexah composite"""
        layers = [
            {"name": "protective_polyimide", "height": 0.02, "scale": 1.0, 
             "color": (0.2, 0.5, 0.8), "metallic": 0.0},
            {"name": "aerogel", "height": 0.1, "scale": 0.98, 
             "color": (0.8, 0.8, 0.9), "metallic": 0.0},
            {"name": "titanium_grid", "height": 0.03, "scale": 0.95, 
             "color": (0.7, 0.7, 0.7), "metallic": 0.8},
            {"name": "polyimide_composite", "height": 0.1, "scale": 0.93, 
             "color": (0.4, 0.4, 0.6), "metallic": 0.0},
            {"name": "d3o_impact", "height": 0.05, "scale": 0.9, 
             "color": (0.3, 0.6, 0.3), "metallic": 0.0}
        ]
        
        offset = 0
        for layer in layers:
            obj = self.create_composite_layer(
                layer["name"],
                layer["height"],
                layer["scale"],
                layer["color"],
                layer["metallic"]
            )
            obj.location.z = offset
            offset += layer["height"]
            
    def setup_scene(self):
        """Setup scene parameters"""
        # Clear existing objects
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete()
        
        # Add camera
        bpy.ops.object.camera_add(location=(5, -5, 3))
        camera = bpy.context.active_object
        camera.rotation_euler = (math.radians(60), 0, math.radians(45))
        
        # Add lighting
        bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
        
        # Set render settings
        bpy.context.scene.render.engine = 'CYCLES'
        bpy.context.scene.cycles.samples = 128

def main():
    generator = HexaphexahGeometryNodes()
    generator.setup_scene()
    generator.generate_composite()

if __name__ == "__main__":
    main()
