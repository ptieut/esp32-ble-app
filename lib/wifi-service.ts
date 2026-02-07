import { getBleManager, decodeBase64, encodeBase64 } from "./ble";
import {
  WIFI_SERVICE,
  SSID_CHAR,
  PASSWORD_CHAR,
  STATUS_CHAR,
  IP_CHAR,
  APPLY_CHAR,
} from "./constants";
import { WifiStatus } from "../types";

export async function readSSID(deviceId: string): Promise<string> {
  const mgr = getBleManager();
  const char = await mgr.readCharacteristicForDevice(
    deviceId,
    WIFI_SERVICE,
    SSID_CHAR
  );
  return char.value ? decodeBase64(char.value) : "";
}

export async function writeSSID(
  deviceId: string,
  ssid: string
): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    WIFI_SERVICE,
    SSID_CHAR,
    encodeBase64(ssid)
  );
}

export async function writePassword(
  deviceId: string,
  password: string
): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    WIFI_SERVICE,
    PASSWORD_CHAR,
    encodeBase64(password)
  );
}

export async function applyConfig(deviceId: string): Promise<void> {
  const mgr = getBleManager();
  await mgr.writeCharacteristicWithResponseForDevice(
    deviceId,
    WIFI_SERVICE,
    APPLY_CHAR,
    encodeBase64("\x01")
  );
}

function parseStatus(value: string): WifiStatus {
  const byte = decodeBase64(value).charCodeAt(0);
  switch (byte) {
    case 0:
      return "disconnected";
    case 1:
      return "connecting";
    case 2:
      return "connected";
    case 3:
      return "failed";
    default:
      return "disconnected";
  }
}

export async function readStatus(deviceId: string): Promise<WifiStatus> {
  const mgr = getBleManager();
  const char = await mgr.readCharacteristicForDevice(
    deviceId,
    WIFI_SERVICE,
    STATUS_CHAR
  );
  return char.value ? parseStatus(char.value) : "disconnected";
}

export async function readIP(deviceId: string): Promise<string> {
  const mgr = getBleManager();
  const char = await mgr.readCharacteristicForDevice(
    deviceId,
    WIFI_SERVICE,
    IP_CHAR
  );
  return char.value ? decodeBase64(char.value) : "";
}

export function monitorStatus(
  deviceId: string,
  callback: (status: WifiStatus) => void
): { remove: () => void } {
  const mgr = getBleManager();
  return mgr.monitorCharacteristicForDevice(
    deviceId,
    WIFI_SERVICE,
    STATUS_CHAR,
    (error, char) => {
      if (error) {
        console.warn("Status monitor error:", error.message);
        return;
      }
      if (char?.value) {
        callback(parseStatus(char.value));
      }
    }
  );
}
