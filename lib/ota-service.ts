import { getBleManager, encodeBase64, decodeBase64 } from "./ble";
import {
  OTA_SERVICE,
  CONTROL_CHAR,
  DATA_CHAR,
  OTA_STATUS_CHAR,
} from "./constants";
import { OtaProgress, OtaState } from "../types";

const OTA_CMD_START = 0x01;
const OTA_CMD_ABORT = 0x02;
const OTA_CMD_FINISH = 0x03;
const OTA_CMD_CONFIRM = 0x04;

const CHUNK_SIZE = 244; // MTU - 3 bytes ATT overhead

function encodeBytes(bytes: number[]): string {
  return encodeBase64(String.fromCharCode(...bytes));
}

function uint32LE(value: number): number[] {
  return [
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ];
}

export async function startOta(
  deviceId: string,
  firmwareSize: number
): Promise<void> {
  const mgr = getBleManager();
  const payload = [OTA_CMD_START, ...uint32LE(firmwareSize)];
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    OTA_SERVICE,
    CONTROL_CHAR,
    encodeBytes(payload)
  );
}

export async function sendChunk(
  deviceId: string,
  chunk: string // base64-encoded chunk
): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithoutResponseForDevice(
    deviceId,
    OTA_SERVICE,
    DATA_CHAR,
    chunk
  );
}

export async function finishOta(deviceId: string): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    OTA_SERVICE,
    CONTROL_CHAR,
    encodeBytes([OTA_CMD_FINISH])
  );
}

export async function confirmOta(deviceId: string): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    OTA_SERVICE,
    CONTROL_CHAR,
    encodeBytes([OTA_CMD_CONFIRM])
  );
}

export async function abortOta(deviceId: string): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    OTA_SERVICE,
    CONTROL_CHAR,
    encodeBytes([OTA_CMD_ABORT])
  );
}

export function monitorProgress(
  deviceId: string,
  callback: (state: OtaState) => void
): { remove: () => void } {
  const mgr = getBleManager();
  return mgr.monitorCharacteristicForDevice(
    deviceId,
    OTA_SERVICE,
    OTA_STATUS_CHAR,
    (error, char) => {
      if (error) {
        console.warn("OTA status monitor error:", error.message);
        callback("error");
        return;
      }
      if (char?.value) {
        const byte = decodeBase64(char.value).charCodeAt(0);
        const states: OtaState[] = [
          "idle",
          "starting",
          "transferring",
          "finishing",
          "confirming",
          "complete",
          "error",
        ];
        callback(states[byte] || "error");
      }
    }
  );
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function performOta(
  deviceId: string,
  firmwareData: string, // base64-encoded full firmware
  onProgress: (progress: OtaProgress) => void
): Promise<void> {
  // Decode base64 to get raw bytes for chunking
  const raw = decodeBase64(firmwareData);
  const totalBytes = raw.length;

  onProgress({
    state: "starting",
    bytesSent: 0,
    totalBytes,
    percent: 0,
  });

  await startOta(deviceId, totalBytes);
  await sleep(500);

  onProgress({
    state: "transferring",
    bytesSent: 0,
    totalBytes,
    percent: 0,
  });

  let offset = 0;
  while (offset < totalBytes) {
    const end = Math.min(offset + CHUNK_SIZE, totalBytes);
    const chunk = raw.substring(offset, end);
    const chunkBase64 = encodeBase64(chunk);

    await sendChunk(deviceId, chunkBase64);
    offset = end;

    onProgress({
      state: "transferring",
      bytesSent: offset,
      totalBytes,
      percent: Math.round((offset / totalBytes) * 100),
    });

    // Small delay to avoid overwhelming the BLE stack
    if (offset % (CHUNK_SIZE * 10) === 0) {
      await sleep(20);
    }
  }

  onProgress({
    state: "finishing",
    bytesSent: totalBytes,
    totalBytes,
    percent: 100,
  });

  await finishOta(deviceId);
  await sleep(1000);

  onProgress({
    state: "confirming",
    bytesSent: totalBytes,
    totalBytes,
    percent: 100,
  });

  await confirmOta(deviceId);

  onProgress({
    state: "complete",
    bytesSent: totalBytes,
    totalBytes,
    percent: 100,
  });
}
