# 30 Minute Network Audit

## Tool Stack
| Stage               | Tool                                             | Platform      | Primary Role                                                   |
| :------------------ | :----------------------------------------------- | :------------ | :------------------------------------------------------------- |
| **1. Visual Proof** | **WiFi Analyzer** (by Gabor Juhos / WebProvider) | Android       | **Heatmaps** & Channel Overlap. (The "Red Zone" visual).       |
| **2. Deep Data**    | **analiti**                                      | Android       | **Protocol Analysis** & Speed. (The "Why it's slow" data).     |
| **3. Security**     | **Fing**                                         | iOS / Android | **Device Inventory** & Security. (The "Unknown Devices" list). |

---

## Stage 1: The Visual Map (Minutes 0–5)

*Goal: Create the "Red Zone" heatmap that clients immediately understand.*
*   **Tool:** **WiFi Analyzer** (Android)
*   **Action:**
    1.  Open the app and select the **"Map"** or **"Heatmap"** tab.
    2.  Upload a floor plan (or draw a rough box if you don't have one).
    3.  **Walk the house.** Tap the screen every 3–5 feet (or every room transition).
    4.  The app generates a color-coded map showing signal strength (RSSI) and channel congestion.
*   **The "Aha!" Moment:** Show the client the map. *"See this red area in the bedroom? That's a dead zone. The signal is dropping below -70dBm, which means your 4K stream will buffer."*
*   **Output:** Screenshot the heatmap.

## Stage 2: The Deep Technical Diagnosis (Minutes 5–10)

*Goal: Prove the *cause* of the slow speed (Interference vs. Signal).*
*   **Tool:** **analiti** (Android)
*   **Action:**
    1.  Connect to the Wi-Fi in the "Dead Zone" identified in Stage 1.
    2.  Open the **"Inspector"** or **"Speed Test"** tab.
    3.  **Check the MCS Rate:** Look for the Modulation and Coding Scheme. If it's low (e.g., 65 Mbps instead of 866 Mbps), the issue is **interference** or **distance**, not the ISP.
    4.  **Check Channel Utilization:** Show the graph. If the graph is red (100% full), you have **co-channel interference**.
*   **The "Aha!" Moment:** *"Your internet is 500 Mbps, but your phone is negotiating at 65 Mbps because your router is fighting with your neighbor's router on the same channel."*
*   **Output:** Screenshot the MCS chart and Channel Utilization graph.

## Stage 3: The Security & Inventory Audit (Minutes 10–15)

*Goal: Find the "bandwidth hogs" and security risks.*
*   **Tool:** **Fing** (iOS/Android)
*   **Action:**
    1.  Run a **"Network Scan"**.
    2.  **Identify IoT:** Look for devices named "Unknown," "Generic," or brands like "Xiaomi," "Tuya," "Generic."
    3.  **Check for "Jailbroken" or "Rooted" devices:** (If visible).
    4.  **Check for "Rogue" devices:** Any device not owned by the client.
*   **The "Aha!" Moment:** *"You have 22 devices on your network. 8 of them are 'Unknown' IoT devices. These are often insecure and eating up your bandwidth with background updates."*
*   **Output:** Screenshot the device list.

---

## Report Assembly (Minutes 15–18)

*Do not leave without a deliverable.*

**1. Open a Note App or Canva.**
**Paste the 3 Screenshots:**
- Image 1: The Heatmap (Visual Proof).
- Image 2: The MCS/Channel Graph (Technical Proof).
- Image 3: The Device List (Security Proof).

**2. Add 3 Bullet Points**
- **Issue 1:** "Dead Zone in Master Bedroom (-75dBm)."
- **Issue 2:** "High Interference on Channel 6 (80% Utilization)."
- *Issue 3:** "8 Unknown IoT Devices detected."

**3. Email it to the client** before you leave.** 
*"Here is your free audit. As you can see, the network is struggling with X, Y, and Z. If you'd like a formal proposal to fix this, just reply."*
