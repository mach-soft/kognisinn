# Cognitive Profile & Training Platform

An advanced, cross-platform mobile application focused on rigorous cognitive enhancement and psychometric analytics. Built with **Flutter** and **Dart**, this project leverages adaptive learning algorithms to push the boundaries of working memory, attention, and visuospatial processing.

## 🔒 Privacy by Design & 100% Local Data

Cognitive performance and psychometric results are highly sensitive personal data. This application is engineered with a strict **local-first paradigm**:
* **Zero Cloud Sync:** No test results, progression histories, or cognitive profiles are ever transmitted to remote servers. 
* **On-Device Analytics:** All complex data mapping, median calculations, and chart generation are processed strictly locally.
* **Fully Offline:** The core application requires no internet connection to function, ensuring total user anonymity and data sovereignty.

## 🧠 Core Modules

* **Dual N-Back:** Features a scientifically accurate adaptive staircase algorithm with variable speeds and dynamic physiological ceilings.
* **eCorsi Block-Tapping:** Visuospatial memory assessment with forward and reverse modes, tracking max span capacity.
* **Digit Span:** Auditory and visual working memory training with customizable dictation speeds and progressive difficulty.
* **Memory Palace:** Advanced mnemonic training focusing on spatial and associative memory capacity.
* **Stroop Test:** Executive function and cognitive flexibility assessment.

## 📊 Architecture & Tech Stack

The application is built for high performance, utilizing clean architecture to handle rapid state changes and continuous data streams efficiently.

* **Framework:** Flutter / Dart
* **State Management:** `BLoC` (Business Logic Component) for predictable and scalable state transitions during fast-paced cognitive tasks.
* **Local Storage:** `SharedPreferences` optimized for fast, synchronous read/writes of time-series psychometric data.
* **Data Visualization:** Custom UI rendering and `fl_chart` integration for highly detailed, scrollable performance histories.
* **Localization:** Fully localized architecture utilizing `easy_localization`.

---

*Developed by [Mach Soft](https://github.com/mach-soft)*
