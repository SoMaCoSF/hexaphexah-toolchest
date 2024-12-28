import React, { useRef, useState } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Text } from '@react-three/drei';

// Layer component for composite visualization
const Layer = ({ position, color, thickness, label, exploded }) => {
  const meshRef = useRef();
  const [hovered, setHovered] = useState(false);

  // Hexagonal geometry parameters
  const radius = 2;
  const height = thickness;
  const segments = 6;

  // Generate hexagonal shape
  const vertices = [];
  const indices = [];

  for (let i = 0; i <= segments; i++) {
    const angle = (i / segments) * Math.PI * 2;
    vertices.push(
      radius * Math.cos(angle), 0, radius * Math.sin(angle),
      radius * Math.cos(angle), height, radius * Math.sin(angle)
    );
    if (i < segments) {
      const base = i * 2;
      indices.push(
        base, base + 1, base + 2,
        base + 1, base + 3, base + 2
      );
    }
  }

  const explodedPosition = [position[0], position[1] + (exploded ? position[1] * 2 : 0), position[2]];

  return (
    <group position={explodedPosition}>
      <mesh
        ref={meshRef}
        onPointerOver={() => setHovered(true)}
        onPointerOut={() => setHovered(false)}
      >
        <bufferGeometry>
          <bufferAttribute
            attach="attributes-position"
            count={vertices.length / 3}
            array={new Float32Array(vertices)}
            itemSize={3}
          />
          <bufferAttribute
            attach="index"
            array={new Uint16Array(indices)}
            count={indices.length}
            itemSize={1}
          />
        </bufferGeometry>
        <meshStandardMaterial
          color={color}
          transparent
          opacity={0.8}
          wireframe={hovered}
        />
      </mesh>
      <Text
        position={[radius * 1.5, 0, 0]}
        fontSize={0.2}
        color="black"
        anchorX="left"
      >
        {label}
      </Text>
    </group>
  );
};

// Main composite visualization component
const CompositeVisualization = () => {
  const [exploded, setExploded] = useState(false);

  const layers = [
    { color: '#4a90e2', thickness: 0.05, label: 'Protective Polyimide', position: [0, 0.4, 0] },
    { color: '#81c784', thickness: 0.1, label: 'Aerogel Layer', position: [0, 0.3, 0] },
    { color: '#7986cb', thickness: 0.1, label: 'Polyimide-Aerogel Composite', position: [0, 0.2, 0] },
    { color: '#b39ddb', thickness: 0.03, label: 'Titanium Honeycomb', position: [0, 0.1, 0] },
    { color: '#4db6ac', thickness: 0.05, label: 'D3O Impact Layer', position: [0, 0, 0] }
  ];

  return (
    <div className="w-full h-screen">
      <div className="absolute top-4 left-4 z-10">
        <button
          className="bg-blue-500 text-white px-4 py-2 rounded"
          onClick={() => setExploded(!exploded)}
        >
          {exploded ? 'Collapse View' : 'Explode View'}
        </button>
      </div>
      <Canvas camera={{ position: [5, 5, 5], fov: 45 }}>
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} />
        <group position={[0, -1, 0]}>
          {layers.map((layer, index) => (
            <Layer key={index} {...layer} exploded={exploded} />
          ))}
        </group>
        <OrbitControls />
      </Canvas>
    </div>
  );
};

export default CompositeVisualization;
