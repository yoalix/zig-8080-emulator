const memory = new WebAssembly.Memory({
  initial: 17,
  maximum: 17,
  shared: true,
});

const wasm = {
  imports: {
    env: {
      memory,
      time: () => {
        const now = performance.now();
        return now;
      },
      print: (ptr: number, len: number) => {
        const str = new TextDecoder().decode(
          new Uint8Array(wasm.exports.memory.buffer, ptr, len),
        );
        console.log(str);
      },
      printHex: (pc: number, opcode: number, a: number, b: number) => {
        console.log(
          pc.toString(16),
          opcode.toString(16),
          a.toString(16),
          b.toString(16),
        );
        console.log("cycles", pc, "lasst", opcode);
      },
    },
  },
  exports: {},
};

export type Matrix<T> = T & {
  width: number;
  height: number;
};

class U8Chunk extends Uint8Array {
  constructor(
    public ptr: number,
    length: number,
  ) {
    //@ts-ignore
    super(wasm.exports.memory.buffer, ptr, length);
  }

  //toInt(): bigint {
  //  return BigInt(this.ptr) | (BigInt(this.length) << BigInt(32));
  //}

  // TODO: remove floats
  // JS can't handle i64 yet so we're using f64 for now
  toFloat(): number {
    let buf = new ArrayBuffer(8);
    let u32s = new Uint32Array(buf);
    u32s[0] = this.ptr;
    u32s[1] = this.length;
    return new Float64Array(buf)[0];
  }

  static fromFloat(value: number): U8Chunk {
    let buf = new ArrayBuffer(8);
    new Float64Array(buf)[0] = value;
    let u32s = new Uint32Array(buf);
    return new U8Chunk(u32s[0], u32s[1]);
  }

  static matrix(value: number): Matrix<U8Chunk> {
    let buf = new ArrayBuffer(8);
    new Float64Array(buf)[0] = value;
    let u16s = new Uint16Array(buf);
    const ptr = u16s[0] | (u16s[1] << 16);
    const width = u16s[2];
    const height = u16s[3];
    return Object.assign(new U8Chunk(ptr, width * height), { width, height });
  }
}
export class CPU8080 {
  cpu: any = null;
  wasm: any = wasm;
  romLength: number = 0;
  prevTime: number = 0;
  nextTime: number = 0;
  whichInterrupt: number = 0;
  interval: any = null;

  async load(rom: Uint8Array) {
    console.log("Loading ROM");
    console.log(rom);
    try {
      const result = await WebAssembly.instantiateStreaming(
        fetch("/cpu8080.wasm"),
        this.wasm.imports,
      );
      console.log("Loaded WASM");
      this.wasm.exports = result.instance.exports;
      // const romBuff = this.wasm.exports.wasmAlloc(rom.length);
      const romArray = new Uint8Array(
        this.wasm.exports.memory.buffer,
        0,
        rom.length,
      );
      this.romLength = rom.length;
      romArray.set(rom);
      this.cpu = this.wasm.exports.cpuInit(rom.length, romArray.byteOffset, 0);
      console.log("CPU Initialized");
      console.log(this.cpu);
      console.log(
        "wasm memory",
        new Uint8Array(this.wasm.exports.memory.buffer),
      );
      console.log("cpu in memory", this.size());
      console.log("Memory", this.memory());
    } catch (e) {
      console.error(e);
    }
  }

  run(updateScreen: () => void) {
    this.interval = setInterval(() => {
      for (let i = 0; i < 30000; i++) {
        const now = performance.now();

        this.stepCycle(now, updateScreen);
      }
    }, 1);
  }

  reset() {
    clearInterval(this.interval);
  }

  size() {
    return new Uint8Array(
      this.wasm.exports.memory.buffer,
      this.cpu,
      this.wasm.exports.cpuSize(),
    );
  }

  memory() {
    const len = 0x10000;
    return new Uint8Array(
      this.wasm.exports.memory.buffer,
      this.wasm.exports.cpuMemory(this.cpu),
      len,
    );
  }

  screen() {
    const len = 0x4000 - 0x2400;
    const cpuScreen = this.wasm.exports.cpuScreen(this.cpu);

    return new Uint8Array(this.wasm.exports.memory.buffer, cpuScreen, len);
  }

  step(now: number, factor = 1000) {
    // for (let i = 0; i < 800; i++) {
    this.wasm.exports.cpuStep(this.cpu, now);
    // }
  }

  stepCycle(ms: number, updateScreen?: () => void) {
    const now = ms * 1000;
    if (this.prevTime === 0) {
      this.prevTime = now;
      this.nextTime = now + 1666.6;
      this.whichInterrupt = 1;
    }

    if (updateScreen && now - this.prevTime > 16) {
      updateScreen();
      console.log("updateScreen");
    }

    if (now > this.nextTime) {
      this.wasm.exports.cpuGenerateInterrupt(this.cpu, this.whichInterrupt);
      this.whichInterrupt = this.whichInterrupt === 1 ? 2 : 1;
      this.nextTime += 8333.25;
    }

    let since_last = now - this.prevTime;
    let cycles_to_catch_up = since_last * 2;
    let cycles = 0;

    while (cycles < cycles_to_catch_up) {
      cycles += this.wasm.exports.cpuStepCycle(this.cpu);
    }
    this.prevTime = now;
  }

  stepFrame(updateScreen?: () => void) {
    let cycle = 0;
    const frame = 2000 * (1000 / 60);
    while (cycle <= frame / 2) {
      cycle += this.wasm.exports.cpuStepCycle(this.cpu);
    }

    this.wasm.exports.cpuGenerateInterrupt(this.cpu, this.whichInterrupt);
    this.whichInterrupt = this.whichInterrupt === 1 ? 2 : 1;
    while (cycle <= frame) {
      cycle += this.wasm.exports.cpuStepCycle(this.cpu);
    }
    this.wasm.exports.cpuGenerateInterrupt(this.cpu, this.whichInterrupt);
    this.whichInterrupt = this.whichInterrupt === 1 ? 2 : 1;
    updateScreen && updateScreen();
  }

  keydown(key: number) {
    this.wasm.exports.cpuKeyDown(this.cpu, key);
  }

  keyup(key: number) {
    this.wasm.exports.cpuKeyUp(this.cpu, key);
  }
}
