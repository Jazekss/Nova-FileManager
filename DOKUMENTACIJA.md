# Nova File Manager — īsā dokumentācija (LV)

## Kas ir izmantots

- **Flutter / Dart** — viena kodu bāze: Android lietotne + Windows lietotne (`desktop/nova_transfer/` → `NovaTransfer.exe`).
- **Provider** — stāvokļa pārvaldība; **Material 3** — dizains (zilā `0xFF3D5AFE` tēma).
- **shared_preferences** — iestatījumu un pāriena saglabāšana; **mobile_scanner** — QR skenēšana; **qr_flutter** — QR attēlošana.
- **dart:io HttpServer** — iebūvētais tīkla serveris abās ierīcēs (PC ports 48320).
- **crypto + cryptography** — HMAC-SHA256 paraksti un AES-256-GCM šifrēšana.
- **Android Keystore** — Vault atslēga; **MediaMetadataRetriever** — video sīktēļi; **PackageManager** — īstās `.apk` ikonas.
- **archive / commons-compress / unrar5j** — ZIP / 7z / RAR lasīšana.
- **9 valodas** caur `gen-l10n` (ARB faili `lib/l10n/`).

## Funkcijas

| Bloks | Ko māk |
|---|---|
| Home | Krājuma aizpildījums (iekšējais + SD), Recycle bin izmērs, Drive karte (vēl neaktīva) |
| File Manager | Saraksts/vidējie/lielie sīktēļi, īstie attēlu/video/APK sīktēļi, multi-select, kopēt/pārvietot/dzēst/pārdēvēt/zip, Recycle bin, Vault |
| Meklēšana | Teksts + `*.pdf` tipa wildcards, krājums/mape/datumi, sistēmas mapes netiek skenētas |
| PC share | QR pāriena → pārlūkot PC mapes, lejupielādēt telefonā, augšupielādēt uz PC; telefons var šērot failus atpakaļ PC logam |
| Vault | PIN + biometrija, AES-256-GCM `.nvx` faili, mapes ZIP→šifrē |
| Nova Transfer | Windows lietotne: divas kolonnas, "Share APK via QR", tēma/valoda/kafija |

## Drošība (novērtējums: labs LAN līmenim)

- Pāriena tokens ir tikai QR kodā — **pa tīklu neceļo**.
- Katrs pieprasījums: `HMAC-SHA256` paraksts + laika zīmogs (±10 min) → atveras/neizklausāms un pret replay.
- Visi dati: **AES-256-GCM** šifrēti (atslēga = SHA-256(token)).
- Failu piekļuve tikai norādītajās mapēs; `../` ceļi atteikti.
- Vault: AES-256-GCM + atslēga Android Keystore — faili uz diska ir šifrēti pat ar root.
- Atklātā daļa: `GET /apk?token=` (kamera→pārlūks) — apzināti, jo pārlūks nevar atšifrēt; lietojams tikai apzinātai APK kopīgošanai.
- **Piezīme:** tas ir LAN kripto bez sertifikātu pārbaudes — pilnīgai MITM aizsardzībai vajadzētu QR verificēt arī pašu TLS sertifikātu (tālsolnākšana).

## Ko vēl varētu pielikt nākotnē

- Google Drive reālais darbības režīms (OAuth ir sagatavots, gaida consent screen publicēšanu/testlietotājus).
- SSH/HTTPS (pašparakstīts sertifikāts ar QR fingerprint), ja paredzēts ne-tikai-LAN lietojums.
- Screenshoti README + Play Store listing, kad projekts ir "piepumpēts" un stabils.
