import { View, Text, TouchableOpacity, StyleSheet } from "react-native";
import { ScannedDevice } from "../types";

interface DeviceCardProps {
  device: ScannedDevice;
  onPress: () => void;
}

function rssiToSignal(rssi: number): string {
  if (rssi >= -50) return "Excellent";
  if (rssi >= -70) return "Good";
  if (rssi >= -85) return "Fair";
  return "Weak";
}

export default function DeviceCard({ device, onPress }: DeviceCardProps) {
  const signal = rssiToSignal(device.rssi);

  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <View style={styles.info}>
        <Text style={styles.name}>{device.name}</Text>
        <Text style={styles.id}>{device.id}</Text>
      </View>
      <View style={styles.rssiContainer}>
        <Text style={styles.rssi}>{device.rssi} dBm</Text>
        <Text style={styles.signal}>{signal}</Text>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: "#2C2C2E",
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  info: { flex: 1 },
  name: { color: "#FFFFFF", fontSize: 16, fontWeight: "600" },
  id: { color: "#8E8E93", fontSize: 12, marginTop: 4 },
  rssiContainer: { alignItems: "flex-end" },
  rssi: { color: "#EBEBF5", fontSize: 14 },
  signal: { color: "#8E8E93", fontSize: 12, marginTop: 2 },
});
