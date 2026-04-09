# GitHub Actions APK Builder - O'rnatish Qo'llanmasi

## 📋 Umumiy Tahlif

Bu GitHub Actions workflow **Time Manager** ilovasining release APK faylini avtomatik ravishda yaratadi va GitHub Releases-ga yuklaydi.

**Asosiy xususiyatlari:**
- ✅ Dart kodni tekshirish (format, analyze)
- ✅ Flutter testlarini o'tkazish
- ✅ Release APK yaratish (production-ready)
- ✅ APK faylni imzolash (signing)
- ✅ GitHub Releases-ga avtomatik e'lon qilish
- ✅ Gradle caching - qurangga tez qurish
- ✅ Java 17 va Flutter 3.x qo'llab-quvvatlash

---

## 🔐 GitHub Secrets O'rnatish

APK imzolash uchun quyidagi secrets-larni o'rnating:

### 1️⃣ **Keystore Faylini Yaratish** (Birinchi marta)

```bash
# Keystore yaratish
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalias upload \
  -keyalg RSA \
  -keysize 4096 \
  -validity 10000 \
  -storepass "YOUR_STORE_PASSWORD" \
  -keypass "YOUR_KEY_PASSWORD"
```

### 2️⃣ **Keystore-ni Base64 ga Kodlash**

```bash
# Linux/Mac
base64 -i android/app/upload-keystore.jks

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))
```

### 3️⃣ **GitHub Secrets-ni Qo'shish**

GitHub repository settings-iga o'ting: **Settings → Secrets and variables → Actions**

Quyidagi secrets-larni qo'shing:

| Secret Nomi | Qiymati | Misol |
|-------------|---------|-------|
| `KEYSTORE_BASE64` | Keystore faylining base64 kodi | `MIIJuAIBA...` |
| `STORE_PASSWORD` | Keystore paroli | `YourStorePassword123!` |
| `KEY_PASSWORD` | Key paroli | `YourKeyPassword123!` |
| `KEY_ALIAS` | Key alias nomi | `upload` |

---

## 🚀 Workflow so'nggi xususiyatlari

### Bir xil Joblar
Workflow **3 ta parallel job**-dan iborat:

#### 1. **analyze** - Kod Tahlifi
```
- Dart formatting tekshirish
- Flutter analyze o'tkazish
- Issues topish va xabar berish
```

#### 2. **test** - Testlarni O'tkazish
```
- Unit va widget testlarini o'tkazish
- Agar test ishlamasa, ogohlantirish bilan davom ettish
```

#### 3. **build-apk** - APK Yaratish
```
- Java 17 o'rnatish
- Flutter dependencies yuklab olish
- Gradle optimization qo'llash
- APK qurish (Release mode)
- APK imzolash (agar main branch bo'lsa)
- GitHub Release-ga yuklash
```

### Trigger Shartlari

| Hodisa | Shaxsi | Natija |
|--------|--------|--------|
| Push to `main` | ✅ | Release APK qurish, imzolash, GitHub Release-ga yuklash |
| Push to `develop` | ✅ | Release APK qurish (unsigned) |
| Pull Request | ✅ | Tahlif va testlar, APK qurish (unsigned) |

---

## 📦 Gradle Optimization (Avtomatik)

Workflow quyidagi Gradle optimizatsiyalarni qo'llagani:

```properties
org.gradle.daemon=true              # Daemon qo'llanish (tezroq)
org.gradle.parallel=true             # Parallel qurish
org.gradle.configureondemand=true    # Lazy configuration
org.gradle.caching=true              # Build cache
org.gradle.jvmargs=-Xmx8G            # 8GB RAM ajratish
```

**Natija:** Birinchi qurish ~5 min, keyingisi ~2 min

---

## 🔍 Workflow Tahlifi va Debugging

### Workflow Status Ko'rish

1. GitHub repository-ga o'ting
2. **Actions** tabiga bosing
3. So'ngi workflow-ni tanlang va logsni ko'ring

### Umumiy Muammolar va Yechimlar

#### ❌ **"APK not found" xatosi**
```
Sabab: Build muvaffaqiyatsiz tugadi
Yechim: Flutter analyze va test logs-ni o'qiyng
```

#### ❌ **"Keystore not found" xatosi**
```
Sabab: KEYSTORE_BASE64 secret-i noto'g'ri
Yechim: Base64 kodlashni qayta o'tkazib ko'ring
```

#### ❌ **Build timeout (15 min dan ko'p)**
```
Sabab: Gradle cache-i ishlamayapti
Yechim: Runner cache-i tozalash uchun GitHub settings-da cache o'chirib yuborish
```

---

## 📝 Pubspec Version Management

APK versiyasi `pubspec.yaml`-dan o'qiladi:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

**Release tag misoli:** `v1.0.0-build1`

---

## 🎯 APK Output Files

### Release APK
- **Location:** `build/app/outputs/flutter-apk/app-release.apk`
- **Size:** ~50-70 MB
- **Imzolangan:** ✅ (main branch-da)

### Artifact Storage
- GitHub Releases-ga 30 kun saqlash mumkin
- Artifacts tab-iga 30 kun saqlash mumkin

---

## 🔧 Qo'shimcha Konfiguratsiya

### Main branch-da avtomatik imzolash uchun:

1. Keystore faylini yaratish (yuqorida ko'rish)
2. Secrets-ni o'rnating (yuqorida ko'rish)
3. `push to main` qiling - workflow avtomatik ishlaydi

### Debug APK yaratish (agar kerak bo'lsa)

Workflow-ni o'zgartirib:
```yaml
flutter build apk --debug --verbose
```
branchni o'zgartirib:
```yaml
if: github.event_name == 'pull_request'
```

---

## 📞 Foydalanuvchi Ma'lumotlari

- **Release Notes:** Oxirgi 5 ta commit-ni ko'rsatadi
- **Versiya:** pubspec.yaml-dan o'qiladi
- **Build vaqti:** UTC vaqtida belgilanadi
- **Workflow linki:** GitHub Release sharhlariga kiritiladi

---

## ✅ Tekshirish Ro'yxati

Birinchi run-da quyidagini tekshiring:

- [ ] Secrets-lar GitHub-da o'rnated
- [ ] Workflow fayli `.github/workflows/flutter_ci.yml` mavjud
- [ ] `pubspec.yaml` versiyasi to'g'ri
- [ ] Keystore faylini yaratdingiz
- [ ] Test-lar o'tisdi
- [ ] APK muvaffaqiyatli yaratildi
- [ ] GitHub Release-ga yuklandi

---

**Tayyorlangan:** GitHub Actions Flutter APK Builder  
**Oxirgi yangilash:** 2026-04-09
