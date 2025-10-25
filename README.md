# Interest Calculator

A simple and elegant Flutter app to calculate interest between two dates with auto-formatting date inputs and smooth animations.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Material 3](https://img.shields.io/badge/Material%203-757575?style=flat&logo=material-design&logoColor=white)

## 📱 Features

- **Simple Interest Calculation**: Calculate interest between two dates with custom principal amount and interest rate
- **Smart Date Formatting**: Automatic dd/mm/yyyy formatting as you type with intelligent cursor positioning
- **Period Breakdown**: Shows time period as Years, Months, and Days
- **Beautiful UI**: Material 3 design with gradient accents and smooth animations
- **Input Validation**: Comprehensive error handling for dates, amounts, and rates
- **Copy Results**: One-tap copy of calculated results to clipboard
- **Responsive Design**: Clean, modern interface optimized for all screen sizes

## 🎯 Calculation Method

The app uses a simplified interest calculation:
- **Total Days** = |day difference| + (|month difference| × 30) + (|year difference| × 360)
- **Interest** = (Principal × Rate × (Total Days / 30)) / 100

The total period is then broken down into:
- Years (360 days per year)
- Months (30 days per month)
- Remaining days

## 📸 Screenshots
![app screenshot2](https://github.com/user-attachments/assets/c3295216-2633-4eda-8016-a7f3ab8516a0)
![app screenshot1](https://github.com/user-attachments/assets/fe92258d-dfe7-4221-902a-24494b289a69)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher recommended)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/interest-calculator.git
cd interest-calculator
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Build for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🏗️ Project Structure

```
lib/
└── main.dart                 # Main app with all components
    ├── DateTextInputFormatter  # Custom input formatter for date fields
    ├── InterestApp             # Root app widget
    └── InterestCalculatorPage  # Main calculator screen
```

## 🎨 Design

- **Color Scheme**: Indigo-based Material 3 theme with gradient accents (Blue → Violet → Pink)
- **Typography**: Roboto font family
- **Animations**: Fade and scale transitions for result display
- **Layout**: Card-based design with clean spacing and modern rounded corners

## 🔧 Technical Highlights

### Custom Date Input Formatter
- Regex-based digit extraction and formatting
- Intelligent cursor positioning after auto-inserted slashes
- Handles insertion, deletion, and paste operations
- Limits input to 8 digits (dd/mm/yyyy)

### State Management
- StatefulWidget with TextEditingController for form inputs
- AnimationController for smooth result transitions
- Auto-dismissing error messages (4-second timeout)

### Input Validation
- Date format validation (dd/mm/yyyy)
- Range checks for day (1-31), month (1-12), year (>0)
- Non-negative principal and interest rate validation
- User-friendly error messages

## 📋 Usage

1. **Enter From Date**: Type in dd/mm/yyyy format (slashes auto-inserted)
2. **Enter To Date**: Type in dd/mm/yyyy format
3. **Enter Amount**: Principal amount in ₹
4. **Enter Interest Rate**: Annual interest rate (e.g., 1.5 for 1.5%)
5. **Tap Calculate**: View the calculated interest and time breakdown
6. **Copy Result**: Tap "Copy" to copy result to clipboard
7. **Reset**: Tap "Reset" to clear result and calculate again

## 🛠️ Dependencies

This app uses only Flutter's core packages:
- `flutter/material.dart` - Material Design widgets
- `flutter/services.dart` - Input formatting and clipboard

No external dependencies required!

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Future Enhancements

- [ ] Multiple interest calculation methods (simple, compound, daily compound)
- [ ] Save calculation history
- [ ] Export results as PDF/CSV
- [ ] Dark mode support
- [ ] Localization for multiple languages
- [ ] Date picker integration
- [ ] Monthly breakdown graph

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Adithya**

- GitHub: [@yourusername](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for design inspiration
- Community contributors

---

**Made with ❤️ using Flutter**

*If you find this project useful, please consider giving it a ⭐ on GitHub!*
