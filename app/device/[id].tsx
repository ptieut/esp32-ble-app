import { useState, useEffect, useCallback } from "react";
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import {
  connectToDevice,
  disconnectDevice,
  isConnected as checkConnected,
  onDisconnect,
} from "../../lib/ble";
import WifiConfig from "../../components/WifiConfig";
import OtaUpdate from "../../components/OtaUpdate";

export default function DeviceDetailScreen() {
  const { id, name } = useLocalSearchParams<{ id: string; name: string }>();
  const router = useRouter();
  const [connected, setConnected] = useState(false);
  const [connecting, setConnecting] = useState(false);

  useEffect(() => {
    if (!id) return;

    let disconnectSub: { remove: () => void } | null = null;

    async function connect() {
      setConnecting(true);
      try {
        await connectToDevice(id!);
        setConnected(true);

        disconnectSub = onDisconnect(id!, () => {
          setConnected(false);
        });
      } catch (e: any) {
        Alert.alert("Connection Failed", e.message);
      } finally {
        setConnecting(false);
      }
    }

    connect();

    return () => {
      disconnectSub?.remove();
      disconnectDevice(id!).catch(() => {});
    };
  }, [id]);

  const handleDisconnect = useCallback(async () => {
    if (!id) return;
    try {
      await disconnectDevice(id);
      setConnected(false);
      router.back();
    } catch (e: any) {
      Alert.alert("Error", `Failed to disconnect: ${e.message}`);
    }
  }, [id, router]);

  const handleReconnect = useCallback(async () => {
    if (!id) return;
    setConnecting(true);
    try {
      await connectToDevice(id);
      setConnected(true);
    } catch (e: any) {
      Alert.alert("Connection Failed", e.message);
    } finally {
      setConnecting(false);
    }
  }, [id]);

  if (!id) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>No device ID provided</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.deviceName}>{name || "ESP32-CAM"}</Text>
        <Text style={styles.deviceId}>{id}</Text>
        <View
          style={[
            styles.connectionBadge,
            connected ? styles.connectionConnected : styles.connectionDisconnected,
          ]}
        >
          <Text style={styles.connectionText}>
            {connecting
              ? "Connecting..."
              : connected
              ? "Connected"
              : "Disconnected"}
          </Text>
        </View>
      </View>

      {connecting && (
        <View style={styles.connectingContainer}>
          <Text style={styles.connectingText}>
            Connecting to device...
          </Text>
        </View>
      )}

      {connected && (
        <>
          <WifiConfig deviceId={id} connected={connected} />
          <OtaUpdate deviceId={id} connected={connected} />
        </>
      )}

      {!connected && !connecting && (
        <TouchableOpacity style={styles.reconnectButton} onPress={handleReconnect}>
          <Text style={styles.buttonText}>Reconnect</Text>
        </TouchableOpacity>
      )}

      <TouchableOpacity
        style={styles.disconnectButton}
        onPress={handleDisconnect}
      >
        <Text style={styles.buttonText}>
          {connected ? "Disconnect" : "Back"}
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000000",
  },
  content: {
    padding: 16,
  },
  header: {
    backgroundColor: "#2C2C2E",
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    alignItems: "center",
  },
  deviceName: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "700",
  },
  deviceId: {
    color: "#8E8E93",
    fontSize: 12,
    marginTop: 4,
  },
  connectionBadge: {
    marginTop: 10,
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
  },
  connectionConnected: {
    backgroundColor: "#30D15833",
  },
  connectionDisconnected: {
    backgroundColor: "#FF3B3033",
  },
  connectionText: {
    color: "#FFFFFF",
    fontSize: 13,
    fontWeight: "600",
  },
  connectingContainer: {
    alignItems: "center",
    marginVertical: 20,
  },
  connectingText: {
    color: "#8E8E93",
    fontSize: 15,
  },
  reconnectButton: {
    backgroundColor: "#007AFF",
    borderRadius: 12,
    padding: 16,
    alignItems: "center",
    marginBottom: 12,
  },
  disconnectButton: {
    backgroundColor: "#FF3B30",
    borderRadius: 12,
    padding: 16,
    alignItems: "center",
    marginBottom: 32,
  },
  buttonText: {
    color: "#FFFFFF",
    fontSize: 17,
    fontWeight: "600",
  },
  errorText: {
    color: "#FF3B30",
    fontSize: 16,
    textAlign: "center",
    marginTop: 40,
  },
});
