export function cpuInit(len: number, rom: Uint8Array, startAddress: number);
export function cpuScreen(cpu: any): number;
export function cpuStep(cpu: any): number;
export const memory: WebAssembly.Memory;
