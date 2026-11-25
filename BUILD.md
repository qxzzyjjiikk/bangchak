# Bangchak → IPA

โฟลเดอร์ `Bangchak` มี `Bangchak.xcodeproj` พร้อมเปิดแล้ว — ไม่ต้องติดตั้ง generator
bundle id: `xyz.rlzx.bangchak` (เซ็นด้วย Apple ID ธรรมดาได้)

---

## ทาง A — มี Mac + Xcode

```bash
cd Bangchak
open Bangchak.xcodeproj
```

ใน Xcode: target **Bangchak** → Signing & Capabilities → เลือก Team → ⌘R (simulator หรือเครื่องจริง)

### ออกเป็น IPA (ไม่เซ็น — เอาไปเซ็นด้วย Sideloadly)

```bash
chmod +x scripts/package-ipa.sh
./scripts/package-ipa.sh
# → build/Bangchak.ipa
```

### ออกเป็น IPA ที่เซ็นแล้ว (AltStore ใช้ได้เลย)

```bash
xcodebuild -project Bangchak.xcodeproj -scheme Bangchak \
  -configuration Release -sdk iphoneos \
  -archivePath build/Bangchak.xcarchive archive -allowProvisioningUpdates

xcodebuild -exportArchive -archivePath build/Bangchak.xcarchive \
  -exportPath build/export -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
# → build/export/Bangchak.ipa
```

หรือใน Xcode: **Product ▸ Archive** → Organizer → Distribute App ▸ Development

---

## ทาง B — ไม่มี Mac (เครื่อง Windows นี้ก็ทำได้)

### B1. GitHub Actions (ฟรี, runner macOS)

```bash
cd Bangchak
git init && git add . && git commit -m "Bangchak 1.0"
git branch -M main
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

`.github/workflows/build-ipa.yml` จะ build เอง (~5–8 นาที)
→ แท็บ **Actions** → run ล่าสุด → ดาวน์โหลด artifact `Bangchak-ipa` → แตกได้ `Bangchak.ipa` (ไม่เซ็น)

### B2. เช่า Mac ทางไกล

MacinCloud / MacStadium / Scaleway Mac mini — อัปโหลดโฟลเดอร์ แล้วทำตามทาง A

---

## ติดตั้งลงเครื่อง (sideload)

IPA ที่ไม่เซ็นติดตั้งตรง ๆ ไม่ได้ ต้องเซ็นด้วย Apple ID:

| เครื่องมือ | หมายเหตุ |
|---|---|
| **Sideloadly** (Windows) | ใส่ Apple ID → sign → ติดตั้งผ่าน USB, 7 วัน |
| **AltStore / SideStore** | ต่อ WiFi, refresh ทุก 7 วัน |
| **TrollStore** | ไม่ต้องเซ็น ไม่หมดอายุ (ตาม iOS build) |
| **Apple Developer Program** | เซ็นเองได้ 1 ปี |

---

## ตรวจ IPA

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::OpenRead("build\Bangchak.ipa").Entries |
  Select-Object -First 6 FullName
# Payload/Bangchak.app/Bangchak
# Payload/Bangchak.app/Info.plist
# Payload/Bangchak.app/Assets.car
```

---

## ฟีเจอร์ที่มีในแอป

- สแกน/ล้าง `Library/Caches` + `tmp` ของตัวเอง (มี guard กันออกนอกคอนเทนเนอร์)
- วงแหวนพื้นที่เครื่อง + สรุปคอนเทนเนอร์ + ปุ่มเลือกเป้าหมายที่จะล้าง
- ตัว browse ไฟล์ในแซนด์บ็อกซ์: เข้าโฟลเดอร์, ลบ, **Import** จาก Files app, **Export** ผ่าน share sheet
- ธีม System/Light/Dark
- ไม่มีหน้าใส่คีย์ ไม่มีเพลง ไม่มีวิดีโอพื้นหลัง ไม่เรียกเน็ต

## ขีดจำกัดที่ยังคงอยู่

แอปแตะได้แค่คอนเทนเนอร์ของตัวเอง ไม่มี app group ของทีมอื่น
การเข้าถึง data ของแอปอื่นบนเครื่องไม่ jailbreak ต้องอาศัยช่องโหว่ระดับระบบ
ซึ่งไม่อยู่ในขอบเขตของโปรเจกต์นี้
