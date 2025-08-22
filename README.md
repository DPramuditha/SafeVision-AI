<div align="center">

# 👁️ SafeVision
### *AI-Powered Drowsiness Detection & Safety Monitoring*

<img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=22&duration=3000&pause=1000&color=4ECDC4&center=true&vCenter=true&width=435&lines=Stay+Alert%2C+Stay+Safe!;Real-time+Face+Detection;Flutter+%2B+ML+Kit+Powered;Your+Personal+Safety+Guardian" alt="Typing SVG" />

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![ML Kit](https://img.shields.io/badge/Google_ML_Kit-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)

<p align="center">
  <img src="https://user-images.githubusercontent.com/74038190/212284100-561aa473-3905-4a80-b561-0d28506553ee.gif" width="700">
</p>

*SafeVision is an intelligent Flutter application that uses advanced machine learning to detect drowsiness and fatigue in real-time, helping prevent accidents and promote safety.*

</div>

---

## 🌟 Features That Make SafeVision Special

<table>
<tr>
<td width="50%">

### 🎯 **Core Capabilities**
- 👁️ **Real-time Face Detection** - Advanced ML Kit integration
- 😴 **Drowsiness Monitoring** - Smart eye closure detection
- 🚨 **Instant Alerts** - Audio & haptic feedback
- 📊 **Blink Rate Analysis** - Fatigue level assessment
- 🎥 **Live Camera Feed** - Front-facing camera integration
- 📱 **Cross-platform** - iOS & Android support

</td>
<td width="50%">

### ⚡ **Smart Features**
- 🌤️ **Weather Integration** - Environmental monitoring
- 🗺️ **Location Services** - GPS tracking capability
- 🔊 **Audio Alerts** - Custom sound notifications
- 📈 **Session Analytics** - Detailed monitoring stats
- 🎨 **Animated UI** - Smooth, engaging interface
- 🔐 **Firebase Backend** - Secure data management

</td>
</tr>
</table>

---

## 🎬 Demo & Screenshots

<div align="center">

### 📱 **App Interface**

<p align="center">
  <img src="assets/screenshot.png" alt="SafeVision App Screenshot" width="600">
</p>

*Real-time drowsiness detection in action - SafeVision monitoring interface*

</div>

---

## 🏗️ **Architecture & Tech Stack**

<div align="center">

```mermaid
graph TD
    A[📱 Flutter App] --> B[📷 Camera Module]
    A --> C[🧠 ML Kit Face Detection]
    A --> D[🔊 Audio System]
    A --> E[🌐 Firebase Backend]
    
    B --> F[👁️ Real-time Stream]
    C --> G[😴 Drowsiness Analysis]
    D --> H[🚨 Alert System]
    E --> I[☁️ Data Storage]
    
    F --> J[📊 Processing Engine]
    G --> J
    J --> K[⚡ Real-time Alerts]
```

</div>

### 🛠️ **Technologies Used**

<div align="center">

| Category | Technology | Purpose |
|----------|------------|---------|
| 🎨 **Frontend** | Flutter 3.7.2+ | Cross-platform UI |
| 🧠 **AI/ML** | Google ML Kit | Face detection & analysis |
| 📷 **Camera** | Camera Plugin | Real-time video capture |
| 🔊 **Audio** | AudioPlayers | Alert sound management |
| ☁️ **Backend** | Firebase | Authentication & storage |
| 🎬 **Animation** | Flutter Animate | Smooth UI transitions |
| 🎭 **Graphics** | Lottie | Complex animations |
| 🌍 **Location** | Geolocator | GPS services |

</div>

---

## 🚀 **Getting Started**

<div align="center">
  <img src="https://user-images.githubusercontent.com/74038190/212284087-bbe7e430-757e-4901-90bf-4cd2ce3e1852.gif" width="500">
</div>

### 📋 **Prerequisites**

Before you begin, ensure you have:

- ✅ **Flutter SDK** (3.7.2 or higher)
- ✅ **Dart SDK** (compatible version)
- ✅ **Android Studio** / **VS Code**
- ✅ **Firebase Account**
- ✅ **Physical Device** (for camera testing)

### 🔧 **Installation Steps**

1. **Clone the Repository**
   ```bash
   git clone https://github.com/DPramuditha/-SafeVision.git
   cd SafeVision
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   ```bash
   # Add your firebase configuration files:
   # - android/app/google-services.json
   # - ios/Runner/GoogleService-Info.plist
   ```

4. **Environment Configuration**
   ```bash
   # Create .env file in root directory
   cp .env.example .env
   # Add your API keys and configuration
   ```

5. **Run the Application**
   ```bash
   flutter run
   ```

---

## ⚙️ **Configuration**

### 🔑 **Environment Variables**

Create a `.env` file in the project root:

```env
# Weather API (Optional)
WEATHER_API_KEY=your_weather_api_key_here

# Firebase Configuration (Auto-generated)
FIREBASE_PROJECT_ID=your_project_id
```

### 🔥 **Firebase Setup**

1. Create a new Firebase project
2. Enable **Authentication** and **Firestore**
3. Download configuration files
4. Place them in respective platform folders

---

## 📱 **Usage Guide**

<div align="center">

### 🎯 **How to Use SafeVision**

</div>

1. **🚀 Launch the App**
   - Open SafeVision on your device
   - Grant camera and microphone permissions

2. **👁️ Position Your Face**
   - Ensure good lighting conditions
   - Keep your face centered in the camera view

3. **▶️ Start Monitoring**
   - Tap the "Start Monitoring" button
   - The app begins real-time face detection

4. **📊 Monitor Your Status**
   - View live blink rate statistics
   - Check drowsiness indicators
   - Receive instant alerts when needed

5. **🛑 End Session**
   - Tap "Stop Monitoring" to end
   - Review your session statistics

---

## 🎨 **Key Components**

### 📷 **Face Detection Engine**

```dart
// Example: Initializing face detection
final options = FaceDetectorOptions(
  enableContours: true,
  enableClassification: true,
  enableTracking: true,
  performanceMode: FaceDetectorMode.fast,
  minFaceSize: 0.05,
);
_faceDetector = FaceDetector(options: options);
```

### 🚨 **Alert System**

```dart
// Example: Triggering fatigue alert
void _triggerFatigueAlert(String message) {
  HapticFeedback.heavyImpact();
  _playAlertSound();
  _showVisualAlert(message);
}
```

---

## 📊 **Features Deep Dive**

<details>
<summary>👁️ <strong>Eye Tracking & Analysis</strong></summary>

- **Real-time Eye Detection**: Uses ML Kit's face detection API
- **Blink Rate Calculation**: Monitors blinks per minute
- **Eye Closure Duration**: Detects prolonged eye closure
- **Fatigue Scoring**: Advanced algorithms assess tiredness levels

</details>

<details>
<summary>🚨 <strong>Alert Mechanisms</strong></summary>

- **Visual Alerts**: Screen overlays and animations
- **Audio Alerts**: Customizable alarm sounds
- **Haptic Feedback**: Vibration patterns
- **Progressive Alerting**: Escalating alert intensity

</details>

<details>
<summary>📈 <strong>Analytics & Reporting</strong></summary>

- **Session Tracking**: Monitor usage patterns
- **Blink Statistics**: Detailed blink analysis
- **Alert History**: Track alert frequency
- **Performance Metrics**: App performance monitoring

</details>

<details>
<summary>🌍 <strong>Smart Integrations</strong></summary>

- **Weather Data**: Environmental context
- **Location Services**: GPS-based features
- **Firebase Sync**: Cloud data synchronization
- **Cross-platform**: iOS and Android support

</details>

---

## 🧪 **Testing**

### 🔬 **Running Tests**

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

### 📱 **Device Testing**

- **Physical Device Required**: Camera functionality needs real hardware
- **iOS Testing**: Requires iOS 11.0+
- **Android Testing**: Requires API level 21+

---

## 🤝 **Contributing**

<div align="center">
  <img src="https://user-images.githubusercontent.com/74038190/212284115-f47cd8ff-2ffb-4b04-b5bf-4d1c14c0247f.gif" width="400">
</div>

We welcome contributions! Here's how you can help:

### 🎯 **Ways to Contribute**

- 🐛 **Bug Reports**: Found an issue? Let us know!
- ✨ **Feature Requests**: Have ideas? Share them!
- 🧹 **Code Improvements**: Submit PRs for enhancements
- 📚 **Documentation**: Help improve our docs
- 🧪 **Testing**: Help us test on different devices

### 📝 **Contribution Process**

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

---

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 **Acknowledgments**

<div align="center">

### 💖 **Special Thanks To**

- **Google ML Kit Team** - For powerful face detection APIs
- **Flutter Team** - For the amazing framework
- **Firebase Team** - For reliable backend services
- **Open Source Community** - For inspiration and support

</div>

---

## 📞 **Contact & Support**

<div align="center">

### 🤔 **Need Help?**

<p align="center">
  <a href="mailto:your-email@example.com">
    <img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white" alt="Email"/>
  </a>
  <a href="https://github.com/DPramuditha/-SafeVision/issues">
    <img src="https://img.shields.io/badge/Issues-2ea44f?style=for-the-badge&logo=github&logoColor=white" alt="Issues"/>
  </a>
  <a href="https://github.com/DPramuditha/-SafeVision/discussions">
    <img src="https://img.shields.io/badge/Discussions-blueviolet?style=for-the-badge&logo=github&logoColor=white" alt="Discussions"/>
  </a>
</p>

</div>

---

<div align="center">

### 🌟 **Star This Repository**

<p align="center">
  <img src="https://user-images.githubusercontent.com/74038190/212284158-e840e285-664b-44d7-b79b-e264b5e54825.gif" width="200">
</p>

**If SafeVision helped you stay safe, please consider giving it a ⭐!**

<p align="center">
  <i>Made with ❤️ and lots of ☕ by the SafeVision Team</i>
</p>

<p align="center">
  <img src="https://forthebadge.com/images/badges/built-with-love.svg" alt="Built with Love"/>
  <img src="https://forthebadge.com/images/badges/powered-by-coffee.svg" alt="Powered by Coffee"/>
</p>

---

<sub>🚗 **Drive Safe, Stay Alert, Use SafeVision!** 🚗</sub>

</div>
