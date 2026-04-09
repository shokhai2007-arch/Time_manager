# 📌 Known Issues & Improvements

## 🐞 Muammolar (Bugs)

### 🔄 Update xususiyati noto‘g‘ri ishlayapti

* Ilova yangilanganda mavjud versiya ustiga yozilmayapti
* Buning o‘rniga yangi ilova sifatida qayta o‘rnatilmoqda

#### ❗ Kutilgan natija:

* Ilova eski versiya ustiga **update** qilinishi kerak

#### ⚠️ Hozirgi holat:

* Har safar update → yangi install bo‘lyapti
* Foydalanuvchi uchun noqulaylik tug‘diradi

#### 💡 Ehtimoliy sabablar:

* `applicationId` o‘zgarib ketgan bo‘lishi mumkin
* `signing config` (debug/release key) mos emas
* versioning noto‘g‘ri (`versionCode`, `versionName`)

---

## 🎨 UI/UX Improvements

### 🏷️ Versiyani ekranda ko‘rsatish

* GitHub tag (`v1.0.0`) loyihaning asosiy versiyasi sifatida ishlatiladi

#### ✅ Taklif:

* Versiyani bosh ekranda kichik va unobtrusive tarzda chiqarish

  * Masalan: `v1.0.0`
  * Pastki qismda yoki corner’da joylashgan bo‘lishi mumkin

#### 🎯 Foydasi:

* Foydalanuvchi qaysi versiyadan foydalanayotganini biladi
* Debug va support jarayonlari osonlashadi
* Release’lar bilan sinxronlik saqlanadi

---

## 🚀 Kelajakdagi yaxshilanishlar

* Auto-update mexanizmini to‘g‘rilash
* Versioning tizimini standartlashtirish
* UI elementlarni minimal va foydalanuvchiga qulay qilish

---

✍️ *Ushbu hujjat loyiha sifatini oshirish va foydalanuvchi tajribasini yaxshilash maqsadida tuzildi.*
