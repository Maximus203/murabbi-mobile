# Médias non versionnés

Les dossiers suivants sont **exclus** de ce repo Git pour rester sous la limite GitHub et éviter de versionner du binaire lourd :

- `media/` : 11 vidéos onboarding `.mp4` + leurs fallback `.png` (~80 MB)
- `uploads/` : copies des MP4 + assets divers (logos, screenshots) (~50 MB)

## Source de vérité

Les fichiers d'origine sont dans :

```
C:\Users\Cherif DIOUF\Documents\Moi\Artist\Projets\06 Murabbi\Assets\Maquettes\Murabbi Mobile\
├── media/        (vidéos onboarding finales)
└── uploads/      (assets brut)
```

Plus loose :
```
C:\Users\Cherif DIOUF\Documents\Moi\Artist\Projets\06 Murabbi\Assets\
├── 01 Murabbi.mp4 ... 11 Murabbi.mp4    (versions originales)
├── Compressed/                          (versions .webm)
└── Images/                              (photos Unsplash)
```

## Plan d'intégration ultérieur

1. **Phase 1 mobile** — décider de la stratégie de delivery des vidéos d'onboarding :
   - **Option A** : Bundlées dans l'IPA/APK (tradeoff : taille du build initial)
   - **Option B** : Téléchargées au premier launch via Supabase Storage (tradeoff : besoin de connexion à l'install)
2. Uploader les MP4 finales sur Supabase Storage bucket `onboarding-media` (privé en read pour anon, signed URLs)
3. Référencer les URLs dans une table `onboarding_assets` ou directement en constante côté mobile
4. Pour l'admin : pas besoin de versionner les médias en doc — ils sont déjà accessibles via le chemin local source ci-dessus

## Pour visualiser le HTML wireframes

Si tu ouvres `Murabbi Wireframes.html` ou `Murabbi Admin.html` dans un navigateur depuis ce repo, les vidéos seront cassées (404 sur `media/*.mp4`). Pour preview avec vidéos, ouvrir depuis `Assets/Maquettes/Murabbi Mobile/` (chemin local complet) directement.
