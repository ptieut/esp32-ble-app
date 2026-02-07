import * as FileSystem from "expo-file-system";
import { FIRMWARE_SERVER_URL } from "./constants";
import { FirmwareEntry } from "../types";

const FIRMWARE_CACHE_DIR = `${FileSystem.documentDirectory}firmware/`;

export async function listFirmware(): Promise<FirmwareEntry[]> {
  const response = await fetch(`${FIRMWARE_SERVER_URL}/api/firmware`);
  if (!response.ok) {
    throw new Error(`Failed to fetch firmware list: ${response.status}`);
  }
  return response.json();
}

export async function getLatestVersion(): Promise<FirmwareEntry> {
  const response = await fetch(`${FIRMWARE_SERVER_URL}/api/firmware/latest`);
  if (!response.ok) {
    throw new Error(`Failed to fetch latest version: ${response.status}`);
  }
  return response.json();
}

export async function downloadFirmware(version: string): Promise<string> {
  const dirInfo = await FileSystem.getInfoAsync(FIRMWARE_CACHE_DIR);
  if (!dirInfo.exists) {
    await FileSystem.makeDirectoryAsync(FIRMWARE_CACHE_DIR, {
      intermediates: true,
    });
  }

  const localPath = `${FIRMWARE_CACHE_DIR}${version}.bin`;
  const fileInfo = await FileSystem.getInfoAsync(localPath);
  if (fileInfo.exists) {
    return localPath;
  }

  const result = await FileSystem.downloadAsync(
    `${FIRMWARE_SERVER_URL}/api/firmware/${version}/download`,
    localPath
  );

  if (result.status !== 200) {
    await FileSystem.deleteAsync(localPath, { idempotent: true });
    throw new Error(`Download failed with status ${result.status}`);
  }

  return localPath;
}

export async function getCachedVersions(): Promise<string[]> {
  const dirInfo = await FileSystem.getInfoAsync(FIRMWARE_CACHE_DIR);
  if (!dirInfo.exists) {
    return [];
  }

  const files = await FileSystem.readDirectoryAsync(FIRMWARE_CACHE_DIR);
  return files
    .filter((f) => f.endsWith(".bin"))
    .map((f) => f.replace(".bin", ""));
}

export async function readFirmwareFile(path: string): Promise<string> {
  return FileSystem.readAsStringAsync(path, {
    encoding: FileSystem.EncodingType.Base64,
  });
}
