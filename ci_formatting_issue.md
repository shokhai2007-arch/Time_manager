# CI/CD Xatoligi: Dart Format Muammosi va Yechimi

## 🛑 Muammo (Root Cause)
GitHub Actions CI/CD pleyplaynida (workflow) **"Verify formatting"** bosqichida xatolik yuz berdi va jarayon to'xtatildi (Exit code 1).

**Sababi:** 
Workflow faylida formatlashni tekshirish uchun quyidagi buyruq kiritilgan edi:
```bash
dart format --output=none --set-exit-if-changed .
```
Bu buyruq loyihadagi barcha `.dart` fayllarni tekshiradi. Agar biron bir fayl Flutter/Dart kodlash standartlariga (formatiga) to'liq mos kelmasa va unga o'zgarish kiritish kerak bo'lsa, `--set-exit-if-changed` bayrog'i sababli u `1` (xato) kodini qaytarib, butun CI jarayonini to'xtatib qo'yadi. 

Biz ko'rgan loglarga ko'ra, xususan quyidagi fayllar standartga muvofiq formatlanmagan edi:
- `lib/main.dart`
- `lib/timer_controller.dart`
- `lib/updater.dart`

## ✅ Taklif Etilgan va Qo'llanilgan Yechim (Solution)
Ushbu muammoni hal qilishning optimal va eng to'g'ri (Best Practice) usuli qo'llanildi.

**Qo'llanilgan Qadamlar:**
1. Loyiha papkasida barcha kodlarni to'g'ri formatlash uchun mahalliy terminalda (lokal) quyidagi buyruq ishga tushirildi:
   ```bash
   dart format .
   ```
2. Yuqorida sanab o'tilgan 3 ta fayl qoidaga mos ravishda formatlandi.
3. Hosil bo'lgan o'zgarishlar gitga qo'shilib, yangi commit qilindi va GitHub serveriga jo'natildi:
   ```bash
   git add .
   git commit -m "style: apply dart format to all lib files"
   git push origin main
   ```

**Natija:** Yangi muvaffaqiyatli yaratilgan kodlar hech qanday sintaksis va format xatolarisiz bo'lganligi uchun, navbatdagi CI jarayoni muammosiz ishlaydi va *Verify formatting* bosqichidan osonlik bilan o'tadi.

### Muqobil varianti (Biroq tavsiya etilmaydi)
Agar har safar format tekshiruvida CI qulashini xohlamasak, `.github/workflows/flutter_ci.yml` faylida o'sha bosqichni quyidagicha o'zgartirish mumkin edi:
```yaml
  - name: Verify formatting
    run: dart format --output=none .
```
Lekin bu usulda yozilgan kod qat'iy standartga ega bo'lmaydi va boshqa dasturchilar o'qishiga qiyin bo'lishi mumkin. Shuning uchun kodni doim GitHub'ga yuklashdan oldin `dart format .` qilish e'tibor qaratilishi kerak bo'lgan eng yaxshi odatdir.
