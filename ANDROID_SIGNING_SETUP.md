# 🔐 Guide Configuration Android Signing

## ⚡ Setup Rapide

### Étape 1 : Générer ou utiliser ta keystore existante

**Si tu as déjà une keystore** (depuis Google Play) :
```bash
# Place-la ici
cp /chemin/vers/ta/upload-keystore.jks android/app/upload-keystore.jks
```

**Si tu dois créer une nouvelle keystore** :
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key \
  -keypass ta_clé_password \
  -storepass ton_store_password
```

### Étape 2 : Créer ton fichier key.properties

```bash
cp android/key.properties.example android/key.properties
```

Édite `android/key.properties` avec tes vraies valeurs :
```properties
storePassword=ton_store_password
keyPassword=ta_clé_password
keyAlias=upload-key
storeFile=app/upload-keystore.jks
```

### Étape 3 : Vérifier le .gitignore

✅ Vérifie que ces fichiers sont ignorés :
```bash
git status
```

Tu ne dois **JAMAIS** voir :
- `android/key.properties` ❌
- `android/app/upload-keystore.jks` ❌
- `android/app/*.jks` ❌

---

## 🚀 Build Local

```bash
# Maintenant tu peux build avec signing auto
flutter build apk --release

# Ou pour Google Play
flutter build appbundle --release
```

---

## 🔐 Setup GitHub Actions

### Étape 1 : Encoder ta keystore en base64

```bash
base64 -i android/app/upload-keystore.jks > keystore-base64.txt
cat keystore-base64.txt
```

### Étape 2 : Ajouter les secrets GitHub

1. Va sur **GitHub → ton repo → Settings → Secrets and variables → Actions**
2. Clique **New repository secret** et ajoute ces 4 secrets :

| Secret | Valeur | Exemple |
|--------|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Contenu du fichier `keystore-base64.txt` | `MIIFjQIBAgI...` |
| `ANDROID_KEY_PASSWORD` | Mot de passe de ta clé | `ma_clé_password` |
| `ANDROID_STORE_PASSWORD` | Mot de passe du keystore | `mon_store_password` |
| `ANDROID_KEY_ALIAS` | Alias de la clé | `upload-key` |

### Étape 3 : Vérifier le workflow

Le workflow `.github/workflows/flutter-build.yml` va automatiquement :
1. Décoder la keystore depuis base64
2. Créer `key.properties` avec les secrets
3. Signer l'APK/Bundle automatiquement

---

## ⚠️ Sécurité - Points Importants

### ✅ À FAIRE :
- ✅ Ajouter `android/key.properties` à `.gitignore`
- ✅ Ajouter `android/app/*.jks` à `.gitignore`
- ✅ Stocker la keystore de façon sécurisée (drive perso, password manager)
- ✅ Rotation régulière des mots de passe des secrets GitHub
- ✅ Limiter l'accès aux secrets GitHub (Settings → Environments)

### ❌ À ÉVITER :
- ❌ Ne jamais commiter `key.properties`
- ❌ Ne jamais commiter la `.jks`
- ❌ Ne jamais partager les secrets GitHub en clair
- ❌ Ne jamais faire d'echo des secrets dans les logs

---

## 🔧 Troubleshooting

### ❌ "Cannot decode keystore" en GitHub Actions
→ Vérifier que le base64 a été bien copié (pas de retours à la ligne)

### ❌ "Wrong password" 
→ Vérifier que les secrets GitHub correspondent exactement à la keystore

### ❌ "File not found: key.properties"
→ C'est normal en CI/CD, le workflow la crée depuis les secrets

### ❌ "key.properties" est apparu dans Git
```bash
# Annuler immédiatement
git rm --cached android/key.properties
git commit -m "Remove accidentally committed key.properties"
```

---

## 📋 Checklist Finale

- [ ] Keystore générée ou importée → `android/app/upload-keystore.jks`
- [ ] `android/key.properties` créée depuis `key.properties.example`
- [ ] `.gitignore` contient les keystores et key.properties
- [ ] Test build local : `flutter build apk --release`
- [ ] Secrets GitHub ajoutés (4 secrets)
- [ ] Workflow GitHub Actions créé
- [ ] Test de push → le workflow lance automatiquement

---

## 📚 Ressources

- [Flutter Signing Doc](https://flutter.dev/to/reference-keystore)
- [Android Signing](https://developer.android.com/studio/publish/app-signing)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
