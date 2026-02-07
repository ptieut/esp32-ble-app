// BLE Service and Characteristic UUIDs for ESP32-CAM

// WiFi Configuration Service
export const WIFI_SERVICE = "12345678-1234-5678-1234-56789abcdef0";
export const SSID_CHAR = "12345678-1234-5678-1234-56789abcdef1";
export const PASSWORD_CHAR = "12345678-1234-5678-1234-56789abcdef2";
export const STATUS_CHAR = "12345678-1234-5678-1234-56789abcdef3";
export const IP_CHAR = "12345678-1234-5678-1234-56789abcdef4";
export const APPLY_CHAR = "12345678-1234-5678-1234-56789abcdef5";

// OTA Update Service
export const OTA_SERVICE = "12345678-1234-5678-1234-56789abcde00";
export const CONTROL_CHAR = "12345678-1234-5678-1234-56789abcde01";
export const DATA_CHAR = "12345678-1234-5678-1234-56789abcde02";
export const OTA_STATUS_CHAR = "12345678-1234-5678-1234-56789abcde03";

// Device name prefix for filtering scan results
export const DEVICE_NAME_PREFIX = "ESP32CAM-";

// Firmware server URL
export const FIRMWARE_SERVER_URL = "http://localhost:3001";
