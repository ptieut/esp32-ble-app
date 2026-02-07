export interface ScannedDevice {
  id: string;
  name: string;
  rssi: number;
}

export type WifiStatus = "disconnected" | "connecting" | "connected" | "failed";

export interface FirmwareEntry {
  version: string;
  filename: string;
  size: number;
  date: string;
  notes: string;
}

export type OtaState =
  | "idle"
  | "starting"
  | "transferring"
  | "finishing"
  | "confirming"
  | "complete"
  | "error";

export interface OtaProgress {
  state: OtaState;
  bytesSent: number;
  totalBytes: number;
  percent: number;
}

export interface DeviceInfo {
  ssid: string;
  status: WifiStatus;
  ip: string;
}
