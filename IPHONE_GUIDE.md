# ⚡ Mashkal Overlay - iPhone 15 Guide

## 📱 متطلبات الجهاز

- **iPhone 15** (أو أي جهاز iOS 14+)
- **Jailbroken** (Dopamine, palera1n, checkra1n, unc0ver, Taurine)
- **Theos** مثبت
- **NewTerm** أو **MTerminal** أو أي terminal app

---

## 🚀 التثبيت السريع (3 خطوات)

### الخطوة 1: نقل المشروع للـ iPhone

**الطريقة 1: عبر SSH**
```bash
# من الكمبيوتر:
scp -r MashkalTweak root@<iphone-ip>:/var/mobile/
```

**الطريقة 2: عبر Filza**
1. نفّس ملف ZIP على الكمبيوتر
2. انقل المجلد `MashkalTweak` إلى `/var/mobile/` عبر Filza

**الطريقة 3: عبر afc2**
```bash
# استخدام ifunbox أو أي file manager
# انقل المجلد إلى /var/mobile/
```

---

### الخطوة 2: تثبيت تلقائي (موصى به)

```bash
# افتح Terminal على iPhone
su
# أدخل كلمة مرور root (الافتراضية: alpine)

cd /var/mobile/MashkalTweak

# تشغيل سكربت التثبيت
./install.sh
```

**السكربت يقوم تلقائياً بـ:**
- ✅ تثبيت Theos (إذا غير موجود)
- ✅ تثبيت الـ dependencies
- ✅ تجميع الـ Tweak
- ✅ تثبيت الـ .deb
- ✅ Respring

---

### الخطوة 3: التفعيل

بعد الـ Respring:
1. **ستظهر نافذة تفعيل** تطلب كلمة المرور
2. **أدخل:** `halak`
3. **تم التفعيل لـ 7 أيام!** 🎉

---

## 🛠️ التثبيت اليدوي (إذا فشل السكربت)

```bash
# 1. الذهاب للمجلد
cd /var/mobile/MashkalTweak

# 2. تثبيت Theos (إذا غير مثبت)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# 3. تثبيت dependencies
apt-get update
apt-get install -y clang ldid dpkg

# 4. تجميع
make clean
make package

# 5. تثبيت
sudo dpkg -i packages/com.mashkal.overlay_*.deb

# 6. Respring
killall -9 SpringBoard
```

---

## 🎮 استخدام الـ Overlay

| الإجراء | الطريقة |
|---------|---------|
| **فتح/إغلاق** | انقر زر ⚡ العائم |
| **سحب** | اسحب من شريط العنوان |
| **تكبير** | Pinch (إصبعين) |
| **التفعيل** | إعدادات → الحماية → أدخل كلمة المرور |

---

## 🔧 حل المشاكل الشائعة

### ❌ "Theos not found"
```bash
export THEOS=/var/theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

### ❌ "ldid not found"
```bash
apt-get install -y ldid
```

### ❌ "clang not found"
```bash
apt-get install -y clang
```

### ❌ "ImGui not found"
```bash
# تثبيت ImGui
apt-get install -y imgui
# أو
mkdir -p $THEOS/include/imgui
cp -r /path/to/imgui/* $THEOS/include/imgui/
```

### ❌ "Build failed"
```bash
# تنظيف وإعادة المحاولة
make clean
make package FINALPACKAGE=1 DEBUG=0
```

### ❌ "Overlay not showing"
```bash
# التحقق من التثبيت
dpkg -l | grep mashkal

# إعادة تثبيت
dpkg -r com.mashkal.overlay
dpkg -i packages/com.mashkal.overlay_*.deb
killall -9 SpringBoard
```

---

## 📞 دعم فني

- **GitHub:** github.com/mashkal/overlay
- **Twitter:** @mashkal_team
- **Email:** support@mashkal.com

---

## 📝 ملاحظات

- **كلمة المرور الافتراضية:** `halak`
- **مدة التفعيل:** 7 أيام
- **الصلاحية:** تنتهي تلقائياً
- **الحفظ:** في Keychain (آمن)

**⚠️ مهم:** لا تشارك كلمة المرور مع أحد!

---

## 🎉 بالتوفيق!

تم التصميم خصيصاً لـ iPhone 15 مع دعم كامل لـ iOS 17+.
