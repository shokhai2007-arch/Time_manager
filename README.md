# Time Manager

**Time Manager** — bu Flutter asosida yaratilgan vaqt boshqaruvi (interval) taymer ilovasi.  
Ilova Neumorphic dizayn uslubida qurilgan bo‘lib, foydalanuvchiga umumiy vaqt va period vaqtini berib, fokuslangan ishlash jarayonini boshqarishga yordam beradi.

## Asosiy imkoniyatlar

- Umumiy taymer va period taymerni alohida sozlash
- Start / Pause / Resume boshqaruvi
- Uzoq bosish orqali to‘liq reset
- Circular progress ring orqali vizual kuzatuv
- Vibratsiya orqali period yakuni va taymer tugashini bildirish
- Ilova fon rejimiga o‘tganda ham taymer holatini saqlash

## Texnologiyalar

- Flutter
- Riverpod (state management)
- Shared Preferences (holatni saqlash)
- flutter_background_service (fon rejimida ishlash)
- flutter_neumorphic_plus (UI uslubi)

## Ishga tushirish

1. Dependensiyalarni o‘rnating:
   ```bash
   flutter pub get
   ```
2. Ilovani ishga tushiring:
   ```bash
   flutter run
   ```

## Loyiha tuzilmasi

- `lib/main.dart` — asosiy UI va ekranlar
- `lib/timer_controller.dart` — taymer logikasi va holat boshqaruvi
- `lib/background_service.dart` — fon servisi
- `lib/widgets/haptic_ring.dart` — markaziy progress ring komponenti
