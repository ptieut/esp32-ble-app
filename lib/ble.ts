import { BleManager, Device, State } from "react-native-ble-plx";
import { DEVICE_NAME_PREFIX, WIFI_SERVICE, OTA_SERVICE } from "./constants";
import { ScannedDevice } from "../types";

let manager: BleManager | null = null;

export function getBleManager(): BleManager {
  if (!manager) {
    manager = new BleManager();
  }
  return manager;
}

export function destroyManager(): void {
  if (manager) {
    manager.destroy();
    manager = null;
  }
}

export async function waitForPoweredOn(): Promise<void> {
  const mgr = getBleManager();
  return new Promise((resolve, reject) => {
    const sub = mgr.onStateChange((state) => {
      if (state === State.PoweredOn) {
        sub.remove();
        resolve();
      } else if (state === State.Unauthorized || state === State.Unsupported) {
        sub.remove();
        reject(new Error(`Bluetooth ${state}`));
      }
    }, true);
  });
}

export async function startScan(
  onDevice: (device: ScannedDevice) => void
): Promise<void> {
  const mgr = getBleManager();
  await waitForPoweredOn();

  mgr.startDeviceScan(
    [WIFI_SERVICE, OTA_SERVICE],
    { allowDuplicates: false },
    (error, device) => {
      if (error) {
        console.warn("Scan error:", error.message);
        return;
      }
      if (
        device?.name?.startsWith(DEVICE_NAME_PREFIX) ||
        device?.localName?.startsWith(DEVICE_NAME_PREFIX)
      ) {
        onDevice({
          id: device.id,
          name: device.name || device.localName || "Unknown",
          rssi: device.rssi ?? -100,
        });
      }
    }
  );
}

export function stopScan(): void {
  getBleManager().stopDeviceScan();
}

export async function connectToDevice(deviceId: string): Promise<Device> {
  const mgr = getBleManager();
  const device = await mgr.connectToDevice(deviceId, {
    requestMTU: 256,
  });
  await device.discoverAllServicesAndCharacteristics();
  return device;
}

export async function disconnectDevice(deviceId: string): Promise<void> {
  const mgr = getBleManager();
  const connected = await mgr.isDeviceConnected(deviceId);
  if (connected) {
    await mgr.cancelDeviceConnection(deviceId);
  }
}

export async function isConnected(deviceId: string): Promise<boolean> {
  const mgr = getBleManager();
  return mgr.isDeviceConnected(deviceId);
}

export function onDisconnect(
  deviceId: string,
  callback: () => void
): { remove: () => void } {
  const mgr = getBleManager();
  return mgr.onDeviceDisconnected(deviceId, () => {
    callback();
  });
}

export function decodeBase64(base64: string): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let result = "";
  let i = 0;
  const clean = base64.replace(/[^A-Za-z0-9+/]/g, "");
  while (i < clean.length) {
    const a = chars.indexOf(clean[i++]);
    const b = chars.indexOf(clean[i++]);
    const c = chars.indexOf(clean[i++]);
    const d = chars.indexOf(clean[i++]);
    const triplet = (a << 18) | (b << 12) | (c << 6) | d;
    result += String.fromCharCode((triplet >> 16) & 0xff);
    if (c !== 64) result += String.fromCharCode((triplet >> 8) & 0xff);
    if (d !== 64) result += String.fromCharCode(triplet & 0xff);
  }
  return result;
}

export function encodeBase64(str: string): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let result = "";
  let i = 0;
  while (i < str.length) {
    const a = str.charCodeAt(i++);
    const b = i < str.length ? str.charCodeAt(i++) : NaN;
    const c = i < str.length ? str.charCodeAt(i++) : NaN;
    const triplet = (a << 16) | ((isNaN(b) ? 0 : b) << 8) | (isNaN(c) ? 0 : c);
    result += chars[(triplet >> 18) & 0x3f];
    result += chars[(triplet >> 12) & 0x3f];
    result += isNaN(b) ? "=" : chars[(triplet >> 6) & 0x3f];
    result += isNaN(c) ? "=" : chars[triplet & 0x3f];
  }
  return result;
}
