# 🔍 Loyiha tahlili va Muammolar hisoboti (Analysis Report)

Ushbu hujjat `future_issue.md` faylidagi va qo'shimcha ko'tarilgan muammolarni texnik tahlil qilish uchun tayyorlandi.

---

## 1. 🔄 Update mexanizmi muammosi (Bugs)

**Muammo:** Ilova yangilanganda eski versiya ustiga emas, balki yangi ilova sifatida o'rnatilmoqda.

### 💡 Texnik tahlil va sabablar:
- **Application ID:** Android tizimi ilovalarni `applicationId` (masalan: `com.example.time_manager`) orqali taniydi. Agar bu ID o'zgargan bo'lsa, tizim uni yangi ilova deb hisoblaydi.
- **Signing Key (Imzo kaliti):** Agar avvalgi versiya *Debug Key* bilan, yangisi esa *Release Key* bilan imzolangan bo'lsa, Android xavfsizlik nuqtai nazaridan yangilashga ruxsat bermaydi va yangi o'rnatishni talab qiladi.
- **VersionCode:** `pubspec.yaml` dagi versiya qatorida `1.0.0+1` dagi `+1` (versionCode) har safar oshirilishi shart. Agar u o'zgarmasa yoki kamaysa, tizim "Update" deb qabul qilmaydi.

## Bu muommo dasturchi tomonidan qo'lda tuzatilinadi!

---

## 2. ⏳ Fon rejimida Timer to'xtashi (Background Issue)

**Muammo:** Ilova fonga o'tganda yoki qurilma ekrani o'chirilganda timer hisoblashdan to'xtab qolyapti.

### 💡 Texnik tahlil:
- **Operatsion tizim cheklovlari:** Android batareya quvvatini tejash maqsadida fon dagi ilovalarning `Timer.periodic` (Dart thread) ishini to'xtatib qo'yadi.
- **Hozirgi holat:** Biz qo'shgan `DateTime` anchor logic-i faqat ilovaga **qaytganda (resume)** vaqtni to'g'ri ko'rsatishga yordam beradi, lekin ilova fonda bo'lgan vaqtda vibratsiya va boshqa mantiqiy amallarni bajara olmaydi.
- **Tavsiya:** Haqiqiy fon ishini (Background Task) ta'minlash uchun `flutter_background_service` yoki `workmanager` kabi paketlardan foydalanish, yoki Android uchun *Foreground Service* ni sozlash lozim.

---

## 🎨 3. UI/UX: Versiya namoyishi

**Taklif:** GitHub tag (v1.0.0) ni ilovaning asosiy ekranida ko'rsatish.

### 💡 Texnik amalga oshirish:
- Loyihada allaqachon `package_info_plus` paketi mavjud.
- `PackageInfo.fromPlatform()` yordamida dastur versiyasini dinamik olib, UI'ning pastki burchagida (masalan: `Opacity` bilan xira qilib) ko'rsatish mumkin.

---

## 📋 Xulosa va Keyingi qadamlar:
1. `versionCode` ni `pubspec.yaml` da har bir Build uchun oshirib borish (`+1` -> `+2`).
2. Ilovani bitta doimiy kalit (Keystore) bilan imzolashni yo'lga qo'yish.
3. Fon rejimida uzluksiz ishlash uchun `Native Background Service` integratsiyasini rejalashtirish.

## ✅ Bajarilgan amaliyotlar
- `pubspec.yaml` versiyasi `1.0.0+2` ga yangilandi.
- Ilovaning asosiy ekrani `PackageInfo` yordamida dinamik versiya ko'rsatish qo'shildi.
- `SharedPreferences` orqali timer holati saqlanishi qo'shildi, shuning uchun ilova fonga ketganida yoki qayta ishga tushganda vaqt yo'qotilmaydi.

---
*Sana: 2026-04-08*
