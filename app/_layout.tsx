import { Tabs } from "expo-router";
import { StatusBar } from "expo-status-bar";

export default function RootLayout() {
  return (
    <>
      <StatusBar style="light" />
      <Tabs
        screenOptions={{
          tabBarActiveTintColor: "#007AFF",
          tabBarInactiveTintColor: "#8E8E93",
          tabBarStyle: {
            backgroundColor: "#1C1C1E",
            borderTopColor: "#38383A",
          },
          headerStyle: { backgroundColor: "#1C1C1E" },
          headerTintColor: "#FFFFFF",
        }}
      >
        <Tabs.Screen
          name="index"
          options={{
            title: "Scanner",
            tabBarLabel: "Scan",
          }}
        />
        <Tabs.Screen
          name="firmware"
          options={{
            title: "Firmware",
            tabBarLabel: "Firmware",
          }}
        />
        <Tabs.Screen
          name="device/[id]"
          options={{
            href: null,
          }}
        />
      </Tabs>
    </>
  );
}
