# Kognisinn: Privacy-First Neurocognitive Trainer

A scientifically grounded, 100% offline mobile application for cognitive assessment and training. Developed with an emphasis on absolute data privacy, Kognisinn features industry-standard tests to help you measure and expand your cognitive baseline.

*All data stays on your device. No ads. No hidden tracking.*

---

## 📱 Screenshots

<table align="center">
  <tr>
    <th align="center">Cognitive Profile</th>
    <th align="center">Dual N-Back</th>
    <th align="center">Analytics</th>
    <th align="center">Main menu (Light)</th>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/26295c62-071b-48df-8255-cac65e604b01" width="250"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/4253c7f1-fe71-46c4-a03d-d4ae538b07ec" width="250"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/9de143c0-19d9-412a-9998-340ba23d201b" width="250"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/4063be96-159e-499f-9eed-e41b9cd0b740" width="250"></td>
  </tr>
</table>

---

## 🧠 Core Modules

Kognisinn integrates five scientifically validated cognitive tasks, each targeting a specific executive function:

* **Dual N-Back:** Enhances working memory capacity and fluid intelligence. Features both adaptive and manual modes.
* **Stroop Test:** Measures cognitive flexibility and the ability to suppress automatic responses (inhibition).
* **Digit Span:** Tests numerical working memory and active mental manipulation (forward, reverse, ascending, n-back).
* **eCorsi Test:** Evaluates visuospatial memory and spatial orientation capacity.
* **Memory Palace:** Trains associative memory and visualization skills using the Method of Loci.

---

## 🔒 Privacy & Architecture

This application was built from the ground up to respect user privacy. 

* **100% Offline:** The core app does not require an internet connection to function.
* **Local Storage:** All cognitive metrics, history, and user settings are stored securely and locally via `SharedPreferences`.
* **No Third-Party Analytics:** The standard release contains zero tracking software or ad networks.

### 🐛 Public Beta Note (Telemetry Enabled)
*Currently, the provided `app-release.apk` in the Releases section is a **Public Beta** build. For testing purposes only, this specific build includes a user-feedback module (Wiredash) and basic crash reporting (Firebase) to help identify bugs across different Android devices. The final production release will have all telemetry strictly disabled.*

---

## 🚀 Installation (Android)

Since Kognisinn is currently in early beta, it is distributed directly via GitHub Releases (Sideloading).

1. Go to the [Releases](../../releases) page of this repository.
2. Download the latest `app-release.apk` file under the **Assets** section.
3. Open the downloaded file on your Android device. 
4. If prompted, grant your browser or file manager permission to "Install unknown apps".
5. Install and launch Kognisinn.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/)
* **State Management:** [BLoC / Cubit](https://bloclibrary.dev/)
* **Localization:** Native JSON (cs, en, de)
* **Storage:** Shared Preferences

---

## 📝 License & Copyright

**© 2026 Mach Soft. All Rights Reserved.**

This repository and its source code are provided strictly for **educational, portfolio evaluation, and review purposes**. 

While the code is publicly visible, it is **not** open-source. You are granted limited permission to download, clone, compile, and run the software locally **solely for the purpose of evaluating and reviewing** the code and application functionality.

You may **not** distribute, modify, create derivative works, publish, or use any part of this software for any personal or commercial projects without explicit written permission from the author.
