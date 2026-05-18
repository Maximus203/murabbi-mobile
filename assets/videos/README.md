# assets/videos/ — Vidéos d'onboarding bundlées (ADR-017)

Ce dossier contient les **4 vidéos d'onboarding** embarquées directement dans
l'APK/IPA (stratégie "Option C" — cf. `docs/adr/ADR-017-media-delivery.md`).

Ces vidéos sont nécessaires **avant toute connexion réseau** (splash + slides
de configuration). Elles doivent être présentes pour tout build release.

---

## Fichiers attendus

| Fichier attendu        | Source (dossier assets compressés)         | Écran cible        |
|------------------------|--------------------------------------------|--------------------|
| `02_murabbi.mp4`       | `02 Murabbi.mp4` (ou `.webm`)              | OB-01 Splash       |
| `06_murabbi.mp4`       | `06 Murabbi.mp4` (ou `.webm`)              | OB-02              |
| `04_murabbi.mp4`       | `04 Murabbi.mp4` (ou `.webm`)              | OB-03              |
| `03_murabbi.mp4`       | `03 Murabbi.mp4` (ou `.webm`)              | OB-04              |

**Source locale** :
```
C:\Users\Cherif DIOUF\Documents\Moi\Artist\Projets\06 Murabbi\Assets\Compressed\
```

**Format recommandé** : WebM (VP9) pour Android — plus léger à taille égale.
MP4 (H.264) en fallback si WebM non disponible.

Note : les chemins dans `AppMedia` utilisent l'extension `.mp4`. Si tu fournis
des fichiers `.webm`, mets à jour `AppMedia.splashVideo` etc. en conséquence.

---

## Commande de copie (PowerShell)

```powershell
$src = "C:\Users\Cherif DIOUF\Documents\Moi\Artist\Projets\06 Murabbi\Assets\Compressed"
$dst = "assets\videos"

Copy-Item "$src\02 Murabbi.mp4" "$dst\02_murabbi.mp4"
Copy-Item "$src\06 Murabbi.mp4" "$dst\06_murabbi.mp4"
Copy-Item "$src\04 Murabbi.mp4" "$dst\04_murabbi.mp4"
Copy-Item "$src\03 Murabbi.mp4" "$dst\03_murabbi.mp4"
```

---

## Vidéos in-app (NON bundlées — Supabase Storage)

Les 6 vidéos in-app (01, 07, 08, 09, 10, 11) sont servies depuis le bucket
Supabase `app-media`. Elles ne sont **pas** commitées dans ce repo.

### Upload vers Supabase (Supabase CLI)

```bash
# Créer le bucket (une seule fois, depuis la console Supabase ou via la CLI)
supabase storage create-bucket app-media --public

# Uploader les vidéos
supabase storage cp "01 Murabbi.mp4" ss:///app-media/01_murabbi.mp4
supabase storage cp "07 Murabbi.mp4" ss:///app-media/07_murabbi.mp4
supabase storage cp "08 Murabbi.mp4" ss:///app-media/08_murabbi.mp4
supabase storage cp "09 Murabbi.mp4" ss:///app-media/09_murabbi.mp4
supabase storage cp "10 Murabbi.mp4" ss:///app-media/10_murabbi.mp4
supabase storage cp "11 Murabbi.mp4" ss:///app-media/11_murabbi.mp4
```

Le bucket `app-media` doit être **public en lecture** (accès anonyme).
Aucune donnée sensible ne doit y être stockée.

---

## Note sur .gitignore

Les fichiers MP4/WebM volumineux ne sont pas committés dans le repo Git
(règle §11 — pas de binaires lourds dans le repo). Ce `README.md` est le seul
fichier committé dans ce dossier.

Si tu utilises Git LFS, ajoute la règle dans `.gitattributes` :
```
assets/videos/*.mp4 filter=lfs diff=lfs merge=lfs -text
assets/videos/*.webm filter=lfs diff=lfs merge=lfs -text
```
