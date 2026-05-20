# خطة تطوير المجموعات المتقدمة — Advanced Group Features

> بناءً على هيكل Firebase الحالي (بدون سيرفر خاص).
> كل الميزات تستخدم Firestore كقاعدة بيانات وحيدة.

---

## 1. نظام الصلاحيات المتدرج (Permissions & Restrictions) 🛡️

### أ. الصلاحيات العامة (Global Permissions)

**الموجود حالياً:**
- `permissions` map في `ChatModel` — لكنه غير مستخدم في الواجهة.

**خطة التطبيق:**
```
مستند المجموعة في Firestore:
permissions: {
  sendMessages: true,
  sendMedia: true,
  addUsers: true,
  pinMessages: true,
  changeInfo: true,
}
```
- شاشة "إدارة المجموعة" ← قسم "الصلاحيات" ← قائمة مفاتيح تشغيل/إيقاف.
- في `chat_screen.dart` و `group_info_screen.dart`، قبل تفعيل زر الإرسال أو زر تغيير الصورة، نفحص `permissions`:
  ```dart
  if (!chat.permissions['sendMessages']) {
    ScaffoldMessenger.showSnackBar('إرسال الرسائل مقيد');
    return;
  }
  ```
- **التخزين:** `chat_service.updateGroupPermissions()` موجود مسبقاً.
- **عدد أيام العمل:** 1 يوم.

### ب. تقييد الأعضاء (User Restrictions)

**جديد — غير موجود.**

**التخزين في Firestore:**
```
مستند المجموعة:
restrictions: {
  userId1: {
    sendMedia: false,
    until: Timestamp(2026-06-01)  // null = دائم
  },
  userId2: {
    sendMessages: false,
    until: null  // دائم
  }
}
```

**الواجهة:**
- من `group_info_screen.dart` ← ضغط على عضو ← "تقييد" ← اختيار الصلاحيات الممنوعة + المدة (ساعة/يوم/أسبوع/دائم).
- عند إرسال رسالة، نفحص إذا كان `restrictions[currentUserId]` موجود ويمنع الإجراء.

**عدد أيام العمل:** 2 يوم.

### ج. الألقاب (Admin Titles)

**الموجود حالياً:**
- `adminTitles` map في `ChatModel` — و `setAdminTitle()` في `ChatService`.
- يظهر في `group_info_screen.dart` كـ subtitle تحت اسم المشرف.

**المطلوب:**
- شاشة تعديل اللقب: ضغط على مشرف في info ← "تعيين لقب" ← حقل نصي.
- عرض اللقب تحت اسم المشرف في كل مكان (chat bubble, group info, mentions).

**عدد أيام العمل:** 0.5 يوم.

---

## 2. إعدادات المجموعة المتقدمة ⚙️

### أ. نوع المجموعة (Public vs Private)

**الموجود حالياً:**
- `isPrivate` boolean في `ChatModel` + `toggleGroupPrivacy()` في `ChatService`.

**المطلوب:**
- إضافة تبديل Public/Private في شاشة "معلومات المجموعة" أو "إدارة المجموعة".
- عند Public: إظهار رابط دائم (مثل: `flow.me/group_username`).
- عند Private: إخفاء الرابط.

**التخزين:**
```
مستند المجموعة:
isPrivate: true/false
groupUsername: "my_group"  // public فقط
```

**ملاحظة:** الرابط الدائم راح يكون مجرد نص وراءه — ما في DNS أو server. الرابط يعمل فقط داخل التطبيق.

**عدد أيام العمل:** 1 يوم.

### ب. حماية المحتوى (Content Protection)

**جديد — غير موجود.**

**التخزين:**
```
مستند المجموعة:
restrictSaving: true/false
```

**الوظيفة:**
- إذا `restrictSaving == true`:
  - إخفاء زر Copy في `_showMessageOptions`.
  - إخفاء زر Forward (أو تعطيله).
  - في Android: لا يمكن منع Screenshot برمجياً بشكل موثوق، لكن نضيف تحذير Toast.
- يتم تفعيلها من شاشة "إدارة المجموعة".

**عدد أيام العمل:** 0.5 يوم.

---

## 3. وضع التهدئة (Slow Mode) ⏳

**الموجود حالياً:**
- `slowModeSeconds` int في `ChatModel`.
- `setSlowMode()` في `ChatService`.
- نص ثابت في `group_management_screen.dart`.

**المطلوب:**

### الواجهة:
- اختيار المدة: Off / 10s / 30s / 1m / 5m / 15m / 30m / 1h.
- حفظ `slowModeSeconds` في Firestore.

### التطبيق في `chat_screen.dart`:
1. كل عضو عنده `lastMessageTime` مخزن في `membersMetadata`:
```
مستند المجموعة:
membersMetadata: {
  userId1: {
    lastMessageTime: Timestamp,
    joinedAt: Timestamp
  }
}
```
2. قبل إرسال رسالة:
   ```dart
   if (slowModeSeconds > 0) {
     final elapsed = DateTime.now().difference(lastMessageTime);
     if (elapsed.inSeconds < slowModeSeconds) {
       final wait = slowModeSeconds - elapsed.inSeconds;
       showCountdown(wait);  // عداد تنازلي مكان زر الإرسال
       return;
     }
   }
   ```
