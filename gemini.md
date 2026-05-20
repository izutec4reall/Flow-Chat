# مشروع تطبيق الدردشة المجاني (FlowChat) - مستند المواصفات الفنية

## 1. نظرة عامة على المشروع
الهدف هو بناء تطبيق دردشة (Chat App) بسيط ومجاني تماماً باستخدام Flutter، يستهدف مجموعة صغيرة من المستخدمين (أصدقاء). التطبيق يركز على الكفاءة في استهلاك الموارد لضمان البقاء ضمن الخطط المجانية للمزودين.

## 2. البنية التحتية التقنية (Tech Stack)
*   **الإطار البرمجي (Frontend):** Flutter (Dart).
*   **قاعدة البيانات والتحقق (Backend):** Firebase (Spark Plan - Free).
    *   **Firebase Auth:** لتسجيل دخول المستخدمين (إيميل وكلمة سر).
    *   **Cloud Firestore:** لتخزين الرسائل النصية، بيانات المستخدمين، وروابط الوسائط.
*   **تخزين الوسائط (Media Storage):** Cloudinary (Free Tier).
    *   يتم استخدامه بدلاً من Firebase Storage لتجنب طلبات الدفع والبطاقة البنكية.
    *   الوظيفة: رفع الصور والفيديوهات والحصول على روابط (URLs).

## 3. المميزات المطلوبة (Features)
*   نظام تسجيل دخول وإنشاء حساب (Email/Password).
*   محادثات فورية (Real-time Chat) باستخدام `StreamBuilder`.
*   إرسال رسائل نصية.
*   إرسال صور وفيديوهات (عن طريق الرفع لـ Cloudinary ثم حفظ الرابط في Firestore).
*   تنظيم الوسائط في Cloudinary داخل مجلدات (مثل: `chat_images/`, `chat_videos/`).
*   مؤشر لحالة المستخدم (متصل الآن / آخر ظهور) - اختياري.
*   إشعارات فورية (Push Notifications) عبر Firebase FCM.

## 4. هيكلية البيانات (Data Modeling)
### مجموعة الرسائل (Messages Collection):
- `senderId`: String
- `receiverId`: String
- `content`: String (نص الرسالة أو رابط الميديا)
- `type`: String (text, image, video)
- `timestamp`: FieldValue.serverTimestamp()
- `folder`: String (المجلد في كلاوديناري - اختيارياً)

## 5. المهارات التقنية المطلوبة للتنفيذ
1.  **أساسيات Dart & Flutter:** التعامل مع Widgets, UI, و State Management بسيط (مثل Provider أو Bloc).
2.  **Firebase Integration:** ربط التطبيق بـ Firebase، إعداد ملفات `google-services.json`.
3.  **التعامل مع APIs:** استخدام مكتبة `http` أو `cloudinary_public` للرفع إلى Cloudinary.
4.  **قواعد الأمان (Security Rules):** كتابة قواعد Firestore لضمان خصوصية الرسائل بين الطرفين.
5.  **التعامل مع الميديا:** استخدام `image_picker` لاختيار الصور و `video_player` لتشغيل الفيديوهات.

## 6. الخطة المطلوبة من الـ AI
يرجى تقديم خطة عمل مقسمة إلى "مراحل" (Sprints)، مع توفير الأكواد البرمجية لكل مرحلة، بدءاً من إعداد المشروع ووصولاً إلى تشغيل الشات المباشر وإرسال الصور.