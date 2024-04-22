import { CPU8080 } from "./cpu-8080";

let WebWorkerTimeout = null;

function run(cpu: CPU8080) {
  for (let i = 0; i < 30000; i++) {
    const now = performance.now();
    if (now - cpu.prevTime > 16) {
      postMessage("updateScreen");
    }
    cpu.stepCycle(now);
  }
  WebWorkerTimeout = setTimeout(() => run(cpu), 1);
}
