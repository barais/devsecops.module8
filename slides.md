---
theme: seriph
title: "Cours 8 — Reproducible Builds"
background: https://cover.sli.dev
titleTemplate: "%s"
author: Olivier Barais
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
mdc: true
pdf: true
export: true
comark: true
download: true
---

# Cours 8 — Reproducible Builds

**Sécurité de la chaîne d'approvisionnement logicielle**

Université de Rennes / IRISA / DiverSE

<div class="pt-4 text-sm opacity-70">
D'après les slides de la communauté Reproducible Builds<br>
<a href="https://salsa.debian.org/reproducible-builds/reproducible-presentations/" target="_blank">salsa.debian.org/reproducible-builds</a>
</div>

---
layout: section
---

# Motivations
## Trois histoires de développeurs

---

# Alice

**Alice développe un logiciel libre utilisé par des milliers de personnes**

- Elle publie également des binaires en ligne
- Elle a une sœur avec un lourd secret

<v-click>

> Sa sœur est **menacée de chantage** à moins qu'Alice n'insère une porte dérobée (backdoor) dans ses binaires…
>
> Alice ne peut pas refuser. Elle modifie les **binaires** publiés — sans toucher aux sources.

</v-click>

<v-click>

➡ Les utilisateurs téléchargent et installent un binaire compromis **sans le savoir**.

</v-click>

---

# Bob

**Bob développe pour une distribution Linux**

- Il est très rigoureux en matière de sécurité informatique
- Ses serveurs de build ont été **compromis** à son insu

<v-click>

> Les serveurs génèrent désormais des binaires compromis inclus dans la distribution.
>
> Bob ne le sait pas.

</v-click>

<v-click>

➡ Toute la chaîne de distribution est corrompue, **de manière indétectable**.

</v-click>

---

# Carol et Eve

**Carol est une développeuse dont l'ordinateur portable a été physiquement compromis**

- Une *evil maid* (Eve) insère une clé USB pendant son absence
- L'ordinateur est infecté

<v-click>

> Tous les binaires compilés depuis cet ordinateur sont désormais **potentiellement porteurs de malware**.

</v-click>

<v-click>

➡ Même le code source sain produit des binaires compromis.

</v-click>

---

# Le problème général

<img src="/install.jpg" style="max-height:220px; float:right; margin-left:1em; opacity:0.8">

- On peut lire le code source d'un logiciel libre pour y détecter des failles malveillantes
- Mais les **utilisateurs installent des paquets pré-compilés**

<v-click>

<div class="mt-8 text-center text-xl font-bold">
<em>Peut-on faire confiance au processus de compilation ?</em>
</div>

</v-click>

<v-click>

**Trois vecteurs d'attaque :**

- Compromission du développeur (chantage, social engineering)
- Compromission des serveurs de build
- Compromission physique de la machine du développeur

</v-click>

---
layout: section
---

# La solution
## Builds reproductibles

---

# La solution en trois étapes

<v-clicks>

1. **Partir du même code source**

2. **S'assurer que les builds produisent toujours des résultats identiques** (bit à bit)

3. **Comparer les résultats** produits par différentes parties indépendantes

</v-clicks>

---

# Comment cela aide-t-il ?

<img src="/sharing-01.png" style="max-height:340px; margin:auto;">

---

<img src="/sharing-02.png" style="max-height:460px; margin:auto;">

---

<img src="/sharing-03.png" style="max-height:460px; margin:auto;">

---

# Comment les builds reproductibles aident

<v-clicks>

- **Alice** → le chantage sera découvert (les binaires diffèrent des builds indépendants)
- **Bob** → la compromission sera détectée (même résultat)
- **Carol** → l'ordinateur trafiqué sera découvert (builds divergents)

</v-clicks>

<v-click>

<div class="mt-8 p-4 bg-green-800 text-white rounded text-center text-xl font-bold">
Réduit fortement l'incitation à attaquer en premier lieu
</div>

</v-click>

---

# Ce que signifie "reproductible"

**Pas** "builds avec les mêmes dépendances"… ✗

