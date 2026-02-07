import { useState, useCallback, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
} from "react-native";
import { performOta, monitorProgress, abortOta } from "../lib/ota-service";
import {
  listFirmware,
  downloadFirmware,
  readFirmwareFile,
  getCachedVersions,
} from "../lib/firmware-api";
import { FirmwareEntry, OtaProgress, OtaState } from "../types";

interface OtaUpdateProps {
  deviceId: string;
  connected: boolean;
}

const STATE_LABELS: Record<OtaState, string> = {
  idle: "Ready",
  starting: "Starting OTA...",
  transferring: "Transferring firmware...",
  finishing: "Finalizing...",
  confirming: "Confirming update...",
  complete: "Update complete!",
  error: "Update failed",
};

export default function OtaUpdate({ deviceId, connected }: OtaUpdateProps) {
  const [firmwares, setFirmwares] = useState<FirmwareEntry[]>([]);
  const [cachedVersions, setCachedVersions] = useState<string[]>([]);
  const [selectedVersion, setSelectedVersion] = useState<string | null>(null);
  const [progress, setProgress] = useState<OtaProgress | null>(null);
  const [downloading, setDownloading] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadFirmwareList();
  }, []);

  const loadFirmwareList = useCallback(async () => {
    setLoading(true);
    try {
      const [list, cached] = await Promise.all([
        listFirmware(),
        getCachedVersions(),
      ]);
      setFirmwares(list);
      setCachedVersions(cached);
      if (list.length > 0 && !selectedVersion) {
        setSelectedVersion(list[list.length - 1].version);
      }
    } catch (e: any) {
      console.warn("Failed to load firmware list:", e.message);
    } finally {
      setLoading(false);
    }
  }, [selectedVersion]);

  const handleDownload = useCallback(async () => {
    if (!selectedVersion) return;
    setDownloading(true);
    try {
      await downloadFirmware(selectedVersion);
      const cached = await getCachedVersions();
      setCachedVersions(cached);
    } catch (e: any) {
      Alert.alert("Download Error", e.message);
    } finally {
      setDownloading(false);
    }
  }, [selectedVersion]);

  const handleStartOta = useCallback(async () => {
    if (!selectedVersion || !connected) return;

    const isCached = cachedVersions.includes(selectedVersion);
    if (!isCached) {
      Alert.alert("Not Downloaded", "Please download the firmware first.");
      return;
    }

    try {
      const path = await downloadFirmware(selectedVersion);
      const firmwareData = await readFirmwareFile(path);
      await performOta(deviceId, firmwareData, setProgress);
    } catch (e: any) {
      setProgress({
        state: "error",
        bytesSent: 0,
        totalBytes: 0,
        percent: 0,
      });
      Alert.alert("OTA Error", e.message);
    }
  }, [selectedVersion, connected, cachedVersions, deviceId]);

  const handleAbort = useCallback(async () => {
    try {
      await abortOta(deviceId);
      setProgress(null);
    } catch (e: any) {
      console.warn("Abort failed:", e.message);
    }
  }, [deviceId]);

  const isUpdating =
    progress &&
    progress.state !== "idle" &&
    progress.state !== "complete" &&
    progress.state !== "error";

  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>OTA Update</Text>

      {loading && <Text style={styles.hint}>Loading firmware list...</Text>}

      {firmwares.length > 0 && (
        <View style={styles.versionList}>
          {firmwares.map((fw) => (
            <TouchableOpacity
              key={fw.version}
              style={[
                styles.versionItem,
                selectedVersion === fw.version && styles.versionItemSelected,
              ]}
              onPress={() => setSelectedVersion(fw.version)}
              disabled={!!isUpdating}
            >
              <View style={styles.versionInfo}>
                <Text style={styles.versionText}>v{fw.version}</Text>
                <Text style={styles.versionDate}>{fw.date}</Text>
              </View>
              {cachedVersions.includes(fw.version) && (
                <Text style={styles.cachedBadge}>Downloaded</Text>
              )}
            </TouchableOpacity>
          ))}
        </View>
      )}

      {selectedVersion && !cachedVersions.includes(selectedVersion) && (
        <TouchableOpacity
          style={styles.downloadButton}
          onPress={handleDownload}
          disabled={downloading || !!isUpdating}
        >
          <Text style={styles.buttonText}>
            {downloading ? "Downloading..." : "Download Firmware"}
          </Text>
        </TouchableOpacity>
      )}

      {progress && (
        <View style={styles.progressContainer}>
          <Text style={styles.progressText}>
            {STATE_LABELS[progress.state]}
          </Text>
          <View style={styles.progressBarBg}>
            <View
              style={[styles.progressBar, { width: `${progress.percent}%` }]}
            />
          </View>
          <Text style={styles.progressPercent}>
            {progress.percent}% ({progress.bytesSent} / {progress.totalBytes}{" "}
            bytes)
          </Text>
        </View>
      )}

      <View style={styles.buttonRow}>
        <TouchableOpacity
          style={[
            styles.otaButton,
            (!connected || !selectedVersion || !!isUpdating) &&
              styles.buttonDisabled,
          ]}
          onPress={handleStartOta}
          disabled={!connected || !selectedVersion || !!isUpdating}
        >
          <Text style={styles.buttonText}>Start Update</Text>
        </TouchableOpacity>

        {isUpdating && (
          <TouchableOpacity style={styles.abortButton} onPress={handleAbort}>
            <Text style={styles.buttonText}>Abort</Text>
          </TouchableOpacity>
        )}
      </View>
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
  hint: { color: "#8E8E93", fontSize: 14, marginBottom: 8 },
  versionList: { marginBottom: 12 },
  versionItem: {
    backgroundColor: "#1C1C1E",
    borderRadius: 8,
    padding: 12,
    marginBottom: 6,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  versionItemSelected: {
    borderColor: "#007AFF",
    borderWidth: 2,
  },
  versionInfo: {},
  versionText: { color: "#FFFFFF", fontSize: 15, fontWeight: "600" },
  versionDate: { color: "#8E8E93", fontSize: 12, marginTop: 2 },
  cachedBadge: { color: "#30D158", fontSize: 12, fontWeight: "600" },
  downloadButton: {
    backgroundColor: "#5856D6",
    borderRadius: 8,
    padding: 12,
    alignItems: "center",
    marginBottom: 12,
  },
  progressContainer: { marginBottom: 12 },
  progressText: { color: "#EBEBF5", fontSize: 14, marginBottom: 6 },
  progressBarBg: {
    height: 8,
    backgroundColor: "#1C1C1E",
    borderRadius: 4,
    overflow: "hidden",
  },
  progressBar: {
    height: 8,
    backgroundColor: "#007AFF",
    borderRadius: 4,
  },
  progressPercent: { color: "#8E8E93", fontSize: 12, marginTop: 4 },
  buttonRow: { flexDirection: "row", gap: 10 },
  otaButton: {
    flex: 1,
    backgroundColor: "#007AFF",
    borderRadius: 8,
    padding: 12,
    alignItems: "center",
  },
  abortButton: {
    backgroundColor: "#FF3B30",
    borderRadius: 8,
    padding: 12,
    alignItems: "center",
    paddingHorizontal: 20,
  },
  buttonDisabled: { opacity: 0.5 },
  buttonText: { color: "#FFFFFF", fontSize: 16, fontWeight: "600" },
});
