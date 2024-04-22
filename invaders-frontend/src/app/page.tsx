"use client";
import { useState, useEffect, useMemo, useCallback, useRef } from "react";
import { Canvas, ThreeElements, useFrame } from "@react-three/fiber";
import { KeyboardControls, OrbitControls } from "@react-three/drei";
import { CPU8080 } from "@/lib/wasm/cpu8080";
import * as THREE from "three";

const WIDTH = 256;
const HEIGHT = 224;

function rotateMatrix(matrix: number[][]) {
  const numRows = matrix.length;
  const numCols = matrix[0].length;
  const rotatedMatrix = new Array(numCols)
    .fill(0)
    .map(() => new Array(numRows).fill(0));

  for (let row = 0; row < numRows; row++) {
    for (let col = 0; col < numCols; col++) {
      // rotatedMatrix[col][numRows - row - 1] = matrix[row][col];
      // rotatedMatrix[col][row] = matrix[numRows - row - 1][col];
      rotatedMatrix[col][row] = matrix[row][numCols - col - 1];
    }
  }

  return rotatedMatrix;
}

export default function Home() {
  const cpu = useMemo(() => new CPU8080(), []);
  const [matrix, setMatrix] = useState<number[][] | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [factor, setFactor] = useState(1000);

  const [file, setFile] = useState<Uint8Array | null>(null);

  const updateScreen = useCallback(() => {
    if (!loaded || performance.now() - cpu.prevTime < 16) return;
    const display = cpu.screen();
    if (!display) return;
    const newMatrix = new Array<number[][]>(256).fill([]).map(() => []);
    for (let y = 0; y < 256; y++) {
      for (let x = 0; x < 32; x++) {
        let pixel = display[y * 32 + x];
        for (let bit = 0; bit < 8; bit++) {
          newMatrix[y].push((pixel >> bit) & 1);
        }
      }
    }
    const rotatedMatrix = rotateMatrix(newMatrix);
    const isEqual =
      matrix?.every((row, i) =>
        row.every((bit, j) => bit === rotatedMatrix[i][j]),
      ) || false;
    if (isEqual) return;
    setMatrix(rotatedMatrix);
  }, [loaded, matrix]);

  useEffect(() => {
    if (!file) return;
    async function loadRom() {
      // load invaders rom into a Uint8Array
      if (!file) return;
      await cpu.load(file);
      console.log("loaded");
      // cpu.run(updateScreen);
      // for (let i = 0; i < 6000; i++) {
      // cpu.step(performance.now() * 2000);
      // }
      const step = () => {
        // for (let i = 0; i < 3000; i++) {
        // const now = performance.now();
        // cpu.step(now);
        // }
        cpu.stepFrame(updateScreen);
        // requestAnimationFrame(step);
        setTimeout(step, 1);
      };
      // requestAnimationFrame(step);
      step();
      // cpu.stepCycle(performance.now());
      setLoaded(true);
    }
    loadRom();
    return () => {
      cpu.reset();
      setLoaded(false);
    };
  }, [file, cpu]);

  const step = useCallback(() => {
    // const now = performance.now();
    // cpu.step(now);
  }, [cpu]);

  const handleFile = (e: any) => {
    console.log("handle");
    console.log(e.target.files[0]);
    const file = e.target.files[0];
    const reader = new FileReader();
    reader.onload = (e) => {
      const arrayBuffer = e.target?.result;
      if (!arrayBuffer) return;
      setFile(new Uint8Array(arrayBuffer as ArrayBuffer));
    };
    reader.readAsArrayBuffer(file);
  };

  const z = 244 / (2 * Math.tan((75 / 2) * (Math.PI / 180)));
  return (
    <main>
      <input type="file" name="rom" onInput={handleFile} />
      <label htmlFor="factor">Factor: {factor}</label>
      <input
        type="number"
        min={100}
        max={10000}
        value={factor}
        onInput={(e) => setFactor(parseInt(e.target.value))}
      />
      <KeyboardControls
        map={[
          { name: "left", keys: ["ArrowLeft", "a"] },
          { name: "right", keys: ["ArrowRight", "d"] },
          { name: "fire", keys: [" ", "Enter"] },
        ]}
      >
        <Canvas
          camera={{
            fov: 75,
            near: 0.1,
            far: 300,
            position: [0, 0, z],
          }}
        >
          <OrbitControls />
          <ambientLight intensity={7} />
          <spotLight position={[10, 10, 10]} />
          <pointLight position={[-10, -10, -10]} />
          {loaded && (
            <Screen matrix={matrix} updateScreen={updateScreen} step={step} />
          )}
        </Canvas>
      </KeyboardControls>
    </main>
  );
}
// <div className="flex flex-col">
// {matrix?.map((row, i) => (
// <div className="flex" key={"row" + i}>
// {row.map((bit, j) => (
// <div
// key={"bit" + i + j}
// className={`w-1 h-1 inline-block ${bit == 0 ? "bg-black" : "bg-white"}`}
// ></div>
// ))}
// </div>
// ))}
// </div>

const Screen = ({ matrix, updateScreen, step }) => {
  const cubes = useRef<THREE.InstancedMesh>(null);
  // const [cubeCount, setCubeCount] = useState(0);
  const cubeCount = 256 * 32 * 8;
  console.log("cubes", cubeCount);
  useFrame(() => {
    // console.log("frame");
    // updateScreen();
    // step();
  });
  useEffect(() => {
    if (!matrix || !cubes.current) return;
    // let count = 0;
    matrix.forEach((row, i) => {
      row.forEach((bit, j) => {
        const cubeMatrix = new THREE.Matrix4();
        cubeMatrix.compose(
          new THREE.Vector3(j - WIDTH / 2, -(i - HEIGHT / 2), 0),
          new THREE.Quaternion(),
          bit === 1 ? new THREE.Vector3(1, 1, 3) : new THREE.Vector3(0, 0, 0),
        );
        cubes.current.setMatrixAt(i * row.length + j, cubeMatrix);
        // count++;
        cubes.current.instanceMatrix.needsUpdate = true;
      });
    });
    // setCubeCount(count);
  }, [matrix]);
  return (
    <instancedMesh ref={cubes} args={[null, null, cubeCount]}>
      <boxGeometry />
      <meshStandardMaterial color="white" />
    </instancedMesh>
  );
  return matrix?.map((row, i) =>
    row.map((bit, j) =>
      bit == 1 ? (
        <Box
          key={"box" + i + j}
          // position={[i - WIDTH / 2, -(j - HEIGHT / 2), 0]}
          // position={[j - WIDTH / 2, i - HEIGHT / 2, 0]}
          // position={[j - HEIGHT / 2, i - WIDTH / 2, 0]}
          position={[j - WIDTH / 2, -(i - HEIGHT / 2), 0]}
          scale={[1, 1, 1]}
        />
      ) : null,
    ),
  );
};

const Box = (props: ThreeElements["mesh"]) => {
  return (
    <mesh {...props}>
      <boxGeometry args={[1, 1, 3]} />
      <meshStandardMaterial color="white" />
    </mesh>
  );
};