**Pas** builds "fiables"… ✗

<v-click>

<div class="mt-8 p-4 bg-green-800 text-white rounded text-center text-2xl font-bold">
Résultats de build <em>bit à bit identiques</em>
</div>

</v-click>

<v-click>

> **Définition officielle** (reproducible-builds.org/docs/definition/)
>
> *"Un build est reproductible si, à partir du même code source, du même environnement de build et des mêmes instructions de build, toute partie peut recréer des copies bit à bit identiques de tous les artefacts spécifiés."*

</v-click>

---

# Mission des Reproducible Builds

<v-clicks>

- Permettre à quiconque de **vérifier indépendamment** qu'une source donnée produit des résultats identiques bit à bit

- Les Reproducible Builds sont un **bloc de construction essentiel** pour sécuriser les chaînes d'approvisionnement — *ni plus, ni moins*

- Un logiciel (non) sécurisé compilé de façon reproductible reste (non) sécurisé. Mais avec les builds reproductibles, vous avez la certitude d'exécuter le logiciel voulu, compilé depuis les sources voulues

</v-clicks>

---
layout: section
---

# Sources de non-reproductibilité

---

# Attends… ce n'est pas si simple

<v-clicks>

- Ordre des dictionnaires / tables de hachage / bases de données
- Parallélisme dans les builds
- **Timestamps** (horodatages)
- Chemins de build (*build paths*)
- Ordre non-déterministe des fichiers
- Utilisateurs, groupes, `umask`, variables d'environnement, etc.

</v-clicks>

<v-click>

<div class="mt-6 p-3 bg-blue-900 text-white rounded text-center font-bold">
Un défi difficile… mais surmontable !
</div>

</v-click>

---

# Causes les plus fréquentes

**Raisons courantes de non-reproductibilité :**

<v-clicks>

- Timestamps, timestamps, timestamps
- Timestamps, timestamps, timestamps
- Chemins de build, chemins de build
- Tout le reste

</v-clicks>

<v-click>

➡ La principale source de non-reproductibilité dans la pratique est l'**horodatage** des fichiers lors de la compilation.

</v-click>

---
layout: section
---

# Outils
## SOURCE_DATE_EPOCH & diffoscope

---

# SOURCE_DATE_EPOCH

**Qu'est-ce que c'est ?**

