# 🎓 Student Notes 

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)
![Provider](https://img.shields.io/badge/Provider-State_Management-blue?style=for-the-badge)

**Student Notes** is a comprehensive, production grade academic companion application built with Flutter. It provides students with instant access to course materials, advanced calculation tools, attendance tracking, and secure offline document viewing, all wrapped in a premium, theme-aware user interface.

---

## 🌟 Core Features

### 📚 Academic Resource Management
* **Subject & Unit Organization:** Structured access to academic materials (Notes, Question Papers, etc.) dynamically fetched and cached.
* **Universal Document Support:** Built-in support for rendering PDFs, DOCX, and PPTX files directly within the application.
* **Offline First Approach:** A robust `DownloadsService` allows students to save materials locally for offline reading, tracked via a dedicated Downloads tab.

### 🧮 Advanced Calculator Suite
* **Scientific Calculator:** Real-time mathematical expression evaluation using abstract syntax tree (AST) parsing (`math_expressions`).
* **Academic Calculators:** Precision-engineered CGPA, SGPA, and Percentage calculators strictly adhering to university (JNTU) standards.
* **Isolated History:** Independent local storage modules (`HistoryService` & `CalculatorHistoryService`) track academic vs. scientific calculations separately for a clutter-free experience.

### 📅 Smart Attendance Tracker
* **Dual-Mode Tracking:** Includes a "Quick Calculator" for hypothetical scenarios and an interactive "Daily Log" calendar.
* **Persistent State:** Saves daily statuses and history locally, allowing students to maintain accurate long-term attendance records.

### ☁️ Free-Tier Optimized Cloud Submissions
* **100MB File Uploads:** Users can securely submit their own notes/materials directly from the app.
* **Rate Limiting:** Enforced at the database level (max 5 submissions per day/user).
* **Automated Notifications:** Admin receives instant emails with direct, secure R2 download links upon successful submissions.

### 🎨 Modern UI/UX
* **Modular Architecture:** UI is broken down into highly reusable components (e.g., `HomeWelcomeSection`, `HomeNotesSection`).
* **Dynamic Theming:** Seamless global Dark Mode support utilizing `ThemeService`.

---

## 🏗️ Architecture & Tech Stack

* **Frontend Framework:** Flutter (Dart) utilizing Material 3 design guidelines.
* **State Management:** **Provider** (`home_provider.dart`), enabling centralized state control and eliminating legacy `setState` monoliths.
* **Backend:** 
  * **Firebase Auth:** Secure Google & Email authentication.
  * **Firestore Database:** NoSQL storage for user profiles, submission metadata, feedback, and rate-limiting counters.
  * **Firebase Remote Config:** Over-the-air (OTA) feature flags and forced/optional update dialogs (`UpdateService`).
* **Micro-Backend (Serverless):** **Cloudflare Workers**. Used to securely hold API keys and dispatch emails via the **Resend API**.
* **Storage:** **Cloudflare R2** buckets, replacing expensive Firebase Storage for handling large user submissions at zero cost.

---

## 🚀 How We Solved Problems & Maximized Efficiency

Building an app for thousands of students requires overtaking platform limitations and optimizing for performance and cost. Here is how we achieved maximum efficiency:

### 1. Bypassing Firebase Billing Limits (The 100MB Upload Problem)
**The Limitation:** Standard Firebase Cloud Functions require a paid Blaze plan. Storing large student uploads in Firebase Storage can quickly incur high costs.
**The Solution:** We engineered a completely free-tier serverless pipeline. 
* The Flutter app performs a direct `HTTP PUT` upload to a **Cloudflare R2 Bucket** (10GB free tier).
* A **Cloudflare Worker** acts as the secure micro-backend, catching the upload success and triggering the **Resend API** to email the admin. 
* **Efficiency:** Zero backend hosting costs, zero Cloud Functions required, and files up to 100MB are handled flawlessly.

### 2. Enforcing Intellectual Property & Security (The PDF Problem)
**The Limitation:** Opening downloaded academic materials in external viewers (like Adobe Reader) exposes the raw files to unauthorized sharing and distribution.
**The Solution:** We completely deprecated external `url_launcher` intents for local files.
* Implemented a secure, sandboxed `DocumentViewerScreen` utilizing `pdfx`.
* Files are managed via `PdfCacheService` and `DownloadManager`, ensuring they remain tightly coupled to the application's secure directory. Users can read offline, but cannot extract the raw files.

### 3. Untangling the UI (The God-Widget Problem)
**The Limitation:** Early iterations of the app suffered from a monolithic `home.dart` file relying heavily on `setState`, causing unnecessary widget rebuilds and making code maintenance a nightmare.
**The Solution:** 
* Migrated to **Provider**. 
* Extracted heavy UI blocks into `home_sections.dart`.
* The `AppScaffold` now dynamically listens to `HomeProvider` for tab routing and drawer navigation, resulting in buttery-smooth 60fps scrolling and instant tab switching.

### 4. Preventing Spam & Database Bloat
**The Limitation:** Open user submissions can lead to malicious spam, eating up Firestore read/write quotas.
**The Solution:** 
* Implemented strict **Firestore Security Rules**.
* Created a lightweight transaction document (`users/{uid}/limits/today`). The app checks this document in real-time, incrementing a counter. If the user hits 5 uploads, Firestore backend rules automatically reject further writes until the timezone rolls over to a new day.

### 5. Seamless Maintenance & Deprecation
**The Limitation:** Forcing users to update an app or taking the app down for maintenance usually breaks the user experience.
**The Solution:** Integrated `RemoteConfigService`. 
* We can instantly toggle a `MaintenanceScreen` globally.
* We can push non-intrusive "Optional Updates" or block access with "Force Updates" depending on the severity of the new release, entirely controlled from the cloud without requiring a new app store review.

---

## 🛡️ Security Rules

The application utilizes strict Firestore Security Rules to protect user data:
* `submissions`: Users can only `create`. Only the Admin UID/Email can `read` or `update`.
* `limits/today`: Users can only read and write to their own specific UID paths.
* `feedback`: Open to authenticated creation, locked for reading/deletion.

---
*Architected and built for the modern student. Maximum efficiency, zero compromises.*
