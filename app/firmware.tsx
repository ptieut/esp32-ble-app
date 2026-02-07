import { useState, useEffect, useCallback } from "react";
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Alert,
  RefreshControl,
} from "react-native";
import {
  listFirmware,
  downloadFirmware,
  getCachedVersions,
} from "../lib/firmware-api";
import { FirmwareEntry } from "../types";

function formatSize(bytes: number): string {
  if (bytes === 0) return "Unknown";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function FirmwareScreen() {
  const [firmwares, setFirmwares] = useState<FirmwareEntry[]>([]);
  const [cachedVersions, setCachedVersions] = useState<string[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [downloadingVersion, setDownloadingVersion] = useState<string | null>(
    null
  );

  const loadData = useCallback(async () => {
    try {
      const [list, cached] = await Promise.all([
        listFirmware(),
        getCachedVersions(),
      ]);
      setFirmwares(list);
      setCachedVersions(cached);
    } catch (e: any) {
      Alert.alert("Error", `Failed to load firmware list: ${e.message}`);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  }, [loadData]);

  const handleDownload = useCallback(
    async (version: string) => {
      setDownloadingVersion(version);
      try {
        await downloadFirmware(version);
        const cached = await getCachedVersions();
        setCachedVersions(cached);
      } catch (e: any) {
        Alert.alert("Download Error", e.message);
      } finally {
        setDownloadingVersion(null);
      }
    },
    []
  );

  const renderItem = useCallback(
    ({ item }: { item: FirmwareEntry }) => {
      const isCached = cachedVersions.includes(item.version);
      const isDownloading = downloadingVersion === item.version;

      return (
        <View style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.version}>v{item.version}</Text>
            <Text style={styles.date}>{item.date}</Text>
          </View>
          <Text style={styles.size}>{formatSize(item.size)}</Text>
          {item.notes ? (
            <Text style={styles.notes}>{item.notes}</Text>
          ) : null}
          <View style={styles.cardFooter}>
            {isCached ? (
              <Text style={styles.cachedText}>Downloaded</Text>
            ) : (
              <TouchableOpacity
                style={[
                  styles.downloadButton,
                  isDownloading && styles.downloadButtonDisabled,
                ]}
                onPress={() => handleDownload(item.version)}
                disabled={isDownloading}
              >
                <Text style={styles.downloadButtonText}>
                  {isDownloading ? "Downloading..." : "Download"}
                </Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
      );
    },
    [cachedVersions, downloadingVersion, handleDownload]
  );

  return (
    <View style={styles.container}>
      {firmwares.length === 0 && !refreshing && (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>
            No firmware versions available. Pull to refresh.
          </Text>
        </View>
      )}

      <FlatList
        data={firmwares}
        keyExtractor={(item) => item.version}
        renderItem={renderItem}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor="#007AFF"
          />
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#000000",
  },
  list: { padding: 16 },
  card: {
    backgroundColor: "#2C2C2E",
    borderRadius: 12,
    padding: 16,
    marginBottom: 10,
  },
  cardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 4,
  },
  version: { color: "#FFFFFF", fontSize: 18, fontWeight: "700" },
  date: { color: "#8E8E93", fontSize: 13 },
  size: { color: "#EBEBF5", fontSize: 14, marginBottom: 4 },
  notes: { color: "#8E8E93", fontSize: 14, marginBottom: 8 },
  cardFooter: {
    flexDirection: "row",
    justifyContent: "flex-end",
    marginTop: 8,
  },
  cachedText: { color: "#30D158", fontSize: 14, fontWeight: "600" },
  downloadButton: {
    backgroundColor: "#5856D6",
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  downloadButtonDisabled: { opacity: 0.5 },
  downloadButtonText: { color: "#FFFFFF", fontSize: 14, fontWeight: "600" },
  emptyState: {
    alignItems: "center",
    marginTop: 40,
    paddingHorizontal: 20,
  },
  emptyText: {
    color: "#8E8E93",
    fontSize: 15,
    textAlign: "center",
  },
});
