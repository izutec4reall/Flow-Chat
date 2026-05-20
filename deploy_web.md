# نشر تطبيق Flow على الويب مجانًا

> **ملف Firebase موجود أصلاً**: `lib/firebase_options.dart` (مولّد من FlutterFire CLI)
> يحتوي على كل الإعدادات (apiKey, appId, projectId, ...)
> **ما يحتاج أي ملف إضافي** — FlutterFire يشغّل Firebase JS SDK أوتوماتيك على الويب

---

## الطريقة 1: Firebase Hosting (مدمج مع المشروع — الأسهل)

### 1. ثبت Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. سجل دخول بحساب Google
```bash
firebase login
```

### 3. جهز ملفات النشر
```bash
flutter build web --release
```
الملفات بتظهر في `build/web/`

### 4. أضف `firebase.json` في مجلد المشروع
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### 5. اربط المشروع بـ Firebase
```bash
firebase init hosting
```
- اختار "Use an existing project" ← اختار `flow-chat-5e38b` (مشروعك)
- لما يسألك عن "public directory" اكتب `build/web`
- لما يسألك "Configure as a single-page app" اختر Yes
- لما يسألك "Set up automatic builds" اختر No

ملاحظة: `firebase init` بيحط ملف `.firebaserc` و `firebase.json` في مجلد المشروع — لا تحذفهم.

### 6. انشر
```bash
firebase deploy --only hosting
```
راح يظهر رابط الموقع (مثلاً: `https://flow-chat-5e38b.web.app`)

### تجديد كل مرة تريد نشر تحديث
```bash
flutter build web --release && firebase deploy --only hosting
```

---

## الطريقة 2: Cloudflare Pages (أسرع + مجاني)

### 1. ارفع يدويًا
- اركب `flutter build web --release`
- ادخل على https://dash.cloudflare.com → Pages
- اضغط "Create a project" → "Direct Upload"
- اسحب مجلد `build/web` كاملًا

### 2. أو اربط GitHub
- ادفع الكود لـ GitHub
- في Cloudflare Pages اضغط "Create a project" → "Connect to Git"
- اختار الـ repo
- Build command: `flutter build web --release`
- Build output directory: `build/web`
- كل ما تدفع تغيير، يتنشر تلقائيًا

---

## الطريقة 3: Netlify

- اركب `flutter build web --release`
- ادخل على https://app.netlify.com → Sites → Drag & drop مجلد `build/web`
- أو اربط مع GitHub:
  - Build command: `flutter build web --release`
  - Publish directory: `build/web`
  - أضف ملف `public/_redirects` بمحتوى:
    ```
    /*    /index.html    200
    ```

---

## مهم لـ Firebase Authentication على الويب

في Firebase Console:
1. ادخل على **Authentication → Settings → Authorized domains**
2. أضف دومين الموقع (مثلاً `flow-chat-5e38b.web.app` أو أي custom domain)
3. لو تستخدم Localhost للتجربة، أضف `localhost`

---

## مهم: إشعارات Firebase (Push Notifications) للويب — اختياري

إذا تبغى push notifications تشتغل على الويب، أنشئ ملف `web/firebase-messaging-sw.js`:
```javascript
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCAazMj-_vstlN7iyltTKCA2v9MZsqWTSA",
  authDomain: "flow-chat-5e38b.firebaseapp.com",
  projectId: "flow-chat-5e38b",
  messagingSenderId: "156617951416",
  appId: "1:156617951416:web:5e8e6901299a7e19730c4d"
});

const messaging = firebase.messaging();
```

> هذا الملف **مو ضروري** للنشر الأساسي — فقط إذا كنت تبي الإشعارات تشتغل على الويب.

---

## نشر FCM Cloud Function (إشعارات تلقائية)

لما يرسل أحد رسالة، Cloud Function يشتغل ويرسل إشعار لبقية المشاركين بالمجموعة.

### 1. تأكد من وجود Node.js 18+
```bash
node --version
```

### 2. ثبت الاعتماديات
```bash
cd functions
npm install
cd ..
```

### 3. انشر الكلاود فنكشن
```bash
firebase deploy --only functions
```

### 4. اختبر الإشعارات
- افتح التطبيق على جهازين مختلفين
- أرسل رسالة من حساب لثاني
- رح يوصل إشعار تلقائيًا
  
> الميزة: كل الإشعارات ترسل من Cloud Function serverless بدون ما تحتاج سيرفر خاص
> خطة Spark المجانية: 2M استدعاء/شهر

---

## ملاحظات
- **النسخة المجانية من Firebase Hosting**: 10GB تخزين، 360MB/day bandwidth — كافي لتجربة شخصية
- **Cloudflare Pages**: غير محدود bandwidth (مجانًا)
- **SPA routing**: كل الطرق فوق تضم `rewrites` أو `_redirects` عشان الـ routing يشتغل (لازم تروح كل المسارات لـ `index.html`)
- **`firebase_options.dart`** في `lib/` هو كل ما تحتاجه — ما يحتاج تحط `<script>` tags في `index.html` ولا تنشئ ملف config ثاني للويب