3. بعد إرسال رسالة بنجاح → تحديث `membersMetadata.userId.lastMessageTime`.
4. العداد التنازلي: `Text('Wait ${wait}s')` يحل مكان icon الإرسال، مع Timer كل ثانية.

**عدد أيام العمل:** 2 يوم.

---

## 4. سجل النشاطات (Recent Actions) 📜

**الموجود حالياً:**
- `adminActions` subcollection في Firestore + `AdminAction` model + `logAdminAction()` + `getAdminActions()`.

**المطلوب:**
- شاشة "النشاطات الأخيرة" → قائمة زمنية (آخر 48 ساعة).
- كل action يكون عنصر قائمة مع أيقونة (➕ إضافة عضو، 🚫 حظر، 📌 تثبيت، ✏️ تعديل).
- زر تصفية حسب نوع النشاط (اختياري).
- زر مسح السجل (للمالك فقط).

**عدد أيام العمل:** 1 يوم.

---

## 5. الملف الشخصي والوسائط المشتركة (User Profile & Media) 👤

### أ. أزرار التحكم السريع:
- رسالة, كتم, اتصال (إذا public profile), المزيد (حظر, تقييد).

**الموجود حالياً:**
- `viewProfile` → شاشة بروفايل بسيطة (موجودة ضمن `profile_screen.dart`).

### ب. الوسائط المشتركة (Shared Media):
جديد كلياً. شاشة داخل المحادثة:
- تبويبات: Media | Files | Links
- Media: GridView يظهر كل `messages where type == 'image'`
- Files: ListView يظهر كل `messages where type == 'file'` (لما نضيف دعم الملفات)
- Links: ListView يستخرج الروابط من `messages where type == 'text'` ويحاول يعرض عنوان الصفحة

**التنفيذ:**
```dart
// Query messages subcollection
_firestore
  .collection('chats').doc(chatId)
  .collection('messages')
  .where('type', isEqualTo: 'image')
  .orderBy('timestamp', descending: true)
  .limit(50)
```

**عدد أيام العمل:** 2 يوم.

---

## 6. القائمة المنبثقة للمحادثات (Chat Context Menu) 🖱️

**الموجود حالياً:**
- long-press يعمل ← قائمة فيها: Mark Read/Unread, Mute/Unmute, Delete.
- جميع الخيارات متصلة بـ Firebase.

### المطلوب إضافته:

**Pin (تثبيت):**
- إضافة حقل `pinned: bool` إلى مستند المحادثة (أو `pinnedBy: { userId: timestamp }`).
- في `chat_list_item.dart`: المحادثات المثبتة تظهر أولاً (sort).
- أيقونة Pin صغيرة بجانب اسم المحادثة.

**Archive (أرشفة):**
- إضافة حقل `archivedBy: { userId: timestamp }`.
- المحادثات المؤرشفة: مخفية من القائمة الرئيسية، تظهر فقط عند التمرير لأسفل أو في قسم منفصل.

**Mute مع اختيار المدة:**
- بدلاً من كتم ليوم واحد افتراضي، نعرض bottomSheet باختيار: 1h / 8h / 1d / 7d / Forever.
- هذه الميزة موجودة مسبقاً في `chat_screen.dart` (دالة `_muteOption`) — نسوي ربط.

**عدد أيام العمل:** 2 يوم.

---

## ملخص الجدول الزمني

| الميزة | الأيام |
|--------|--------|
| الألقاب (Admin Titles) | 0.5 |
| حماية المحتوى | 0.5 |
| الصلاحيات العامة | 1 |
| سجل النشاطات | 1 |
| نوع المجموعة (Public/Private) | 1 |
| تقييد الأعضاء | 2 |
| وضع التهدئة (Slow Mode) | 2 |
| الوسائط المشتركة | 2 |
| القائمة المنبثقة كاملة | 2 |
| **المجموع** | **~12 يوم** |

---

## ملاحظات تقنية

1. **الروابط الدائمة:** ما عندنا server، لذلك `flow.me/my_group` راح يكون مجرد معرف داخل التطبيق. المستخدم ينسخ الرابط ويشاركه يدوياً.
2. **الأكواد:** `group_username` لازم يكون فريد — نستخدم `where` query للتأكد قبل الحفظ.
3. **الـ Screenshot:** لا يمكن منعه برمجياً في iOS/Android بدون مكتبات خارجية. الحل الواقعي: Toast تحذيري.
4. **الـ Files:** شاشة الوسائط المشتركة للملفات تحتاج أولاً تفعيل رفع الملفات (`file_picker` + Cloudinary).
5. **الترجمة:** كل النصوص الجديدة تضاف إلى `translations.dart` بمفتاح AR + EN.
6. **الأداء:** استعلامات `where('type', isEqualTo: ...)` تحتاج `composite index` على `chats/{chatId}/messages/`.
