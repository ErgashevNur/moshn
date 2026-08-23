# Vaqtinchalik google-services.json (Pro)

Bu papkadagi `google-services.json` **customer** (`uz.pitgo.pitgo`) uchun
Firebase loyihasidan olingan, lekin `package_name` maydoni qo'lda
`uz.pitgo.pitgo.pro` ga o'zgartirilgan — faqat build xatosini
(`processProReleaseGoogleServices: No matching client found`) oldini olish
uchun. `mobilesdk_app_id`/`api_key` haqiqatda `uz.pitgo.pitgo.pro` uchun
Firebase'da ro'yxatdan o'tmagan.

**Natija:** PitGo Pro APK to'liq build bo'ladi va ishlaydi, lekin push
bildirishnomalar (FCM) ishlamaydi.

**Qachon almashtirish kerak:** Firebase Console'da mavjud loyihaga yangi
Android ilova (`uz.pitgo.pitgo.pro`) qo'shilgach, o'sha yerdan yuklab
olingan haqiqiy `google-services.json` shu faylni almashtirishi kerak.
Shundan keyin bu fayl (`FIREBASE_TODO.md`) o'chirilsin.
