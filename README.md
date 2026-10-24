# 📚 Lucid Pages — Story Reading & Publishing Platform

**Lucid Pages** is a cross-platform story-reading and publishing application built with **Flutter and Dart** for Android, iOS, and Web. It provides a platform for readers to explore stories and for authors to create, edit, publish, and manage their books and episodes.

The application integrates Firebase services for authentication and cloud-based data storage. It is currently in the testing phase.

## ✨ Features

- **User Authentication:** Register and log in using Firebase Authentication.
- **Story Reading:** Explore and read published stories.
- **Story Publishing:** Create, edit, and manage books and episodes.
- **Rich-Text Formatting:** Format story content for a better reading experience.
- **Content Visibility:** Support for public and private content.
- **Cloud Database:** Store and manage user profiles and story content using Cloud Firestore.
- **Cross-Platform Support:** Developed for Android, iOS, and Web.
- **Web Hosting:** Deploy the web application using Firebase Hosting.
- **AI-Assisted Development:** Use OpenAI Codex and ChatGPT to assist with implementation, debugging, and problem-solving.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Firebase Authentication | User registration and login |
| Cloud Firestore | Cloud-based data storage |
| Firebase Hosting | Web application deployment |
| OpenAI Codex & ChatGPT | AI-assisted development |

## 📱 Supported Platforms

- Android
- iOS
- Web

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/)
- A Firebase project configured for the application

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/pavansaireddythota/lucid-pages-flutter.git
```

**2. Navigate to the project directory**

```bash
cd lucidpages
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Configure Firebase**

Configure the Firebase project for your target platforms. Ensure the required Firebase configuration files and FlutterFire setup are in place.

**5. Run the application**

For Android or an available connected device:

```bash
flutter run
```

To run the web application:

```bash
flutter run -d chrome
```

## 🌐 Web Deployment

Lucid Pages uses Firebase Hosting for web deployment.

Build the web application:

```bash
flutter build web
```

Deploy it using the Firebase CLI after configuring the appropriate Firebase Hosting project:

```bash
firebase deploy --only hosting
```

## 📂 Project Overview

Lucid Pages is designed to bring readers and authors together through a digital storytelling platform. The project focuses on cross-platform accessibility, content creation, story management, and Firebase integration.

## 🧪 Project Status

**Currently in the testing phase.**

Features and functionality may change as development and testing continue.

## 🔮 Future Improvements

- Enhance the story discovery and browsing experience.
- Improve reading customization and accessibility.
- Expand author and content management capabilities.
- Improve application performance and responsiveness.
- Add further features based on testing and user feedback.

## 👨‍💻 Developer

**Pavan Sai Reddy Thota**

Mobile Application Developer | Flutter | React Native | Firebase

## 📄 License

A license has not yet been specified for this repository. All rights are reserved by the copyright holder unless a license is added.

---

*Built with Flutter, Dart, Firebase, and AI-assisted development tools.*
