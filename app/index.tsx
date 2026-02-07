import { useState, useCallback, useRef, useEffect } from "react";
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Platform,
} from "react-native";
import { useRouter } from "expo-router";
import { startScan, stopScan, waitForPoweredOn } from "../lib/ble";
import { ScannedDevice } from "../types";
import DeviceCard from "../components/DeviceCard";

export default function ScannerScreen() {
  const [scanning, setScanning] = useState(false);
  const [devices, setDevices] = useState<ScannedDevice[]>([]);
  const devicesRef = useRef<Map<string, ScannedDevice>>(new Map());
  const router = useRouter();

  useEffect(() => {
    return () => {
      stopScan();
    };
  }, []);

  const handleScan = useCallback(async () => {
    if (scanning) {
      stopScan();
      setScanning(false);
      return;
    }

    if (Platform.OS === "ios") {
      try {
        await waitForPoweredOn();
      } catch (e: any) {
        Alert.alert("Bluetooth Error", e.message);
        return;
      }
    }

    devicesRef.current.clear();
    setDevices([]);
    setScanning(true);

    try {
      await startScan((device) => {
        devicesRef.current.set(device.id, device);
        setDevices(Array.from(devicesRef.current.values()));
      });
    } catch (e: any) {
      Alert.alert("Scan Error", e.message);
      setScanning(false);
    }
  }, [scanning]);

  const handleDevicePress = useCallback(
    (device: ScannedDevice) => {
      stopScan();
      setScanning(false);
      router.push({
        pathname: "/device/[id]",
        params: { id: device.id, name: device.name },
      });
    },
    [router]
  );

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={[styles.scanButton, scanning && styles.scanButtonActive]}
        onPress={handleScan}
      >
        <Text style={styles.scanButtonText}>
          {scanning ? "Stop Scanning" : "Scan for Devices"}
        </Text>
      </TouchableOpacity>

      {devices.length === 0 && !scanning && (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>
            Tap "Scan for Devices" to find nearby ESP32-CAM devices
          </Text>
        </View>
      )}

      {devices.length === 0 && scanning && (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>Scanning for devices...</Text>
        </View>
      )}

      <FlatList
        data={devices}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <DeviceCard
            device={item}
            onPress={() => handleDevicePress(item)}
          />
        )}
        contentContainerStyle={styles.list}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000000",
    padding: 16,
  },
  scanButton: {
    backgroundColor: "#007AFF",
    borderRadius: 12,
    padding: 16,
    alignItems: "center",
    marginBottom: 16,
  },
  scanButtonActive: {
    backgroundColor: "#FF3B30",
  },
  scanButtonText: {
    color: "#FFFFFF",
    fontSize: 17,
    fontWeight: "600",
  },
  emptyState: {
    alignItems: "center",
    marginTop: 40,
  },
  emptyText: {
    color: "#8E8E93",
    fontSize: 15,
    textAlign: "center",
  },
  list: {
    paddingTop: 8,
  },
});
