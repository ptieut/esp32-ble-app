import { View, Text, StyleSheet } from "react-native";
import { WifiStatus } from "../types";

const STATUS_COLORS: Record<WifiStatus, string> = {
  disconnected: "#8E8E93",
  connecting: "#FF9F0A",
  connected: "#30D158",
  failed: "#FF3B30",
};

interface StatusBadgeProps {
  status: WifiStatus;
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <View style={[styles.badge, { backgroundColor: STATUS_COLORS[status] + "33" }]}>
      <View style={[styles.dot, { backgroundColor: STATUS_COLORS[status] }]} />
      <Text style={[styles.text, { color: STATUS_COLORS[status] }]}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    alignSelf: "flex-start",
  },
  dot: { width: 8, height: 8, borderRadius: 4, marginRight: 6 },
  text: { fontSize: 13, fontWeight: "600" },
});
