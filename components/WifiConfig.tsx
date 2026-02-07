import { useState, useEffect, useCallback } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from "react-native";
import {
  readSSID,
  writeSSID,
  writePassword,
  applyConfig,
  readStatus,
  readIP,
  monitorStatus,
} from "../lib/wifi-service";
import { WifiStatus } from "../types";
import StatusBadge from "./StatusBadge";

interface WifiConfigProps {
  deviceId: string;
  connected: boolean;
}

export default function WifiConfig({ deviceId, connected }: WifiConfigProps) {
  const [currentSSID, setCurrentSSID] = useState("");
  const [ssid, setSSID] = useState("");
  const [password, setPassword] = useState("");
  const [status, setStatus] = useState<WifiStatus>("disconnected");
  const [ip, setIP] = useState("");
  const [applying, setApplying] = useState(false);

  useEffect(() => {
    if (!connected) return;

    let statusSub: { remove: () => void } | null = null;

    async function init() {
      try {
        const [currentSsid, currentStatus, currentIp] = await Promise.all([
          readSSID(deviceId),
          readStatus(deviceId),
          readIP(deviceId),
        ]);
        setCurrentSSID(currentSsid);
        setSSID(currentSsid);
        setStatus(currentStatus);
        setIP(currentIp);
      } catch (e: any) {
        console.warn("Failed to read WiFi info:", e.message);
      }

      statusSub = monitorStatus(deviceId, (newStatus) => {
        setStatus(newStatus);
        if (newStatus === "connected") {
          readIP(deviceId).then(setIP).catch(() => {});
        }
      });
    }

    init();
    return () => statusSub?.remove();
  }, [deviceId, connected]);

  const handleApply = useCallback(async () => {
    if (!ssid.trim()) {
      Alert.alert("Error", "SSID cannot be empty");
      return;
    }

    setApplying(true);
    try {
      await writeSSID(deviceId, ssid.trim());
      if (password) {
        await writePassword(deviceId, password);
      }
      await applyConfig(deviceId);
      setPassword("");
    } catch (e: any) {
      Alert.alert("Error", `Failed to apply WiFi config: ${e.message}`);
    } finally {
      setApplying(false);
    }
  }, [deviceId, ssid, password]);

  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>WiFi Configuration</Text>

      <View style={styles.statusRow}>
        <Text style={styles.label}>Status:</Text>
        <StatusBadge status={status} />
      </View>

      {currentSSID ? (
        <Text style={styles.currentSSID}>Current: {currentSSID}</Text>
      ) : null}

      {ip ? <Text style={styles.ip}>IP: {ip}</Text> : null}

      <TextInput
        style={styles.input}
        placeholder="SSID"
        placeholderTextColor="#636366"
        value={ssid}
        onChangeText={setSSID}
        autoCapitalize="none"
        autoCorrect={false}
      />

      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#636366"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        autoCapitalize="none"
        autoCorrect={false}
      />

      <TouchableOpacity
        style={[styles.applyButton, applying && styles.applyButtonDisabled]}
        onPress={handleApply}
        disabled={applying}
      >
        <Text style={styles.applyButtonText}>
          {applying ? "Applying..." : "Apply"}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    backgroundColor: "#2C2C2E",
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
  },
  sectionTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "700",
    marginBottom: 12,
  },
  statusRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginBottom: 8,
  },
  label: { color: "#EBEBF5", fontSize: 15 },
  currentSSID: { color: "#8E8E93", fontSize: 14, marginBottom: 4 },
  ip: { color: "#30D158", fontSize: 14, marginBottom: 12 },
  input: {
    backgroundColor: "#1C1C1E",
    borderRadius: 8,
    padding: 12,
    color: "#FFFFFF",
    fontSize: 16,
    marginBottom: 10,
  },
  applyButton: {
    backgroundColor: "#007AFF",
    borderRadius: 8,
    padding: 12,
    alignItems: "center",
    marginTop: 4,
  },
  applyButtonDisabled: { opacity: 0.5 },
  applyButtonText: { color: "#FFFFFF", fontSize: 16, fontWeight: "600" },
});
