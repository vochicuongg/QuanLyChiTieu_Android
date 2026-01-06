# 💰 VFinance - Quản Lý Chi Tiêu Cá Nhân (Android)

<p align="center">
  <a href="">
    <img src="assets/logo.png" alt="VFinance Logo" width="150" height="150">
  </a>
</p>

<p align="center">
  <i>Quản lý tài chính thông minh, nắm bắt tương lai vững vàng.</i>
</p>

---

**VFinance** là ứng dụng quản lý tài chính cá nhân thông minh được xây dựng bằng **Flutter**, giúp người dùng theo dõi thu nhập, chi tiêu, quản lý ngân sách và phân tích thói quen tài chính trực quan. Ứng dụng hỗ trợ đồng bộ hóa dữ liệu thời gian thực qua **Firebase Cloud Firestore**.

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.4-blue.svg?style=flat-square&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Core-orange.svg?style=flat-square&logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Android-green.svg?style=flat-square&logo=android)

</div>

## ✨ Tính Năng Nổi Bật

### 📊 1. Quản Lý & Thống Kê
*   **Dashboard trực quan:** Hiển thị số dư hiện tại, tổng thu/chi trong tháng với giao diện thẻ Gradient động (Animated Gradient).
*   **Ghi chép nhanh:** Thêm giao dịch chi tiêu/thu nhập theo danh mục (Ăn uống, Di chuyển, Mua sắm, v.v.).
*   **Biểu đồ phân tích (Statistics):**
    *   **Pie Chart:** Xem tỷ lệ phần trăm chi tiêu theo danh mục.
    *   **Comparison Mode (Mới):** So sánh chi tiêu giữa tháng hiện tại và tháng trước (hoặc kỳ bất kỳ) bằng biểu đồ cột đôi và danh sách chênh lệch (Delta View).
*   **Lịch sử chi tiết:** Xem lại lịch sử giao dịch theo ngày/tháng.

### ☁️ 2. Công Nghệ & Đồng Bộ
*   **Cloud First:** Dữ liệu được lưu trữ và đồng bộ thời gian thực trên Firebase Firestore. Đăng nhập trên nhiều thiết bị vẫn giữ nguyên dữ liệu.
*   **Guest Mode:** Hỗ trợ dùng thử không cần đăng nhập. Tự động di chuyển dữ liệu (Migration) khi người dùng quyết định tạo tài khoản.
*   **Bảo mật:** Xác thực người dùng qua Firebase Authentication.

### 🎨 3. Trải Nghiệm Người Dùng (UX/UI)
*   **Dark/Light Mode:** Hỗ trợ giao diện Sáng/Tối tuỳ chỉnh hoặc theo hệ thống.
*   **Đa ngôn ngữ:** Hỗ trợ Tiếng Việt (Vi) và Tiếng Anh (En).
*   **Thông báo thông minh:** Nhắc nhở ghi chép chi tiêu vào các khung giờ vàng (Sáng, Trưa, Chiều, Tối) với lời chào thân thiện.
*   **In-App Update:** Tự động kiểm tra và cập nhật phiên bản mới nhất từ server.

---

## 🛠 Công Nghệ Sử Dụng (Tech Stack)

Dự án được xây dựng dựa trên các thư viện Flutter mạnh mẽ nhất hiện nay:

| Core | UI & Tiện ích | Backend (Firebase) |
| :--- | :--- | :--- |
| **Flutter SDK** | `fl_chart` (Biểu đồ) | `firebase_auth` (Đăng nhập) |
| **Dart** | `flutter_local_notifications` | `cloud_firestore` (Database) |
| `provider` / Streams | `shared_preferences` (Cache) | `firebase_core` |
| | `url_launcher` | |

---

## 📂 Cấu Trúc Dự Án

```text
lib/
├── main.dart                  # Entry point & Theme configuration
├── models/                    # Data Models
│   ├── expense_categories.dart  # Định nghĩa danh mục chi tiêu
│   └── comparison_model.dart    # Model cho tính năng so sánh
├── screens/                   # Các màn hình chính
│   ├── home_screen.dart         # Trang chủ (Dashboard)
│   ├── statistics_screen.dart   # Thống kê & So sánh
│   ├── budget_screen.dart       # Quản lý ngân sách
│   ├── history_screen.dart      # Lịch sử giao dịch
│   ├── settings_screen.dart     # Cài đặt (Theme, Language)
│   └── login_screen.dart        # Màn hình đăng nhập
├── services/                  # Business Logic & Backend interaction
│   ├── auth_service.dart        # Xử lý đăng nhập/đăng xuất
│   ├── database_service.dart    # Tương tác Firestore (CRUD)
│   ├── transaction_service.dart # Quản lý luồng dữ liệu giao dịch
│   ├── notification_service.dart# Quản lý thông báo đẩy
│   └── update_service.dart      # Kiểm tra cập nhật ứng dụng
└── widgets/                   # Các Widget tái sử dụng
    ├── animated_gradient_card.dart # Thẻ nền chuyển màu
    ├── comparison_chart.dart       # Biểu đồ so sánh
    ├── delta_list_view.dart        # Danh sách chênh lệch chi tiêu
    └── ...
```

---

## 🚀 Hướng Dẫn Cài Đặt (Development)

Để chạy dự án này trên máy local, bạn cần cài đặt Flutter SDK.

### Bước 1: Clone dự án
```bash
git clone https://github.com/vochicuongg/quanlychitieu_android.git
cd vfinance_phone
```

### Bước 2: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 3: Cấu hình Firebase
> ⚠️ **Lưu ý:** Dự án này yêu cầu file cấu hình `google-services.json` từ Firebase.

1. Truy cập [Firebase Console](https://console.firebase.google.com/).
2. Tạo project mới hoặc sử dụng project có sẵn.
3. Thêm ứng dụng Android với package name: `com.chiscung.vfinance_phone`.
4. Tải file `google-services.json` và đặt vào thư mục:
   `android/app/google-services.json`

### Bước 4: Chạy ứng dụng
Kết nối thiết bị Android hoặc bật Emulator và chạy lệnh:
```bash
flutter run
```

---

## 📸 Hình Ảnh Demo

| Dashboard (Dark) | Statistics (Pie) | Comparison (Bar) | Settings |
| :---: | :---: | :---: | :---: |
| <img src="assets/screenshots/dashboard.png" width="200" alt="Dashboard"> | <img src="assets/screenshots/stats.png" width="200" alt="Stats"> | <img src="assets/screenshots/comparison.png" width="200" alt="Comparison"> | <img src="assets/screenshots/settings.png" width="200" alt="Settings"> |

*(Lưu ý: Thay thế đường dẫn ảnh bằng ảnh chụp màn hình thực tế của bạn)*

---

## 🤝 Đóng Góp

Mọi đóng góp đều được hoan nghênh! Nếu bạn tìm thấy lỗi hoặc muốn đề xuất tính năng mới:

1. **Fork** dự án.
2. Tạo **branch** mới (`git checkout -b feature/AmazingFeature`).
3. **Commit** thay đổi (`git commit -m 'Add some AmazingFeature'`).
4. **Push** lên branch (`git push origin feature/AmazingFeature`).
5. Tạo **Pull Request**.

---

## 📞 Liên Hệ

*   **Tác giả:** Võ Chí Cường
*   **Email:** [Email của bạn]
*   **GitHub:** [vochicuongg](https://github.com/vochicuongg)

---

<p align="center">
  © 2024 VFinance. All Rights Reserved.
</p>