- Les timestamps intégrés lors de la compilation sont en grande partie **sans signification**
- `SOURCE_DATE_EPOCH` décrit la date de la **dernière modification des sources** (en secondes depuis l'époque Unix)

<v-clicks>

- Supporté par **de nombreux** outils aujourd'hui (gcc, ghc, sphinx, doxygen, go, rust, …)
- La spécification date de 2015, mise à jour en 2017
- Référence : https://reproducible-builds.org/docs/source-date-epoch/

</v-clicks>

<v-click>

```bash
export SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct)
make
```

</v-click>

---

# diffoscope

**Outil de comparaison profonde pour déboguer les non-reproductibilités**

> *diffoscope tente de trouver la cause des différences entre fichiers ou répertoires. Il décompresse récursivement les archives de nombreux formats et transforme les formats binaires en formes plus lisibles pour les comparer.*

<v-clicks>

- Sortie texte et HTML
- Comparaison récursive des archives
- Fallback sur comparaison hexdump
- Fuzzy-matching pour gérer les renommages

</v-clicks>

<v-click>

🌐 https://diffoscope.org / https://try.diffoscope.org

</v-click>

---

# diffoscope — formats supportés (extrait)

<div style="font-size: 0.65em; columns: 2; gap: 2em;">

Android APK, Android boot images, Apple Xcode .mobileprovision, ar(1) archives, ASM, Berkeley DB, bzip2, cpio, Dalvik .dex, Debian .buildinfo / .changes / .dsc, Device Tree Compiler, ELF binaries, ext2/3/4/btrfs/fat, FreeDesktop Fontconfig, FreePascal .ppu, Gettext .po/.mo, GHC .hi, GIF, Git repositories, GNU R .rdb/.rds, Gnumeric, GPG keybox, Gzip, HTML, ISO 9660, Java .class / .jmod, JavaScript, JPEG, JSON, Linux kernel, LLVM IR, LZ4, lzip, macOS binaries, MS Windows .ico, MS Word .docx, Mono PE, PDF, PNG, PostScript, Python .pyc, RPM, Rust .deflate, SQLite, SquashFS, .tar, tcpdump .pcap, TrueType fonts, WebAssembly, XML, XZ, ZIP, Zstandard…

</div>

<v-click>

> Fallback sur comparaison hexdump, fuzzy-matching, et bien plus !

</v-click>

---

# diffoscope — exemple de découverte de bug

**Caractères aléatoires dans les pages man ?**

```diff
-This manual page documents the usage of WikipediaFS.
+This manual page documents the usageo of WikipediaFS.
```

<v-click>

```c
memcpy(&buf[1], &buf[2], strlen(buf)-1);
// memcpy(3): The memory areas must not overlap!
```

</v-click>

<v-click>

```diff
- memcpy(&buf[1], &buf[2], strlen(buf)-1);
+ memmove(&buf[1], &buf[2], strlen(buf)-1);
```

</v-click>

<v-click>

➡ Comportement indéfini dans `docbook-to-man` pour i386 (bug Debian #842635)  
Les builds reproductibles **trouvent des bugs** insoupçonnés !

</v-click>

---
layout: section
---

# Historique
## Comment en est-on arrivé là ?

---

# Quelques jalons historiques

<v-clicks>

- **2000** : première idée mentionnée sur `debian-devel`
- **2007** : thread sur `debian-devel@lists.debian.org` — jugé irréalisable par beaucoup
- **2011** : Bitcoin (le logiciel) rendu reproductible
- **2013** : Tor Browser rendu reproductible par Mike Perry (un projet de la taille de Firefox !)
- **2013** : Lunar anime une réunion de brainstorming à DebConf13
- **2014** : Lunar anime DebConf14 ; patches pour `dpkg` (sorting + `.buildinfo` = SBOM !)
- **Septembre 2014** : premiers builds systématiques de tous les paquets Debian (deux fois)
- **Décembre 2014** : Mike Perry et Seth Schoen présentent les graphiques au CCCongress

</v-clicks>

---

# CCCongress 2014 — les graphiques fondateurs

<img src="/ccc2014-1.png" style="max-height:420px; margin:auto;">

---

<img src="/ccc2014-5.png" style="max-height:460px; margin:auto;">

---

<img src="/ccc2014-13.png" style="max-height:460px; margin:auto;">

---

# Comment en est-on vraiment arrivé là ?

<v-clicks>

- 💰 **L'argent / Bitcoin** → Bitcoin rendu reproductible en 2011
- 🕵️ **Edward Snowden / Tor Browser** → Firefox rendu reproductible en 2013
- 👥 **... et BEAUCOUP de travail par BEAUCOUP de personnes sur de NOMBREUSES années**

</v-clicks>

<v-click>

<div class="mt-6 p-4 bg-blue-900 text-white rounded">

**2015 :**
- Talk FOSDEM par Lunar et Holger Levsen — invitation de la communauté du logiciel libre
- Talk CCCamp par Lunar — problèmes courants et solutions
- 1er Reproducible Builds Summit à Athènes
- Spécification `SOURCE_DATE_EPOCH`
- Création de `diffoscope`

</div>

</v-click>

---

# Fast-forward 2023

<v-click>

> **WireGuard** (VPN Android) : les builds sont désormais reproductibles, identiques sur leur site web, le Google Play Store et F-Droid. 🎯🎯🎯🥳
>
> — https://lists.zx2c4.com/pipermail/wireguard/2023-April/008045.html

</v-click>

<v-click>

> *"On n'a même pas été informés. Les gens font des builds reproductibles comme une partie normale de leur travail maintenant."* 🤗

</v-click>

<v-click>

**En 2024 :**
- Whitehouse.gov **exige** des SBOM pour les logiciels gouvernementaux
- Whitehouse.gov **recommande** les builds reproductibles et les SBOM vérifiés
- Largement reconnu dans la communauté sécurité : https://reproducible-builds.org/resources/

</v-click>

---
layout: section
---

# Debian & Reproducible Builds

---

# Debian — le terrain d'expérimentation

**Travail sur la reproductibilité de Debian depuis 2013**

- Premier rebuild en 2013 → **24% de paquets reproductibles**
- Mars 2018 → **93% de paquets reproductibles**

<v-click>

**Le "torture test" de Debian :**
- Date & heure
- Hostname & nom de domaine
- Filesystem (`disorderfs`)
- Timezone & locale
- `uid` & `gid`
- Noyau & type de CPU

</v-click>

---

# Statistiques Debian — trixie (2024-02-01)

<img src="/stats_pkg_state_trixie_20240201.png" style="max-height:400px; margin:auto;">

---

# Reproductibilité CI Debian amd64

| Suite | Reproductible | Non-repro | Échec build | Autre |
|-------|--------------|-----------|-------------|-------|
| stretch | 23040 (93.2%) | **1514 (6.1%)** | 85 (0.3%) | 80 |
| buster | 26653 (93.9%) | **1405 (4.9%)** | 232 (0.8%) | 108 |
| bullseye | 29698 (96.2%) | **761 (2.5%)** | 274 (0.9%) | 127 |
| bookworm | 33240 (96.9%) | **670 (2.0%)** | 260 (0.8%) | 124 |
| trixie | 33399 (95.6%) | **619 (1.8%)** | 673 (1.9%) | 135 |

<v-click>

➡ Progression régulière, mais il reste encore des cas à traiter.

</v-click>

---

# Statistiques Debian — unstable (2024-02-01)

<img src="/stats_pkg_state_20240201.png" style="max-height:400px; margin:auto;">

---

# Bugs liés à la reproductibilité

<img src="/stats_bugs_sin_ftbfs_state.png" style="max-height:220px; margin:auto;">

<v-click>

**3852 bugs de reproductibilité corrigés** (en grande partie en amont), 301 patches en attente…

</v-click>

<v-click>

<img src="/stats_bugs_state.png" style="max-height:180px; margin:auto;">

**32 000 bugs en 10 ans ≈ 8 par jour !**

</v-click>

---

# Politique Debian

<v-clicks>

- **2017** : les paquets *devraient* être compilés de façon reproductible
- **2025 ?** : les paquets reproductibles *ne doivent pas* régresser
- **2025 ?** : les *nouveaux* paquets *doivent* être compilés de façon reproductible
- **2027 ?** : tous les paquets *doivent* être compilés de façon reproductible

</v-clicks>

<v-click>

**100% reproductible est une décision politique, pas technique.**

➡ Il faut modifier `debian-policy` !

➡ Les *whitelists* permettent de progresser vers cet objectif.

</v-click>

---

# Les rebuilders — vers 100% en pratique

<img src="/bookworm_full.amd64+all.png" style="max-height:380px; margin:auto;">

<div class="text-sm text-center opacity-70">Résultats des rebuilders — beta.tests.reproducible-builds.org/debian</div>

---

# 100% reproductible ne suffit pas

<v-clicks>

- Il faut ensuite des **rebuilders** (différents des builders CI)
- Pour cela il faut un service `snapshot.debian.org` fonctionnel
- Sans `snapshot.d.o`, impossible de recréer les environnements exacts…
- Or snapshot est buggé : #1050815, #1031628, #1029744, #1034000, #1012559…

</v-clicks>

<v-click>

**Solution en cours : rebuilder-snapshot.debian.net**

- Cache pour `snapshot.d.o` : stocke uniquement les paquets utilisés comme build-depends *aujourd'hui*
- Accessibles via SHA256, chemin et API
- ~100 GB par arch et suite — raisonnable !
- Deux instances déjà opérationnelles, objectif : permettre de nombreuses instances

</v-click>

---
layout: section
---

# Au-delà de Debian

---

# L'écosystème des builds reproductibles

**De nombreux projets adoptent les builds reproductibles :**

<v-clicks>

- **Distributions** : coreboot, Fedora, OpenWRT, NetBSD, FreeBSD, Archlinux, Qubes
- **Gestionnaires de paquets** : NixOS, Guix, F-Droid
- **Outils de build** : Meson, et bien d'autres
- **Autres projets** utilisant le framework de test de Debian

</v-clicks>

<v-click>

**Summits Reproducible Builds** : Athènes, Berlin, Paris, Marrakech, Venise, Hambourg…

🌐 https://reproducible-builds.org

</v-click>

---

# Bénéfices inattendus

<v-clicks>

- **Réduction des coûts** de développement et **vitesse accrue** grâce à moins d'attente pour les builds (meilleur cache ratio = économie de temps, d'argent et de CO₂)
- **Développement logiciel** : ce changement a-t-il vraiment l'effet escompté uniquement ?
- **Conformité de licence** : on ne peut être sûr qu'un binaire est un Logiciel Libre que si on peut le reconstruire reproduciblement depuis une source donnée
- **SBOMs vérifiés** reproductiblement

</v-clicks>

---
layout: section
---

# Perspectives
## Théorie vs pratique

---

# Théorie vs pratique

<v-clicks>

- En théorie, nous avons montré que les builds reproductibles sont faisables
- En pratique, nous avons besoin de :
  - **Rebuilders** (≠ builders CI) en grand nombre
  - Stockage des résultats
  - Critères sur la façon dont les outils doivent traiter ces données
  - Les outils eux-mêmes…
- Ces 5% manquants sont **cruciaux** : pour Debian, 1% = 300 logiciels

</v-clicks>

---

# Feuille de route

<v-clicks>

- Finir les derniers 1-5% en amont
- Créer l'infrastructure de rebuilders en pratique
- Créer l'infrastructure, les processus et les outils pour utiliser ces résultats de façon sécurisée
- Consensus et engagement au niveau des projets envers les builds reproductibles en pratique
- **Prochaine étape pour Debian forky (2025)** : pénalités dans la migration testing pour les paquets non-reproductibles

</v-clicks>

---

# Ressources

<v-clicks>

- 📖 https://reproducible-builds.org/docs/ — documentation officielle
- 🐛 422 types de problèmes connus dans `reproducible-notes.git`
- 🎓 Talk de Lunar à CCCamp 2015
- 🔬 https://github.com/bmwiedemann/theunreproduciblepackage — exemples de pièges
- 📊 https://reproducible-builds.org/docs/publications/ — publications académiques

</v-clicks>

<v-click>

**Failles exploitées montrant l'importance du sujet :**
- SolarWinds (2020) — build server compromis
- XZ Utils (CVE-2024-3094) — backdoor insérée dans le processus de build

</v-click>

---

# S'impliquer

<div class="mt-4">

| | |
|---|---|
| 🌐 Visiter | https://reproducible-builds.org/ |
| 📧 S'abonner | `lists.reproducible-builds.org` → `rb-general` |
| 🐦 Suivre | **@ReproBuilds** sur X |
| 💬 Rejoindre | `#reproducible-builds` (sur OFTC) |

</div>

<v-click>

<div class="mt-8 p-4 bg-green-800 text-white rounded text-center">

**Les builds reproductibles ne sont pas une fin en soi, mais un maillon essentiel**  
**d'une chaîne d'approvisionnement logicielle sécurisée.**

</div>

</v-click>

---
layout: section
---

# Partie pratique
## Pourquoi un build n'est-il pas reproductible ?

---

# Objectifs & prérequis

**But :** compiler le *même* code deux fois et constater que le résultat n'est **pas** identique bit à bit.

<v-clicks>

- Même code source → deux compiles → le hash est-il le même ? (souvent non !)
- Pour chaque cause : l'observer → appliquer le remède → revérifier que tout redevient identique
- Prérequis : `gcc`, `python3`, `diffoscope` (`sudo apt install diffoscope`)

</v-clicks>

---

# Démo 1 — Les timestamps dans le binaire

Le préprocesseur `gcc` capture l'instant de compilation dans le binaire.

```c
#include <stdio.h>
int main(){ printf("compile le %s a %s\n", __DATE__, __TIME__); return 0; }
```

```bash
gcc hello.c -o h1 ; sleep 1 ; gcc hello.c -o h2     # 2 compiles à 1 s d'écart
sha256sum h1 h2                                     # ⚠ deux hash DIFFÉRENTS
diffoscope h1 h2                                    # ...et on voit pourquoi !
```

<v-click>

> Le binaire "correct" n'existe pas : il change à chaque seconde écoulée.

</v-click>

---

# Démo 1 — Le remède : SOURCE_DATE_EPOCH

Fixer une fois pour toutes la "date des sources" (dernier commit, par exemple) :

```bash
export SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct)
gcc hello.c -o h3 ; sleep 1 ; gcc hello.c -o h4
sha256sum h3 h4                                     # ✅ deux hash IDENTIQUES
```

<v-click>

- `gcc` fait correspondre `__DATE__`, `__TIME__` et `__TIMESTAMP__` à `SOURCE_DATE_EPOCH`
- Recompiler à n'importe quel moment → même date embarquée → mêmes binaires

</v-click>

---

# Démo 2 — Le chemin de build dans le binaire

Le chemin absolu de compilation fuite dans le binaire (via `__FILE__`, infos de debug…).

```bash
mkdir -p A B ; cp hello.c A/ ; cp hello.c B/
(cd A && gcc -g hello.c -o bin) ; (cd B && gcc -g hello.c -o bin)
strings A/bin | grep hello.c                         # le chemin absolu apparaît
sha256sum A/bin B/bin                                # ⚠ deux hash DIFFÉRENTS
```

<v-click>

> Deux machines différentes (chemins différents) → mêmes sources → binaires différents.

</v-click>

---

# Démo 2 — Le remède : -ffile-prefix-map

Normaliser vers un chemin canonique identique pour toute la chaîne :

```bash
(cd A && gcc -g -ffile-prefix-map=/chemin/A=/build/src hello.c -o bin)
(cd B && gcc -g -ffile-prefix-map=/chemin/B=/build/src hello.c -o bin)
sha256sum A/bin B/bin                                # ✅ deux hash IDENTIQUES
```

<v-click>

- `-ffile-prefix-map` / `-fdebug-prefix-map` / `-fmacro-prefix-map` effacent le préfixe propre à l'hôte
- En pratique : on build toujours depuis un répertoire canonique (ex. `/build`)

</v-click>

---

# Démo 3 — L'ordre de parcours des tables de hachage

Parcourir un dictionnaire / un ensemble n'a **aucun ordre garanti**.

```bash
for s in 1 2 3; do PYTHONHASHSEED=$s python3 \
  -c 'print(list({"delta-kernel","beta-xorg","alpha-libs"}))'; done
# delta-kernel beta-xorg alpha-libs
# beta-xorg alpha-libs delta-kernel ...
```

<v-click>

- Une archive produite en parcourant dans cet ordre sera **différente** selon la graine
- ➡ Toujours **trier** les entrées avant d'écrire une archive, une base, un fichier

</v-click>

---

# Bilan — Causes et remèdes

| Cause de non-reproductibilité | Remède |
|---|---|
| Timestamps (`__DATE__`, mtimes) | `SOURCE_DATE_EPOCH` |
| Chemin de build dans le binaire | `-ffile-prefix-map` |
| Ordre des hash / bases de données | trier avant d'écrire |
| uid / gid / umask | `fakeroot`, permissions normalisées |
| Hostname / locale / fuseau | environnement maîtrisé (CI) |

<v-click>

<div class="p-3 bg-blue-900 text-white rounded text-center font-bold">
Compilez 2× le même code → si un hash diffère, lancez `diffoscope` pour trouver la cause !
</div>

</v-click>

---
layout: center
class: text-center
---

# Merci !

<div class="mt-8">
  <img src="/logo.svg" style="height:80px; margin:auto;">
</div>

<div class="mt-6 text-sm opacity-70">
https://reproducible-builds.org
</div>
