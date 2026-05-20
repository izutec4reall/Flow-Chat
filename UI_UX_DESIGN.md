# 🎨 دليل تصميم واجهة وتجربة المستخدم (UI/UX) - Flow

---

## 📑 المحتويات

- [فلسفة التصميم](#-فلسفة-التصميم)
- [نظام الألوان](#-نظام-الألوان)
- [الطباعة والخطوط](#-الطباعة-والخطوط)
- [المسافات والهيكل](#-المسافات-والهيكل)
- [المكونات المرئية (Widgets)](#-المكونات-المرئية-widgets)
- [الأيقونات والرسومات](#-الأيقونات-والرسومات)
- [الأنيميشن والحركة](#-الأنيميشن-والحركة)
- [شاشات التطبيق بالتفصيل](#-شاشات-التطبيق-بالتفصيل)
- [حالات الشاشات (States)](#-حالات-الشاشات-states)
- [التجاوب مع المستخدم](#-التجاوب-مع-المستخدم)
- [تجربة المستخدم (UX)](#-تجربة-المستخدم-ux)
- [إرشادات الأكسسيبليتي](#-إرشادات-الأكسسيبليتي)

---

## 🧠 فلسفة التصميم

### المبادئ الأساسية:
1. **البساطة والوضوح** — واجهة نظيفة خالية من التعقيد، تركيز على المحتوى
2. **الألفة (Familiarity)** — اتباع معايير Material 3 لتكون التجربة مألوفة للمستخدم
3. **السرعة والاستجابة** — تصميم Optimistic UI مع حالات Pending واضحة
4. **التخصيص** — دعم الثيما الفاتح والداكن مع ألوان مريحة للعين
5. **التسلسل الهرمي البصري** — عناوين واضحة، أزرار بارزة، تدرج في الأحجام

### الهوية البصرية:
- تصميم عصري ناعم يستلهم من iOS في الألوان (الأزرق #007AFF)
- حواف مدورة (Border Radius 12-24px) في كل العناصر
- استخدام الظل الخفيف (Shadow) لإضفاء العمق
- تدرجات لونية (Gradients) كلوحة احتياطية للصور
- Material 3 مع `useMaterial3: true`

---

## 🎨 نظام الألوان

### Light Mode

```
🌐 Basic Colors:
  Primary:        #007AFF (أزرق iOS)      — الأزرار، الروابط، العناصر النشطة
  Secondary:      #34C759 (أخضر)           — حالة Online, نجاح
  Tertiary:       #5856D6 (بنفسجي)         — أوسمة، أكسنت ثانوي
  
📦 Surface Colors:
  Surface:        #FFFFFF (أبيض)            — خلفية البطاقات والورق
  Background:     #FFFFFF (أبيض)            — خلفية الشاشة
  SurfaceVariant: #F3F4F6 (رمادي فاتح)     — حقول الإدخال، مناطق ثانوية
  SurfaceContainerLow: #F9FAFB             — مناطق سطحية منخفضة
  
📝 Text Colors:
  OnSurface:      #111827 (رمادي غامق)      — النصوص الأساسية
  OnSurfaceVariant: #4B5563 (رمادي وسط)     — النصوص الثانوية
  
🔲 Borders:
  Outline:        #9CA3AF (رمادي)           — الحدود الأساسية
  OutlineVariant: #E5E7EB (رمادي فاتح جداً)  — حدود ثانوية
  
⛔ Error:
  Error:          #FF3B30 (أحمر)            — أخطاء، حظر، حذف
  ErrorContainer: #FFDAD6                   — خلفية الأخطاء
```

### Dark Mode (OLED)

```
🌐 Basic Colors:
  Primary:        #0A84FF (أزرق ساطع)      — عناصر تفاعلية في الوضع الداكن
  Secondary:      #32D74B (أخضر ساطع)       — Online status
  Tertiary:       #5E5CE6                   — أكسنت بنفسجي
  
📦 Surface Colors:
  Surface:        #000000 (أسود OLED)        — خلفيات أساسية (توفير البطارية)
  Background:     #000000 (أسود خالص)
  SurfaceVariant: #1F2937 (رمادي غامق)      — Gray 800
  SurfaceContainerLow: #111827 (Gray 900)   — أقل سطح ارتفاعاً

📝 Text Colors:
  OnSurface:      #F9FAFB (أبيض مائل للرمادي)
  OnSurfaceVariant: #D1D5DB (رمادي فاتح)

🔲 Borders:
  Outline:        #4B5563
  OutlineVariant: #374151
```

### ألوان الأوسمة (Role Badges):
```
  developer:  #7C3AED (Deep Purple)
  admin:      #FF3B30 (Red Accent)
  vip:        #FF9500 (Orange)
  user:       لا يظهر وسام
```

### ألوان المرسلين في المجموعات:
```
  #007AFF (أزرق)    — المستخدم الأول
  #34C759 (أخضر)    — الثاني
  #FF9500 (برتقالي)  — الثالث
  #FF2D55 (وردي)     — الرابع
  #5856D6 (بنفسجي)   — الخامس
  #AF52DE (موف)      — السادس
  #00C7BE (تركواز)   — السابع
  #FF6482 (سلموني)   — الثامن
```
> يتم اختيار اللون بناءً على `senderId.hashCode` لضمان ثبات اللون لكل مستخدم.

---

## 🔤 الطباعة والخطوط

### نظام الخطوط:
```
العناوين (Headings):  Poppins (Google Fonts)
النصوص (Body):        Inter (Google Fonts)
```

### جدول الأنماط:

| النمط | الخط | الحجم | الوزن | ارتفاع السطر | تباعد الحروف |
|-------|------|-------|-------|--------------|--------------|
| `displayLarge` | Poppins | 32 | Bold (700) | 1.25 | -0.64 |
| `headlineLarge` | Poppins | 28 | Bold (700) | 1.28 | — |
| `headlineMedium` | Poppins | 24 | Semi-Bold (600) | 1.33 | — |
| `headlineSmall` | Poppins | 20 | Semi-Bold (600) | 1.4 | — |
| `bodyLarge` | Inter | 16 | Regular (400) | 1.5 | — |
| `bodyMedium` | Inter | 14 | Regular (400) | 1.43 | — |
| `bodySmall` | Inter | 12 | Regular (400) | 1.33 | — |
| `labelLarge` | Inter | 14 | Semi-Bold (600) | 1.43 | 0.14 |
| `labelSmall` | Inter | 11 | Medium (500) | 1.45 | 0.55 |

### استخدامات الخطوط:
```
displayLarge → عنوان شاشة الترحيب "Flow"
headlineMedium → عنوان الصفحة الرئيسية
headlineSmall → اسم المستخدم في AppBar
bodyLarge → نص البايو، أوصاف
bodyMedium → الرسائل النصية
bodySmall → التوقيت، النصوص المساعدة
labelLarge → أسماء الحقول، أسماء المحادثات
labelSmall → عدّاد غير مقروء، نصوص تسميات
```

---

## 📐 المسافات والهيكل

### نظام المسافات (Constants):
```
AppConstants.xs  = 4px   — مسافات صغيرة جداً
AppConstants.sm  = 8px   — مسافات صغيرة
AppConstants.md  = 16px  — مسافة افتراضية
AppConstants.lg  = 24px  — مسافة كبيرة
AppConstants.xl  = 32px  — مسافة كبيرة جداً
```

### Border Radius:
```
حقول الإدخال:         20px (دائري ناعم)
الأزرار الرئيسية:      20px
الأزرار الثانوية:      12px
البطاقات:             12px, 16px
فقاعات الرسائل:       20px (مع تخصيص لكل زاوية)
صور الملف الشخصي:      دائري (50% / radius 24-60)
Bottom Sheet:          24px (زوايا علوية فقط)
```

### الظلال (Elevation/Shadows):
```
FAB:                  elevation 2
البطاقات:            elevation 0 (تعتمد على اللون فقط)
الـ Bottom Nav Bar:   ظل خفيف (blur 10, offset 0,-4)
صور البروفايل:       ظل (blur 10, spread 2)
شعار Splash:         ظل (blur 30, offset 0,10)
```

---

## 🧩 المكونات المرئية (Widgets)

### 1. BottomNavBar
```
شريط سفلي بحافتين علويتين مدورتين (20px)
خلفية: surface (أبيض/أسود)
عنصران: Chats (chat_bubble), Settings (settings)
التنشيط: خلفية primaryContainer + زوايا مدورة 16px
أنيميشن: AnimatedContainer (200ms)
```

### 2. ChatListItem
```
ارتفاع 72px + padding (16 أفقي، 8 عمودي)
Avatar دائري (radius 24) مع Hero animation
دائرة Online (12px, tertiary, حد surface 2px)
اسم المحادثة: labelLarge 
آخر رسالة: bodySmall
الوقت: labelSmall
عدّاد غير مقروء: container primary + زوايا 12px
Swipe-to-Delete: خلفية حمراء مع أيقونة delete
```

### 3. MessageBubble
```
أقصى عرض: 75% من عرض الشاشة
فقاعة المرسل (isMe):
  - تدرج لوني (primary → primary.alpha(200))
  - محاذاة لليمين
  - زوايا: علوية يمنى 4 إذا كان في مجموعة والبقية 20
فقاعة المستقبل:
  - خلفية surfaceContainerHighest
  - محاذاة لليسار
  - زوايا: علوية يسرى 4 إذا كان في مجموعة والبقية 20
  
محتوى الرسالة:
  - نص: RichText مع دعم @Mentions (أزرق عريض، قابل للنقر)
  - صورة: CachedNetworkImage مع ClipRRect (12px) + Hero
  - فيديو: Container خلفية سوداء + play icon
  - صوت: VoiceMessagePlayer بعرض 250px

ردود (Reactions Badge):
  - container أبيض مع ظل + حد خفيف
  - position: absolute (bottom: -12)
  - عرض حتى 3 إيموجي + العدد

وقت الرسالة: bodySmall (10px) + أيقونة done_all (قراءة/غير مقروءة)
Swipe-to-Reply: Dismissible مع أيقونة reply
```

### 4. MessageInput
```
Container مع حد علوي (outlineVariant, alpha 50)
حقل إدخال: surfaceContainerHighest + 24px borderRadius
زر الإرسال: AnimatedContainer دائري (200ms)
  - عند الكتابة: primary مع أيقونة arrow_upward
  - عند التسجيل: أحمر مع أيقونة mic
  - عند Slow Mode: رمادي مع عرض الثواني
  
زر الوسائط: add_circle_outline, لون outline
زر الإيموجي: sentiment_satisfied_alt, لون outline
@Mentions: قائمة منبثقة (surfaceContainer + borderRadius 16)
التسجيل الصوتي: LongPress لبدء، Release للإرسال
```

### 5. VoiceMessagePlayer
```
عرض 250px، container مع alpha 20 من لون النص
borderRadius 16px
أيقونة Play/Pause (32px)
25 شريط موجة صوتية (waveform bars)
  - ارتفاع كل شريط: 5 + (index % 7) * 3
  - لون مشغّل: لون النص، غير مشغّل: alpha 60
شريط قابل للسحب (Seek)
عرض الوقت: دقيقة:ثانية (9px)
```

### 6. الأزرار الرئيسية (ElevatedButton)
```
عرض كامل (double.infinity)
ارتفاع 48px
borderRadius 20px
خلفية primary، نص onPrimary
elevation 2
```

---

## 🖼 الأيقونات والرسومات

### أيقونات التطبيق (من Material Icons):

```
الشعار:           forum_rounded
رسالة:            chat_bubble_rounded
مجموعة:           group_rounded
بحث:              search_rounded
إرسال:            arrow_upward_rounded
مايك:             mic_rounded, mic_none_rounded
صورة:             image_rounded, camera_alt
فيديو:            videocam_rounded
رد:               reply_rounded
حذف:              delete_outline
تثبيت:            push_pin_rounded
إعدادات:          settings_rounded
ال logout:        exit_to_app / logout
link:             link_rounded
```

### الصور:
- **صور الملف الشخصي**: دائرة (CircleAvatar) مع Hero animation
- **صور الغلاف**: ملء الشاشة مع تدرج شفاف去اق(Overlay Gradient للحماية)
- **معاينة الوسائط**: CachedNetworkImage مع placeholder (CircularProgressIndicator) و error (Icon error)
- **خلفية الـ Splash**: تدرج لوني (LinearGradient) يختلف بين الثيم الفاتح والداكن

### الشعار (Logo):
```
SplashScreen:
  Container 100x100
  تدرج: primary → primary.alpha(200) → tertiary
  borderRadius 28px
  ظل: primary.alpha(60), blur 30, offset 0,10
  أيقونة forum_rounded بيضاء 48px
  
شاشات Auth:
  Container 64x64
  خلفية: primaryContainer
  borderRadius 20px
  أيقونة forum, لون onPrimaryContainer
```

---

## 🎬 الأنيميشن والحركة

### الشاشات والانتقالات:

| العنصر | النوع | المدة | المنحنى (Curve) |
|--------|------|-------|-----------------|
| شعار Splash | ScaleTransition | 800ms | elasticOut |
| نص Splash | FadeTransition | 600ms | easeIn |
| انتقال Splash → Auth | FadeTransition | 500ms | — |
| Bottom Nav | AnimatedContainer | 200ms | — |
| زر الإرسال | AnimatedContainer | 200ms | — |
| Hero Avatar | Hero animation | — | — |
| صورة كاملة | Hero + InteractiveViewer | — | — |
| مؤشر التحميل (AppBar) | LinearProgressIndicator | — | — |

### مبدأ Optimistic UI:
```
1. المستخدم يختار صورة → تظهر فوراً في القائمة بحالة "Pending"
2. يتم رفع الصورة إلى Cloudinary في الخلفية
3. عند نجاح الرفع → تستبدل بالصورة النهائية
4. عند الفشل → إزالة وإظهار SnackBar خطأ
```

---

## 📱 شاشات التطبيق بالتفصيل

### 1. SplashScreen (شاشة البداية)
```
خلفية: LinearGradient (Light: F8FAFF → E8F0FE → F0F4FF, Dark: 0A0A0A → 001D36 → 0A0A0A)
الشعار: Container بتدرج + ظل + ScaleTransition (elasticOut) + FadeTransition
النص: "Flow" بـ displayLarge → يتلاشى بعد الشعار
      "Stay Connected" بـ bodyLarge (letterSpacing 2, weight 300)
مؤشر تحميل: CircularProgressIndicator (strokeWidth 2, primary.alpha(120))
المدة الإجمالية: 2.2 ثانية ← انتقال Fade إلى AuthWrapper
```

### 2. LoginScreen (تسجيل الدخول)
```
SafeArea + SingleChildScrollView + padding (32px)
الشعار: Container 64px, primaryContainer, borderRadius 20, أيقونة forum
العنوان: "Flow" displayLarge
الوصف: "Welcome back..." bodyLarge, onSurfaceVariant
حقل Email:
  - label "Email" بـ labelLarge
  - TextField مع hint "alex.rivers@example.com"
  - prefixIcon: mail_outline
حقل Password:
  - label "Password" + رابط "Forgot Password?" (TextButton)
  - TextField مع hint "••••••••"
  - prefixIcon: lock_outline
  - obscureText: true
زر Login: ElevatedButton (عرض كامل, 48px, borderRadius 20)
فاصل: "OR CONTINUE WITH" (labelSmall, letterSpacing 1.5)
زر Google: OutlinedButton (عرض كامل, borderRadius 20)
تذييل: "Don't have an account?" + "Sign up" (TextButton)
```

### 3. SignupScreen (إنشاء حساب)
```
AppBar: سهم رجوع
الشعار + "Join Flow" + وصف
حقل Full Name: hint "Alex Rivers", prefixIcon person_outline
حقل Email: hint "alex.rivers@example.com"
حقل Password: hint "••••••••"
زر Sign Up
تذييل: "Already have an account?" + "Login"
```

### 4. HomeScreen (الشاشة الرئيسية)
```
AppBar:
  - title: "Flow" أو "Settings" (headlineMedium, primary, bold)
  - centerTitle: true
Drawer (التبويب 0 فقط):
  - UserAccountsDrawerHeader (خلفية primary)
  - اسم المستخدم + وسام الدور (badge ملون)
  - صورة الملف الشخصي (CircleAvatar)
  - Items: Settings, Help & Feedback, Logout (أحمر)

شريط البحث:
  - TextField مع hint "Search chats..."
  - prefixIcon: search
  - fillColor: surfaceContainerLow
  - borderRadius: 12

قائمة المحادثات (StreamBuilder):
  - حالة تحميل: CircularProgressIndicator
  - حالة فارغة: أيقونة chat_bubble_outline + "No conversations yet"
  - حالة بحث بدون نتائج: search_off + "No matches found"
  - قائمة: ListView.builder مع ChatListItem

FAB: أيقونة add, primary
BottomSheet (FAB عند الضغط):
  - مقبض سفلي (40x4, surfaceContainerHighest, borderRadius 2)
  - "New Chat" (primaryContainer أيقونة person)
  - "New Group" (secondaryContainer أيقونة group)
  - "Join Group by Link" (tertiaryContainer أيقونة link)

BottomNavBar:
  - 2 tabs: Chats (chat_bubble), Settings (settings)
  - نشط: خلفية primaryContainer + أيقونة ممتلئة
  - IndexedStack للتبديل
```

### 5. ChatScreen (شاشة المحادثة)
```
AppBar:
  - leading: سهم رجوع
  - title: صورة المستخدم + الاسم (Hero animation)
    - في المجموعات: اسم المجموعة + عدد الأعضاء / "يكتب..."
    - محادثة خاصة: الاسم + Online / آخر ظهور / "Typing..."
  - actions: بحث (toggle) + PopupMenu (View Profile / Group Info / Group Management)

شريط البحث (عند التفعيل):
  - TextField مع hint "Search messages..."
  - autofocus, border none
  - على الخروج: مسح النص + إغلاق

Pinned Message Banner (إذا موجود):
  - خلفية primaryContainer.alpha(100)
  - أيقونة push_pin + "Pinned Message" + نص الرسالة
  - زر X للأدمن (إلغاء التثبيت)

قائمة الرسائل (ListView.builder, reversed):
  - Pagination: تحميل 20 رسالة + load more عند 90% من الأعلى
  - Date Headers: container مع surfaceContainerHighest + borderRadius 12
  - مجموعة الرسائل: تجميع رسائل نفس المرسل في 5 دقائق
  - علامات القراءة (isRead): أيقونة done_all (زرقاء / رمادية)
  - حالة الخطأ: أيقونة error + نص الخطأ
  - حالة فارغة: "No messages yet"

Loading More: CircularProgressIndicator (أسفل القائمة)

شريط الرد (Reply Preview):
  - خلفية surfaceContainer + حد علوي
  - أيقونة reply + "Replying to [name]" + نص الرسالة
  - زر X للإلغاء

MessageInput (أسفل الشاشة):
  - حقل كتابة مع زر إيموجي + زر وسائط
  - زر إرسال/تسجيل متغير
  - @Mentions في المجموعات

Bottom Sheet خيارات الرسالة:
  - شريط تفاعلات: 6 إيموجي (❤️ 😂 😮 😢 🔥 👍) حجم 30
  - Reply (أيقونة reply)
  - Copy Text (أيقونة copy) 
  - Delete Message (أيقونة delete, أحمر) — لرسائله فقط
  - Pin Message (أيقونة push_pin) — للمشرفين فقط
```

### 6. FullScreenImageViewer
```
خلفية: سوداء (#000000)
صورة: InteractiveViewer (تكبير/تصغير بالضغط والسحب)
Hero animation عند الانتقال من ChatScreen
يُغلق بالضغط على السهم الرجوع أو السحب لأسفل
```

### 7. GroupInfoScreen (معلومات المجموعة)
```
SliverAppBar:
  - expandedHeight 250px, pinned
  - FlexibleSpaceBar: عنوان المجموعة
  - background: صورة المجموعة أو أيقونة group (primaryContainer)

Pending Requests Banner (للأدمن فقط):
  - خلفية orange.alpha(50) + حد برتقالي
  - أيقونة person_add + عدد الطلبات + زر "Review"

About section: "About" (أزرق, عريض) + نص وصفي

Quick Actions row:
  - Search (search أيقونة, primary)
  - Link (add_link أيقونة)
  - Leave (logout أيقونة, أحمر)

Options:
  - Members (people_outline, عدد الأعضاء)
  - Group Settings (settings_outlined, للأدمن)
  - Notifications (notifications_none)

Shared Media: SliverGrid (3 أعمدة, 6 صور placeholder)
```

### 8. GroupManagementScreen (إدارة المجموعة)
```
AppBar: "Group Management" (centerTitle)

Settings Section:
  - Group Type (lock/public) → Switch
  - Permissions → Bottom Sheet مع 5 مفاتيح
  - Administrators → Sheet مع قائمة + أوسمة (Owner/Admin)
  - Slow Mode → Dialog مع Slider (0-3600 ثانية)

Invitations Section:
  - Invite Links → Sheet مع قائمة روابط + زر إضافة
  - Removed Users (Banned) → Sheet مع زر Unban

Activity Section:
  - Recent Actions → Stream قائمة النشاطات

Card design: elevation 0, surfaceContainerHighest, borderRadius 16
Section Header: labelSmall, uppercase, primary, letterSpacing 1.2
```

### 9. UserProfileScreen (الملف الشخصي)
```
SliverAppBar:
  - expandedHeight 350px, pinned
  - coverPhoto: صورة الغلاف أو تدرج (primary → secondary)
  - dark overlay (gradient black54 → transparent) لقراءة النص
  - صورة الملف الشخصي: Container مع padding 4 + border surface + ظل
    → Hero animation, CircleAvatar (radius 50)
  - أزرار تعديل: camera_alt لصورة الغلاف, edit لصورة الملف (للمستخدم نفسه)

المعلومات:
  - Row: الاسم (headlineMedium, bold) + وسام الدور (badge ملون)
  - @username (titleMedium, primary)
  - Online/Offline badge (Container مع دائرة ملونة)

Bio Section:
  - أيقونة info_outline + "About" (primary, عريض, 12px)
  - نص البايو (bodyLarge)

Media Section:
  - "Media, Links and Docs" (titleMedium, bold)
  - ListView أفقي مع 5 صور placeholder

Actions Row:
  - Send Message (ElevatedButton.icon, عرض كامل)
  - Call, Video, Share, Block (CircleAvatar 25px + اسم)

Admin Controls (للمشرفين فقط):
  - "Admin Controls" (titleMedium, redAccent, bold)
  - Change User Role (ListTile مع خلفية حمراء شفافة)
  - AlertDialog مع RadioListTile (user/vip/admin/developer)
```

### 10. SettingsScreen (الإعدادات)
```
ListView:
  - Account tile: صورة + اسم + "Account, Profile, Privacy" → AccountSettings
  - Notifications: أيقونة notifications_none
  - Appearance: أيقونة palette_outlined
  - Storage and Data: أيقونة data_usage
  - Help: أيقونة help_outline
  - Logout: ListTile أحمر (خلفية حمراء شفافة, borderRadius 12)
```

### 11. AccountSettings (إعدادات الحساب)
```
AppBar: "Account"
Cover Photo: Container 150px, borderRadius 12 + زر camera_alt
Profile Photo: CircleAvatar (radius 60) + FAB.small camera_alt
Editable fields:
  - Name (person_outline) → حفظ بـ check
  - Username (alternate_email, @ prefix) → حفظ بـ check
  - Bio (info_outline, maxLines 3) → حفظ بـ check
  - Email: للعرض فقط (read-only)
```

---

## 🔄 حالات الشاشات (States)

### لكل شاشة تستخدم StreamBuilder:

| الحالة | العرض |
|--------|-------|
| `ConnectionState.waiting` | CircularProgressIndicator |
| `hasError` | أيقونة error + رسالة الخطأ |
| `!hasData || data.isEmpty` | أيقونة فارغة + نص توضيحي |
| `hasData` | المحتوى الفعلي |

### حالات خاصة:

```
تحميل صور (CachedNetworkImage):
  - placeholder: CircularProgressIndicator
  - error: أيقونة error

Pending Upload:
  - شفافية سوداء 45% فوق الصورة
  - CircularProgressIndicator أبيض

Slow Mode:
  - زر الإرسال يعرض الثواني المتبقية
  - تعطيل الإرسال أثناء العد

Banned/Restricted:
  - حقل الإدخال معطل + نص "Messaging is restricted"
```

---

## 👆 التفاعل مع المستخدم

### اللمسات والإيماءات:

| الإيماءة | المكان | النتيجة |
|----------|--------|---------|
| Tap | ChatListItem | فتح المحادثة |
| Tap | اسم المستخدم في AppBar | فتح الملف الشخصي |
| Swipe Right | MessageBubble | تفعيل الرد (Reply) |
| Swipe Left | ChatListItem | حذف المحادثة (مع تأكيد) |
| Long Press | MessageBubble | فتح قائمة الخيارات |
| Long Press | Mic Button | بدء التسجيل الصوتي |
| Release | Mic Button | إرسال التسجيل |
| Tap | صورة في الرسالة | فتح FullScreenImageViewer |
| Pinch/Zoom | FullScreenImageViewer | تكبير/تصغير |
| Drag | VoiceMessagePlayer | التقديم/الإرجاع |

### التغذية الراجعة (Feedback):

```
SnackBar:
  - behavior: floating
  - borderRadius: 12
  - types: نجاح (أخضر), خطأ (أحمر), معلومات (أزرق)

Loading Indicators:
  - CircularProgressIndicator (عام)
  - LinearProgressIndicator (في AppBar أثناء رفع الوسائط)
  - Shimmer/Skeleton loading (في ChatListItem أثناء تحميل المستخدم)

Haptic/Vibration:
  - غير مطبق حالياً (قابل للإضافة مستقبلاً)

Dialogs للتأكيد:
  - حذف محادثة: AlertDialog مع زر أحمر "Delete"
  - مغادرة مجموعة: AlertDialog مع "Leave" أحمر
```

---

## 💡 تجربة المستخدم (UX)

### المبادئ المطبقة:

### 1. Optimistic UI
- عند إرسال صورة/فيديو → تظهر فوراً في القائمة بحالة Pending
- لا انتظار على رفع الملفات → المستخدم يرى النتيجة فوراً

### 2. الـ Real-time
- Firestore streams → تحديث فوري للرسائل
- Realtime Database → حضور فوري + مؤشر الكتابة
- بدون الحاجة لإعادة تحميل الصفحة

### 3. الـ Offline First
- Firestore persistence مفعل (كاش غير محدود)
- المستخدم يستطيع قراءة الرسائل السابقة بدون إنترنت
- الرسائل الجديدة تُرسل تلقائياً عند عودة الاتصال

### 4. إدارة التركيز
- فتح لوحة المفاتيح تلقائياً عند دخول الشاشات
- Auto-scroll لآخر رسالة
- Search field autofocus في البحث

### 5. الـ Navigation
- IndexedStack لحفظ حالة التبويبات (Chats/Settings)
- Standard Navigator.push للشاشات الفرعية
- Hero animations للانتقالات السلسة

### 6. Error Boundaries
- ErrorWidget مخصص: أيقونة error + "Oops! Something went wrong"
- عرض Stack Trace في وضع Debug فقط

### 7. Keyboard Handling
- SafeArea في كل الشاشات
- SingleChildScrollView في شاشات Auth (لمنع overlap)
- حقل الإدخال مرتبط بـ Keyboard (يظهر مع لوحة المفاتيح)

### 8. الـ Lifecycle
- WidgetsBindingObserver لكشف خلفية/أمامية التطبيق
- تعيين Offline تلقائي عند الخروج
- Presence Service مع onDisconnect()

---

## ♿ إرشادات الأكسسيبليتي

### التباين (Contrast):
- ألوان النصوص الأساسية: onSurface (#111827) على Surface (#FFFFFF) → نسبة تباين عالية
- Dark Mode: onSurface (#F9FAFB) على Background (#000000) → تباين ممتاز
- أزرار: onPrimary (أبيض) على Primary (#007AFF) → مقروء

### أحجام:
- الحد الأدنى لحجم النقر: 48px للأزرار الرئيسية
- أيقونات: 24px كحد أدنى
- الحقول: 48px ارتفاع

### القراءة:
- استخدام خطوط Google Fonts واضحة (Inter + Poppins)
- تباعد أسطر كافٍ (1.25 - 1.5)
- ألوان مختلفة للروابط والأزرار (Primary)

### التحسينات المستقبلية:
- [ ] دعم أحجام الخطوط القابلة للتغيير (موجود UI لكن غير مفعل)
- [ ] دعم الإتجاه RTL (العربية)
- [ ] إضافة TalkBack/Label للأيقونات
- [ ] تحسين التباين لبعض العناصر الثانوية

---

## 📐 ملخص تصميم الشاشة الواحدة

```
┌─────────────────────────────────┐
│       Status Bar                │
├─────────────────────────────────┤
│  AppBar (سهم + title + actions) │
├─────────────────────────────────┤
│                                 │
│   (Pinned Message Banner)       │
│                                 │
│  ┌───────────────────────────┐  │
│  │     StreamBuilder Content │  │
│  │  (قائمة / نموذج / خ)     │  │
│  │                           │  │
│  │  حالة فارغة / خطأ / تحميل │  │
│  └───────────────────────────┘  │
│                                 │
│  (Reply Preview Bar)            │
│  (MessageInput / حقل الإدخال)   │
├─────────────────────────────────┤
│       BottomNavBar              │
└─────────────────────────────────┘
```

---

> وثيقة التصميم - Flow Chat App v1.0.0  
> Built with Flutter + Material 3 ❤️
