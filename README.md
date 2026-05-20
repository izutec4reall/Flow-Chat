# Flow - تطبيق مراسلة فوري 💬

**Flow** هو تطبيق مراسلة فوري مفتوح المصدر مبني بـ **Flutter**، مصمم لمجموعات صغيرة من الأصدقاء. يتيح إرسال الرسائل النصية والصور والفيديو والرسائل الصوتية مع دعم كامل للمجموعات ونظام صلاحيات متقدم.

> مبني بالكامل على خدمات سحابية مجانية: Firebase (Spark Plan) + Cloudinary (Free Tier)

---

## 📋 المحتويات

- [المميزات](#-المميزات)
- [لقطة سريعة على التقنية](#-لقطة-سريعة-على-التقنية)
- [هيكلة المشروع](#-هيكلة-المشروع)
- [البنية المعمارية](#-البنية-المعمارية)
- [الشاشات والواجهات](#-الشاشات-والواجهات)
- [التصميم والثيم](#-التصميم-والثيم)
- [طبقة البيانات](#-طبقة-البيانات)
- [المكتبات المستخدمة](#-المكتبات-المستخدمة)
- [التنقل بين الشاشات](#-التنقل-بين-الشاشات)
- [كيفية التشغيل](#-كيفية-التشغيل)

---

## ✨ المميزات

### 🔐 المصادقة
- تسجيل الدخول وإنشاء حساب بالبريد الإلكتروني وكلمة المرور
- إعادة تعيين كلمة المرور عبر البريد الإلكتروني
- جلسة مستمرة (Session Persistence) عبر `authStateChanges()`
- تسجيل الخروج مع تعيين حالة المستخدم Offline تلقائياً

### 💬 المراسلة الفورية (نص، صورة، فيديو، صوت)
- **رسائل نصية** مع دعم الإشارات `@Mention` في المجموعات
- **مشاركة الصور** مع رفع متعدد الصور إلى Cloudinary وواجهة Pending أثناء الرفع
- **مشاركة الفيديو** مع رفع إلى Cloudinary وأيقونة تشغيل
- **الرسائل الصوتية** تسجيل بالضغط المطول على المايك والإرسال تلقائياً عند رفع الإصبع
- **الرد على الرسائل** بالسحب لليمين (Swipe-to-Reply)
- **التفاعلات** إيموجي رياكشنز: ❤️ 😂 😮 😢 🔥 👍
- **تثبيت الرسائل** للمشرفين (Pinned Messages)
- **نسخ النص** إلى الحافظة
- **حذف الرسائل**
- **البحث داخل المحادثة**

### 👥 المجموعات (نظام متكامل)
- **إنشاء مجموعة** مع اختيار الأعضاء وصورة المجموعة
- **صلاحيات دقيقة** لكل مجموعة:
  - إرسال الرسائل
  - إرسال الوسائط
  - إضافة مستخدمين
  - تثبيت الرسائل
  - تغيير معلومات المجموعة
- **أنواع المجموعات**: عامة (Public) أو خاصة (Private) مع طلبات الانضمام
- **رتب المشرفين**: Owner، Admin مع ألقاب مخصصة
- **Slow Mode**: فترة تهدئة بين الرسائل (0-3600 ثانية)
- **روابط الدعوة**: إنشاء روابط انضمام مع تسميات
- **حظر المستخدمين**: قائمة محظورين مع إمكانية إلغاء الحظر
- **سجل النشاطات**: تسجيل جميع إجراءات المشرفين
- **إدارة الأعضاء**: إضافة/إزالة/تعيين مشرف/طرد

### 👤 الملفات الشخصية
- **صورة الملف الشخصي** مع Hero Animation
- **صورة الغلاف** مع تدرج لوني احتياطي
- **الحالة**: أونلاين/أوفلاين/آخر ظهور
- **الأوسمة**: User, VIP, Admin, Developer (مرمزة بالألوان)
- **معرض الوسائط** (صور مشتركة)
- **أزرار التواصل**: إرسال رسالة، اتصال، فيديو، مشاركة، حظر
- **التحكم في الرتب** للمشرفين والديڤلوبر

### 🎨 التصميم والثيم
- **Material 3** بالكامل مع `ColorScheme` مخصص
- **ثيم فاتح وداكن** مع دعم OLED الأسود النقي (#000000)
- **حفظ التفضيلات** عبر SharedPreferences
- **Google Fonts**: Poppins للعناوين، Inter للنصوص

### 🔔 الإشعارات
- Firebase Cloud Messaging مهيأ (جاهز للإشعارات الفورية)

### 🟢 الحضور (Presence)
- كشف الحضور عبر Firebase Realtime Database مع `onDisconnect()`
- مزامنة الحالة مع Firestore
- مؤشر "يكتب..." في الوقت الفعلي

---

## 🛠 لقطة سريعة على التقنية

```
الإطار            : Flutter (Dart)
اللغة             : Dart
الحالة            : نشط قيد التطوير
قاعدة البيانات    : Cloud Firestore + Firebase Realtime Database
التخزين الوسائط   : Cloudinary
المصادقة          : Firebase Auth (Email/Password)
الإشعارات         : Firebase Cloud Messaging
إدارة الحالة      : Provider (للثيم فقط)
التصميم           : Material 3
الخطوط            : Google Fonts (Poppins + Inter)
الحد الأدنى SDK   : Flutter default
الإصدار           : 1.0.0+1
```

---

## 📁 هيكلة المشروع

```
lib/
├── main.dart                     # نقطة الدخول + MaterialApp + Provider
├── firebase_options.dart         # إعدادات Firebase (مولّد تلقائي)
├── models/
│   ├── chat_model.dart           # نموذج المحادثة
│   ├── group_models.dart         # نماذج المجموعات (دعوات، صلاحيات، إلخ)
│   ├── message_model.dart        # نموذج الرسالة
│   └── user_model.dart           # نموذج المستخدم
├── screens/
│   ├── auth/
│   │   ├── auth_wrapper.dart     # موجه المصادقة
│   │   ├── login_screen.dart     # شاشة تسجيل الدخول
│   │   └── signup_screen.dart    # شاشة إنشاء حساب
│   ├── splash/
│   │   └── splash_screen.dart    # شاشة البداية المتحركة
│   ├── home/
│   │   ├── home_screen.dart      # الشاشة الرئيسية
│   │   ├── contacts_screen.dart  # قائمة جهات الاتصال
│   │   ├── new_chat_screen.dart  # بدء محادثة جديدة
│   │   └── new_group_screen.dart # إنشاء مجموعة جديدة
│   ├── chat/
│   │   ├── chat_screen.dart      # شاشة المحادثة
│   │   ├── full_screen_image_viewer.dart # عرض الصورة كامل
│   │   ├── add_group_members_screen.dart # إضافة أعضاء للمجموعة
│   │   ├── group_info_screen.dart   # معلومات المجموعة
│   │   ├── group_management_screen.dart # إدارة المجموعة
│   │   ├── group_members_screen.dart  # أعضاء المجموعة
│   │   ├── join_requests_screen.dart  # طلبات الانضمام
│   │   └── user_profile_screen.dart   # الملف الشخصي
│   └── settings/
│       ├── settings_screen.dart        # الإعدادات
│       ├── account_settings.dart       # إعدادات الحساب
│       ├── appearance_settings.dart    # إعدادات المظهر
│       └── notification_settings.dart  # إعدادات الإشعارات
├── services/
│   ├── auth_service.dart           # خدمة المصادقة
│   ├── chat_service.dart           # خدمة المحادثات
│   ├── cloudinary_service.dart     # خدمة رفع الوسائط
│   ├── media_service.dart          # خدمة اختيار الوسائط
│   ├── message_service.dart        # خدمة الرسائل
│   ├── presence_service.dart       # خدمة الحضور (Presence)
│   ├── user_service.dart           # خدمة المستخدمين
│   └── voice_recorder_service.dart # خدمة التسجيل الصوتي
├── theme/
│   ├── app_colors.dart             # ألوان التطبيق
│   ├── app_text_styles.dart        # أنماط النصوص
│   ├── app_theme.dart              # الثيم الرئيسي
│   └── theme_provider.dart         # مزود الثيم (ChangeNotifier)
├── utils/
│   ├── constants.dart              # الثوابت
│   └── date_formatter.dart         # تنسيق التاريخ
└── widgets/
    ├── bottom_nav_bar.dart         # شريط التنقل السفلي
    ├── chat_list_item.dart         # عنصر قائمة المحادثات
    ├── message_bubble.dart         # فقاعة الرسالة
    ├── message_input.dart          # حقل إدخال الرسالة
    └── voice_message_player.dart   # مشغل الرسائل الصوتية
```

---

## 🏗 البنية المعمارية

### النمط: Service-based Architecture (MVVM-like مع Provider)

التطبيق لا يستخدم Clean Architecture. بدلاً من ذلك، يتبع نمطاً بسيطاً يعتمد على **الخدمات**:

```
Models (Data Classes)
    ↓
Services (Business Logic + Firebase Operations)
    ↓
Screens (UI + State via StreamBuilder/FutureBuilder)
    ↓
Widgets (Reusable Components)
```

**مبادئ أساسية:**
- **Models**: كلاسات بيانات مع `fromMap`/`toMap` للتعامل مع Firestore
- **Services**: تحتوي كل المنطق التجاري وعمليات Firebase
- **Provider**: يُستخدم فقط لـ `ThemeProvider` (إدارة الثيم)
- **Real-time**: عبر `StreamBuilder` مع Firestore streams
- **Offline**: تمكين Firebase Offline Persistence مع كاش غير محدود
- **Images**: تحميل مؤقت (Pending) مع عرض Optimistic UI

---

## 📱 الشاشات والواجهات

### شاشة البداية (SplashScreen)
- خلفية متدرجة (Gradient)
- أنيميشن شعار بــ ScaleTransition (elastic bounce) + FadeTransition
- نص "Flow" + "Stay Connected"
- مدة الأنيميشن: 2.2 ثانية

### شاشات المصادقة
| الشاشة | الوصف |
|--------|-------|
| **LoginScreen** | شعار Flow، حقل البريد الإلكتروني، كلمة المرور، "نسيت كلمة المرور" زر الدخول، زر Google (غير مفعل)، رابط التسجيل |
| **SignupScreen** | سهم رجوع، شعار، "Join Flow"، الاسم الكامل، البريد، كلمة المرور، زر التسجيل، رابط تسجيل الدخول |

### الشاشة الرئيسية (HomeScreen)
- AppBar بعنوان "Flow" وأيقونة الإعدادات
- شريط بحث فوق قائمة المحادثات
- Drawer جانبي مع معلومات المستخدم/الصورة/الوسام/الإعدادات/تسجيل الخروج
- FAB لبدء محادثة/مجموعة جديدة
- BottomNavBar (محادثات + إعدادات)
- `IndexedStack` للتبديل بين التبويبات

### شاشات المحادثة
| الشاشة | الوصف |
|--------|-------|
| **ChatScreen** | AppBar مع avatar + الاسم + حالة الأونلاين + مؤشر الكتابة، شريط الرسائل المثبتة، قائمة الرسائل (مقلوبة)، شريط الرد، حقل الإدخال مع أزرار الصور/الفيديو/الصوت |
| **FullScreenImageViewer** | خلفية سوداء، Hero Animation، تكبير/تصغير باللمس والضغط |
| **MessageBubble** | فقاعة رسالة مع: المحتوى، وقت الإرسال، علامة القراءة، الردود، التفاعلات، قائمة منبثقة للنسخ/الحذف/التثبيت |

### شاشات المجموعات
| الشاشة | الوصف |
|--------|-------|
| **GroupInfoScreen** | SliverAppBar (250px) بصورة المجموعة، pending requests للأدمن، أزرار سريعة (بحث/رابط دعوة/مغادرة)، قائمة الأعضاء، معرض الوسائط |
| **GroupManagementScreen** | إعدادات (نوع المجموعة، الصلاحيات، المشرفين، Slow Mode)، روابط الدعوة، المستخدمين المحظورين، سجل النشاطات |
| **GroupMembersScreen** | قائمة الأعضاء مع أوسمة Owner/Admin وأزرار إدارة، FAB لإضافة أعضاء |
| **JoinRequestsScreen** | طلبات انضمام مع أزرار موافقة/رفض |
| **AddGroupMembersScreen** | بحث واختيار أعضاء جدد |

### شاشات الإعدادات
| الشاشة | الوصف |
|--------|-------|
| **SettingsScreen** | قائمة: الحساب، الإشعارات، المظهر، التخزين، المساعدة، تسجيل الخروج |
| **AccountSettings** | تعديل صورة الملف، صورة الغلاف، الاسم، اسم المستخدم (مع التحقق من التوفر)، البايو |
| **AppearanceSettings** | Dark Mode (حفظ تلقائي)، خلفية المحادثة (placeholder)، حجم الخط (placeholder) |
| **NotificationSettings** | أصوات الإشعارات، الاهتزاز، إشعارات المجموعات |

---

## 🎨 التصميم والثيم

### الألوان
```
Light Theme:
  Primary:    #007AFF (أزرق iOS)
  Secondary:  #5856D6
  Background: #FFFFFF
  Surface:    #F2F2F7

Dark Theme:
  Primary:    #0A84FF
  Secondary:  #5E5CE6
  Background: #000000 (OLED)
  Surface:    #1C1C1E
```

### الخطوط
- **Poppins**: العناوين (Headlines)
- **Inter**: النصوص الأساسية (Body)

### القطع المكررة (Widgets)
- **BottomNavBar**: شريط سفلي مخصص مع أيقونات وانتقال متحرك
- **ChatListItem**: عنصر محادثة مع صورة، اسم، آخر رسالة، وقت، عدد غير مقروء
- **MessageBubble**: فقاعة رسالة مع كل التفاصيل
- **MessageInput**: حقل إدخال متكامل مع أزرار الوسائط والتسجيل
- **VoiceMessagePlayer**: مشغل صوتي مع موجة صوتية وشريط تقدم

---

## 🗄 طبقة البيانات

### Cloud Firestore - المجموعات

#### `users/{uid}`
| الحقل | النوع | الوصف |
|-------|------|-------|
| uid | String | معرف المستخدم |
| email | String | البريد الإلكتروني |
| displayName | String | الاسم المعروض |
| username | String? | اسم المستخدم (فريد) |
| bio | String? | نبذة عن المستخدم |
| photoUrl | String? | رابط صورة الملف (Cloudinary) |
| coverUrl | String? | رابط صورة الغلاف (Cloudinary) |
| lastSeen | Timestamp? | آخر ظهور |
| isOnline | bool | هل هو متصل |
| role | String | user \| vip \| admin \| developer |

#### `chats/{chatId}`
| الحقل | النوع | الوصف |
|-------|------|-------|
| participants | List\<String> | معرفات المشاركين |
| lastMessage | String | آخر رسالة (معاينة) |
| lastMessageTime | Timestamp | وقت آخر رسالة |
| unreadCounts | Map\<String, int> | عدد غير مقروء لكل مستخدم |
| isGroup | bool | هل هي مجموعة |
| groupName | String? | اسم المجموعة |
| groupIcon | String? | أيقونة المجموعة |
| adminId | String? | المالك الأساسي |
| admins | List\<String> | معرفات المشرفين |
| adminTitles | Map\<String, String> | ألقاب المشرفين |
| slowModeSeconds | int | فترة التهدئة |
| bannedUsers | List\<String> | المستخدمون المحظورون |
| permissions | Map\<String, bool> | sendMessages, sendMedia, addUsers, pinMessages, changeInfo |
| isPrivate | bool | مجموعة خاصة |
| joinRequests | List\<String> | طلبات الانضمام المعلقة |
| pinnedMessageId | String? | معرف الرسالة المثبتة |
| pinnedMessageContent | String? | نص الرسالة المثبتة |

#### `chats/{chatId}/messages/{messageId}`
| الحقل | النوع | الوصف |
|-------|------|-------|
| senderId | String | معرف المرسل |
| senderName | String? | اسم المرسل (للمجموعات) |
| receiverId | String | معرف المستقبل أو 'group' |
| content | String | النص أو رابط الوسائط |
| type | String | text \| image \| video \| voice |
| timestamp | Timestamp | وقت الإرسال |
| isRead | bool | هل قُرئت |
| replyToMessageId | String? | مرجع للرسالة المردود عليها |
| replyToMessageContent | String? | معاينة الرد |
| reactions | Map\<String, String> | {userId: emoji} |

#### `chats/{chatId}/inviteLinks/{linkId}`
روابط دعوة مع label، عدد الانضمامات، الحالة

#### `chats/{chatId}/adminActions/{actionId}`
سجل إجراءات المشرفين (نوع الإجراء، الوصف، الوقت)

### Firebase Realtime Database
- `/status/{uid}`: حالة الاتصال (online/offline)
- `/typing/{chatId}/{userId}`: مؤشر الكتابة

### Cloudinary
- **Cloud name**: `dvdehwhwf`
- **Upload preset**: `flow-preset`
- **المجلدات**: `chats/{chatId}` (صور وفيديو)، `voice_messages` (صوتيات)، `profiles` (صور الملف)

---

## 📦 المكتبات المستخدمة

| المكتبة | الإصدار | الاستخدام |
|---------|---------|-----------|
| firebase_core | ^4.9.0 | تهيئة Firebase |
| firebase_auth | ^6.5.1 | المصادقة |
| cloud_firestore | ^6.4.1 | قاعدة البيانات الرئيسية |
| firebase_database | ^12.4.1 | Realtime Database (Presence + Typing) |
| firebase_messaging | ^16.2.2 | الإشعارات |
| cloudinary_public | ^0.23.1 | رفع الوسائط |
| provider | ^6.1.5+1 | إدارة حالة الثيم |
| image_picker | ^1.2.2 | اختيار الصور والفيديو |
| image_cropper | ^12.2.1 | قص الصور |
| cached_network_image | ^3.4.1 | تحميل وعرض الصور |
| record | ^6.2.0 | تسجيل الصوت |
| audioplayers | ^6.6.0 | تشغيل الصوت |
| google_fonts | ^8.1.0 | الخطوط |
| shared_preferences | ^2.5.5 | حفظ الإعدادات محلياً |
| intl | ^0.20.2 | تنسيق التواريخ |
| path_provider | ^2.1.5 | مسار الملفات المؤقتة |
| video_player | ^2.11.1 | تشغيل الفيديو |

---

## 🔀 التنقل بين الشاشات

```
SplashScreen
  └── AuthWrapper
        ├── [دخول] → HomeScreen
        │     ├── [التبويب 0: المحادثات]
        │     │     ├── FAB → NewChat / NewGroup / JoinGroup
        │     │     └── Chat → ChatScreen
        │     │           ├── Info → UserProfileScreen / GroupInfoScreen
        │     │           │     ├── GroupInfoScreen
        │     │           │     │     ├── GroupMembersScreen → AddGroupMembersScreen
        │     │           │     │     ├── GroupManagementScreen
        │     │           │     │     │     ├── JoinRequestsScreen
        │     │           │     │     │     ├── InviteLinks / Banned / Actions Log
        │     │           │     │     │     └── Permissions / Admins / Slow Mode
        │     │           │     │     └── روابط الدعوة
        │     │           │     └── UserProfileScreen
        │     │           ├── الصورة → FullScreenImageViewer
        │     │           └── خيارات → Reactions / Reply / Copy / Delete / Pin
        │     └── [التبويب 1: الإعدادات]
        │           ├── AccountSettings
        │           ├── NotificationSettings
        │           ├── AppearanceSettings
        │           └── Logout
        └── [خارج] → LoginScreen
              └── SignupScreen
```

---

## 🚀 كيفية التشغيل

### المتطلبات
- Flutter SDK (أحدث إصدار)
- Android Studio / VS Code
- جهاز Android أو iOS أو محاكي
- مشروع Firebase + حساب Cloudinary

### الخطوات

```bash
# 1. استنساخ المشروع
git clone <repository-url>
cd flow

# 2. تثبيت الاعتماديات
flutter pub get

# 3. إعداد Firebase
#    - أنشئ مشروع Firebase
#    - فعّل Authentication (Email/Password)
#    - فعّل Cloud Firestore + Realtime Database
#    - أضف تطبيق Android/iOS/Web
#    - حمل ملف google-services.json وضعه في android/app/
#    - سجل القيم من firebase_options.dart (أو استخدم flutterfire configure)
```

#### تشغيل محلي (بناءً على --dart-define)

جميع مفاتيح Firebase تُمرر عبر `--dart-define` أثناء البناء:

```bash
flutter run --dart-define=FIREBASE_PROJECT_ID=your_project \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456 \
  --dart-define=FIREBASE_DATABASE_URL=https://your_project.firebasedatabase.app \
  --dart-define=FIREBASE_STORAGE_BUCKET=your_project.firebasestorage.app \
  --dart-define=FIREBASE_WEB_API_KEY=... \
  --dart-define=FIREBASE_WEB_APP_ID=... \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID=... \
  --dart-define=FIREBASE_ANDROID_API_KEY=... \
  --dart-define=FIREBASE_ANDROID_APP_ID=... \
  --dart-define=FIREBASE_IOS_API_KEY=... \
  --dart-define=FIREBASE_IOS_APP_ID=... \
  --dart-define=FIREBASE_IOS_CLIENT_ID=... \
  --dart-define=FIREBASE_WINDOWS_API_KEY=... \
  --dart-define=FIREBASE_WINDOWS_APP_ID=... \
  --dart-define=FIREBASE_WINDOWS_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_WINDOWS_MEASUREMENT_ID=...
```

> 💡 **نصيحة:** أنشئ ملف `build.sh` يحتوي على الأمر كاملاً مع مفاتيحك عشان ما تعيد كتابتها كل مرة، وأضف الملف لـ `.gitignore`.

#### GitHub Actions + Secrets

عشان تبني APK تلقائياً من GitHub:

1. اذهب إلى `Settings → Secrets and variables → Actions` في الـ repo.
2. أضف كل مفتاح Firebase كـ **Repository secret** بنفس الاسم المذكور فوق.
3. أضف الـ secret `GOOGLE_SERVICES_JSON` — محتوى ملف `google-services.json` كاملاً.
4. ادفع التعديلات → GitHub Actions يبني APK تلقائياً.

### 4. إعداد Cloudinary
- أنشئ حساب Cloudinary
- أنشئ Upload Preset باسم "flow-preset" من نوع **Unsigned**
- حدث الرابط في `cloudinary_service.dart`

### ملاحظات مهمة
- المشروع لا يحتوي على مفاتيح Firebase حقيقية في الـ repository — كلها تمر عبر `--dart-define`
- `lib/firebase_options.dart` يقرأ من `--dart-define` ولا يحتوي أي قيم ثابتة
- ملف `android/app/google-services.json` مضاف لـ `.gitignore` — لازم توفره يدوياً أو عبر CI Secret

---

## 📄 الترخيص

هذا المشروع مفتوح المصدر ومتاح للاستخدام الشخصي والتعلم.

---

> تم تطويره بواسطة **Izutec** 🚀
