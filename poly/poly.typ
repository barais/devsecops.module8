// ============================================================
// Polycopié — Cours 8 : Reproducible Builds
// Université de Rennes · IRISA / DiverSE
// Olivier Barais
// ============================================================

#set document(
  title: "Cours 8 — Reproducible Builds",
  author: "Olivier Barais",
  date: datetime(year: 2026, month: 9, day: 1),
)

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  header: context {
    if counter(page).get().first() > 1 [
      #set text(size: 8pt, fill: luma(130))
      #grid(columns: (1fr, 1fr),
        [DevSecOps — Cours 8 · Université de Rennes],
        align(right)[Olivier Barais]
      )
      #line(length: 100%, stroke: 0.5pt + luma(200))
    ]
  },
  footer: context [
    #set text(size: 8pt, fill: luma(130))
    #line(length: 100%, stroke: 0.5pt + luma(200))
    #v(2pt)
    #grid(columns: (1fr, 1fr),
      [IRISA / DiverSE · 2026],
      align(right)[Page #counter(page).display("1")]
    )
  ]
)

#set text(font: "New Computer Modern", size: 10.5pt, lang: "fr")
#set par(justify: true, leading: 0.65em, spacing: 1.2em)
#set heading(numbering: "1.1")

#show heading.where(level: 1): it => {
  v(1.5em)
  block(
    fill: rgb("#1e40af"),
    radius: 4pt,
    inset: (x: 10pt, y: 6pt),
    width: 100%,
    text(fill: white, size: 14pt, weight: "bold")[#it.body]
  )
  v(0.5em)
}

#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 12pt, weight: "bold", fill: rgb("#1d4ed8"))[#it.body]
  v(0.3em)
}

#show heading.where(level: 3): it => {
  v(0.5em)
  text(size: 11pt, weight: "bold", fill: rgb("#374151"))[#it.body]
  v(0.2em)
}

// Boîte d'alerte
#let alert(color: red, icon: "⚠", body) = block(
  fill: color.lighten(90%),
  stroke: 0.8pt + color,
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[
  #text(weight: "bold")[#icon  ] #body
]

// Boîte d'exemple
#let example(title, body) = block(
  fill: rgb("#f0f9ff"),
  stroke: (left: 3pt + rgb("#0ea5e9")),
  inset: (left: 12pt, right: 10pt, top: 8pt, bottom: 8pt),
  width: 100%,
)[
  #text(weight: "bold", fill: rgb("#0369a1"))[Exemple — #title] \
  #v(4pt)
  #body
]

// Boîte de définition
#let definition(term, body) = block(
  fill: rgb("#f5f3ff"),
  stroke: (left: 3pt + rgb("#7c3aed")),
  inset: (left: 12pt, right: 10pt, top: 8pt, bottom: 8pt),
  width: 100%,
)[
  #text(weight: "bold", fill: rgb("#6d28d9"))[Définition — #term] \
  #v(4pt)
  #body
]

// Boîte de retenir
#let keypoint(body) = block(
  fill: rgb("#fff7ed"),
  stroke: (left: 3pt + rgb("#ea580c")),
  inset: (left: 12pt, right: 10pt, top: 8pt, bottom: 8pt),
  width: 100%,
)[
  #text(weight: "bold", fill: rgb("#c2410c"))[À retenir] \
  #v(4pt)
  #body
]

// Style des blocs de code
#show raw.where(block: true): it => block(
  fill: rgb("#0f172a"),
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[#text(fill: rgb("#94a3b8"), size: 9pt, font: "New Computer Modern")[#it]]

// ============================================================
// PAGE DE TITRE
// ============================================================

#align(center)[
  #v(2cm)
  #block(
    fill: rgb("#1e3a8a"),
    radius: 8pt,
    inset: 20pt,
    width: 90%,
  )[
    #text(fill: white, size: 11pt)[DevSecOps — Université de Rennes · IRISA / DiverSE]
    #v(8pt)
    #text(fill: white, size: 20pt, weight: "bold")[Cours 8]
    #v(4pt)
    #text(fill: rgb("#93c5fd"), size: 15pt)[Reproducible Builds]
    #v(4pt)
    #text(fill: rgb("#bfdbfe"), size: 11pt)[Motivations · Définition · Outils · Historique · Debian · Perspectives]
  ]
  #v(1.5cm)
  #text(size: 11pt)[Olivier Barais]
  #v(0.3em)
  #text(size: 10pt, fill: luma(80))[Université de Rennes · IRISA · Équipe DiverSE]
  #v(0.3em)
  #text(size: 10pt, fill: luma(80))[D'après les présentations de la communauté Reproducible Builds]
  #v(0.3em)
  #text(size: 10pt, fill: luma(80))[salsa.debian.org/reproducible-builds/reproducible-presentations/]
  #v(0.3em)
  #text(size: 10pt, fill: luma(80))[2026]
]

#pagebreak()

// ============================================================
// TABLE DES MATIÈRES
// ============================================================

#outline(title: "Table des matières", depth: 2, indent: 1.5em)

#pagebreak()

// ============================================================
// 1. MOTIVATIONS
// ============================================================

= Motivations : trois histoires de développeurs

Les attaques sur la chaîne d'approvisionnement logicielle peuvent prendre de nombreuses formes. Trois scénarios illustrent les vecteurs les plus représentatifs, et permettent de comprendre pourquoi les approches de sécurité traditionnelles sont insuffisantes.

== Alice : la compromission par contrainte externe

Alice est développeuse et maintient un logiciel libre utilisé par des milliers de personnes. Elle publie à la fois le code source et des binaires précompilés en ligne. Confrontée à un chantage (sa sœur est menacée), elle est forcée d'insérer une backdoor dans les *binaires* publiés — sans modifier le code source accessible publiquement.

Du point de vue des utilisateurs et des administrateurs de systèmes, rien n'est détectable : les sources semblent saines, le code source est identique à ce qui est annoncé, et les binaires sont signés avec le certificat officiel d'Alice. Les outils de vérification d'intégrité classiques ne décèlent rien de suspect.

#alert(color: rgb("#dc2626"), icon: "⚠")[
  Alice illustre la dissociation entre *code source* et *binaires distribués*. Cette dissociation est précisément ce que les builds reproductibles cherchent à éliminer : si un tiers peut reconstruire un binaire bit à bit depuis la source officielle et obtenir le même résultat, toute modification du binaire sera détectée immédiatement.
]

== Bob : la compromission de l'infrastructure de build

Bob développe pour une distribution Linux. Il est très rigoureux en matière de sécurité informatique : ses systèmes sont maintenus à jour, ses accès sont protégés par authentification forte. Malgré tout, les *serveurs de build* de son organisation ont été compromis à son insu. Ces serveurs génèrent désormais des binaires modifiés qui deviennent partie intégrante de la distribution.

Bob ne le sait pas. Il inspecte son code source et ne voit rien d'anormal. Il vérifie ses processus CI/CD et n'observe pas d'anomalie visible. Pourtant, des centaines de milliers d'utilisateurs installent des paquets portant une backdoor.

Ce scénario est loin d'être théorique. L'attaque SolarWinds (2020) @solarwinds2021 en est l'illustration emblématique : le groupe APT29 a compromis l'infrastructure de build de SolarWinds, injectant du code malveillant lors de la phase de *compilation* de la plateforme Orion. Les binaires produits étaient signés avec le certificat officiel de SolarWinds. Environ 18 000 organisations ont reçu la mise à jour piégée, dont le Département du Trésor américain et la NSA.

== Carol : la compromission physique (evil maid attack)

Carol est développeuse. Lors d'un déplacement, une attaquante (#emph[evil maid]) accède physiquement à son ordinateur portable pendant son absence et y insère une clé USB infectée. L'ordinateur est compromis à un niveau bas (bootloader, firmware). Dès lors, tous les binaires compilés depuis cet ordinateur sont potentiellement porteurs de malware, même si le code source est parfaitement sain.

Carol rentre chez elle et reprend son travail. Elle compile son code normalement. Les binaires produits semblent corrects, les tests passent — mais un composant invisible dans la chaîne de compilation empoisonne les artefacts produits.

== Le problème général

Ces trois histoires convergent vers un problème fondamental :

- On peut lire le code source d'un logiciel libre pour y détecter des failles malveillantes
- Mais les utilisateurs finaux installent des *paquets pré-compilés*

#keypoint[
  La question centrale : *peut-on faire confiance au processus de compilation ?*

  Un logiciel libre dont le code source est sain peut produire des binaires compromis si :
  - le développeur est contraint d'altérer les binaires (Alice) ;
  - l'infrastructure de build est compromise (Bob, SolarWinds) ;
  - la machine du développeur est physiquement compromise (Carol).
]

// ============================================================
// 2. LA SOLUTION : BUILDS REPRODUCTIBLES
// ============================================================

= La solution : builds reproductibles

== Principe en trois étapes

La réponse à ce problème repose sur un principe simple, mais dont la mise en œuvre est techniquement exigeante :

1. *Partir du même code source* — tous les participants disposent de la même base de départ, publiée de manière transparente et vérifiable ;
2. *S'assurer que les builds produisent toujours des résultats identiques* — c'est-à-dire bit à bit identiques, quel que soit l'environnement de build (machine, heure, utilisateur) ;
3. *Comparer les résultats produits par différentes parties indépendantes* — si A et B construisent indépendamment le même logiciel depuis la même source et obtiennent le même binaire, et si C le fait également, la probabilité qu'un attaquant ait réussi à compromettre simultanément les trois est extrêmement faible.

== Comment cela résout les trois scénarios

#block(
  fill: rgb("#f8fafc"),
  stroke: 0.5pt + luma(200),
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[
  #table(
    columns: (auto, 1fr),
    stroke: none,
    fill: (_, row) => if calc.odd(row) { luma(248) } else { white },
    inset: 7pt,
    [*Scénario*], [*Comment les builds reproductibles aident*],
    [Alice], [Le binaire publié diffère de celui qu'un tiers reconstruit depuis les sources → le chantage est découvert dès la première vérification indépendante],
    [Bob], [Le binaire produit par le serveur compromis diffère de celui d'un rebuild tiers → la compromission est détectée automatiquement],
    [Carol], [Le binaire produit sur la machine infectée diffère du rebuild d'un tiers → la compromission physique est mise en évidence],
  )
]

L'effet le plus important n'est pas nécessairement la *détection* systématique : c'est la *dissuasion*. Si un attaquant sait que ses modifications seront très probablement découvertes lors d'une vérification indépendante, l'incitation à attaquer disparaît en grande partie.

== Définition officielle

#definition("Build reproductible")[
  Un build est reproductible si, à partir du même code source, du même environnement de build et des mêmes instructions de build, toute partie peut recréer des copies bit à bit identiques de tous les artefacts spécifiés. @rb_definition

  Les attributs pertinents de l'environnement de build, les instructions et le code source ainsi que les artefacts reproductibles attendus sont définis par les auteurs ou distributeurs.
]

Il est important de distinguer ce que cette définition exige de ce qu'elle n'exige *pas* :

- Ce n'est pas "builds avec les mêmes dépendances" : un build peut utiliser exactement les mêmes dépendances et produire des résultats différents à cause d'un timestamp ou d'un chemin de build.
- Ce n'est pas des builds "fiables" au sens de "qui fonctionnent bien" : un logiciel bogué peut être compilé de façon parfaitement reproductible.
- C'est des *résultats bit à bit identiques* : chaque octet de l'artefact produit doit être identique.

== Mission de la communauté

La communauté Reproducible Builds @rb_resources formule sa mission ainsi :

> *Permettre à quiconque de vérifier indépendamment qu'une source donnée produit des résultats bit à bit identiques. Les Reproducible Builds sont un maillon essentiel pour sécuriser les chaînes d'approvisionnement logicielles — ni plus, ni moins.*

Un logiciel non sécurisé compilé de façon reproductible reste non sécurisé. Mais avec les builds reproductibles, on a la certitude d'exécuter *exactement* le logiciel issu des sources qu'on souhaite utiliser, et non une version modifiée en cours de chemin.

// ============================================================
// 3. SOURCES DE NON-REPRODUCTIBILITÉ
// ============================================================

= Sources de non-reproductibilité

La définition est simple, mais l'implémentation soulève un problème majeur : un grand nombre de comportements normaux du processus de build introduisent du non-déterminisme. Ces sources de variation rendent les builds différents d'une exécution à l'autre, même en partant exactement du même code source.

== Catégories principales

=== Timestamps

La cause de non-reproductibilité la plus fréquente, et de loin. De nombreux outils intègrent automatiquement la date et l'heure de compilation dans les artefacts produits :

- Compilateurs C/C++ : `__DATE__` et `__TIME__` dans le préprocesseur
- Générateurs de documentation (Sphinx, Doxygen) : date dans les en-têtes de pages
- Outils d'archivage (zip, tar) : timestamps des fichiers dans l'archive
- Langages comme Go, Rust, Java : métadonnées de build dans les exécutables

Chaque reconstruction, même à quelques secondes d'intervalle, produit un binaire différent à cause de ces timestamps.

=== Chemins de build (#emph[build paths])

Certains outils intègrent dans les artefacts produits le chemin absolu du répertoire de build. Deux développeurs qui compilent depuis `/home/alice/projet` et `/home/bob/projet` obtiennent des binaires différents. Ce problème concerne notamment :

- Les symboles de débogage dans les ELF (`.debug_line`, `.debug_str`)
- Les messages de log et assertions en C (`__FILE__`)
- Les chemins dans les artefacts Python compilés (`.pyc`)

=== Ordre des fichiers non-déterministe

Les systèmes de fichiers ne garantissent pas un ordre de parcours déterministe. Des opérations comme `ls *.c | xargs gcc` ou l'itération sur un dictionnaire peuvent produire des ordres différents selon le système, le kernel, ou le filesytem utilisé :

```bash
# Non-reproductible : l'ordre de ls dépend du filesystem
gcc $(ls *.c) -o programme

# Reproductible : tri explicite
gcc $(ls *.c | sort) -o programme
```

=== Parallélisme dans les builds

Les builds parallèles (`make -j4`) peuvent produire des résultats différents si les tâches ne sont pas correctement isolées. Les systèmes de build modernes comme Ninja et Bazel ont été conçus avec ce problème en tête, mais de nombreux Makefiles historiques en souffrent.

=== Variables d'environnement et contexte système

Utilisateur (`uid`, `gid`), hostname, timezone, locale, variables d'environnement (`PATH`, `HOME`, `TMPDIR`), type de CPU, noyau : tous ces éléments peuvent influencer le comportement de certains outils et être intégrés dans les artefacts produits.

#keypoint[
  *La règle des trois P* : les causes de non-reproductibilité sont, par ordre de fréquence : (1) les *P*ath timestamps (#emph[horodatages]), (2) les chemins de build (*P*aths), (3) tout le reste.

  La bonne nouvelle : la grande majorité des problèmes de non-reproductibilité sont désormais bien identifiés, documentés, et des solutions existent pour chacun d'eux @rb_docs.
]

// ============================================================
// 4. OUTILS FONDAMENTAUX
// ============================================================

= Outils fondamentaux

== SOURCE_DATE_EPOCH

`SOURCE_DATE_EPOCH` est la solution principale au problème des timestamps @source_date_epoch. Il s'agit d'une variable d'environnement standardisée qui indique aux outils de build quelle date utiliser à la place de la date courante du système.

=== Principe

```bash
# Définir SOURCE_DATE_EPOCH à partir du dernier commit git
export SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct)

# La variable contient le timestamp Unix du dernier commit
# Exemple : 1709562657

# Tous les outils qui supportent SOURCE_DATE_EPOCH l'utilisent
# à la place de $(date +%s)
make
```

La valeur exprime le temps en secondes depuis l'époque Unix (1er janvier 1970). Elle correspond généralement à la date de la dernière modification des sources dans le dépôt git, ce qui est sémantiquement cohérent : le binaire produit porte la date de la dernière modification du code, pas la date de compilation.

=== Adoption

La spécification a été créée en 2015 et mise à jour en 2017. Elle est aujourd'hui supportée par un très grand nombre d'outils :

#block(
  fill: rgb("#f8fafc"),
  stroke: 0.5pt + luma(200),
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[
  #table(
    columns: (auto, 1fr),
    stroke: none,
    fill: (_, row) => if calc.odd(row) { luma(248) } else { white },
    inset: 7pt,
    [*Catégorie*], [*Outils supportant SOURCE_DATE_EPOCH*],
    [Compilateurs], [GCC, Clang, Go, Rust, GHC (Haskell)],
    [Documentation], [Sphinx, Doxygen, Javadoc, Asciidoctor],
    [Systèmes de build], [CMake, Meson, Autotools, Maven, Gradle],
    [Langages de script], [Python (py_compile), Perl],
    [Archivage], [GNU tar, cpio, zip (via libzip)],
    [Paquetage], [dpkg, rpm, Maven, npm (via certaines configurations)],
  )
]

Lorsqu'un outil ne supporte pas encore `SOURCE_DATE_EPOCH`, deux approches sont possibles : soit contribuer un patch à l'outil en amont (#emph[upstream]), soit appliquer un patch local dans le système de paquetage de la distribution.

== diffoscope

`diffoscope` est l'outil de référence pour déboguer les non-reproductibilités @diffoscope. Son rôle est de répondre à la question : *pourquoi deux builds du même logiciel produisent-ils des binaires différents ?*

=== Principe de fonctionnement

```bash
# Comparer deux versions d'un paquet compilé
diffoscope ./build1/programme ./build2/programme

# Sortie HTML pour une analyse visuelle
diffoscope --html rapport.html ./build1/paquet.deb ./build2/paquet.deb

# Version en ligne pour des tests rapides
# https://try.diffoscope.org
```

`diffoscope` applique une décomposition récursive : pour comparer deux fichiers `.deb`, il les décompresse, compare les métadonnées, puis compare chaque fichier contenu — y compris les binaires ELF, les archives `.a`, les fichiers `.pyc`, les fichiers de documentation, etc. Pour chaque format, il applique la transformation la plus appropriée pour obtenir une représentation lisible par l'humain.

=== Formats supportés

La liste des formats supportés est impressionnante, couvrant la quasi-totalité des types d'artefacts produits par les distributions Linux modernes : exécutables ELF, archives Debian et RPM, images ISO et systèmes de fichiers (ext4, SquashFS, FAT), conteneurs Android (APK, DEX), documents PDF, images JPEG/PNG, archives ZIP/tar/bzip2/xz/lz4/zstandard, bases de données SQLite, fichiers Java (`.class`, `.jar`, `.jmod`), fichiers Python (`.pyc`), binaires Rust, et bien d'autres. En dernier recours, une comparaison hexadécimale est utilisée.

=== diffoscope trouve des bugs réels

#example("Bug de corruption mémoire découvert via diffoscope")[
  Lors de l'analyse d'une non-reproductibilité dans les pages man de `WikipediaFS`, diffoscope a révélé :

  ```diff
  -This manual page documents the usage of WikipediaFS.
  +This manual page documents the usageo of WikipediaFS.
  ```

  Un caractère `o` supplémentaire apparaissait de façon non-déterministe. Remontée à la source, la cause était un appel `memcpy` avec zones mémoires qui se chevauchent (comportement indéfini en C) dans `docbook-to-man` pour l'architecture i386 (bug Debian #842635) :

  ```c
  // Comportement indéfini : zones mémoires overlappantes
  memcpy(&buf[1], &buf[2], strlen(buf)-1);

  // Correction : utiliser memmove
  memmove(&buf[1], &buf[2], strlen(buf)-1);
  ```

  Ce bug de corruption mémoire latent, indétectable par les tests fonctionnels, n'a été découvert que grâce à la recherche de reproductibilité.
]

Les builds reproductibles ne servent pas seulement à la sécurité de la supply chain : ils constituent un outil de *qualité logicielle* qui force à éliminer des comportements non-déterministes qui peuvent cacher des bugs sérieux.

== disorderfs

`disorderfs` @disorderfs est un système de fichiers FUSE qui randomise l'ordre de parcours des répertoires. Il est utilisé dans le "torture test" de Debian pour simuler un environnement de build dont le comportement est délibérément différent du premier build :

```bash
# Monter le répertoire source avec ordre aléatoire
disorderfs --shuffle-dirents=yes /source /mnt/disordered

# Compiler depuis le montage désordonné
make -C /mnt/disordered
```

Si le build produit un résultat identique malgré le désordre du système de fichiers, c'est un indicateur fort que la non-reproductibilité liée à l'ordre des fichiers a bien été éliminée.

// ============================================================
// 5. HISTORIQUE ET COMMUNAUTÉ
// ============================================================

= Historique et communauté

== Les origines (avant 2013)

L'idée des builds reproductibles est ancienne. Une première mention apparaît sur la liste `debian-devel@lists.debian.org` en 2000, puis une discussion plus substantielle en 2007 — jugée irréalisable par de nombreux participants à l'époque.

== Les catalyseurs (2011–2013)

Deux événements ont véritablement lancé le mouvement des builds reproductibles à grande échelle.

=== Bitcoin (2011)

Bitcoin (#emph[le logiciel]) a été rendu reproductible en 2011 via un système appelé Gitian @bitcoin_reproducible. La raison est évidente : pour un logiciel gérant des crypto-monnaies, il est crucial que les utilisateurs puissent vérifier que le binaire qu'ils installent correspond exactement au code source audité. Un binaire modifié pourrait subtiliser des fonds.

Bitcoin a démontré la *faisabilité pratique* des builds reproductibles pour un projet de taille réelle, et a motivé d'autres projets critiques à suivre.

=== Tor Browser (2013)

Mike Perry a rendu le Tor Browser reproductible en 2013 @torbrowser_reproducible. L'importance de cette réalisation est considérable : le Tor Browser est basé sur Firefox, l'un des projets logiciels les plus complexes au monde (des millions de lignes de code, des dizaines de dépendances). Sa reproductibilité a montré que même des projets d'une telle envergure pouvaient atteindre cet objectif.

Le contexte était celui des révélations Snowden (2013) sur la surveillance de masse par la NSA. Pour des outils d'anonymat comme Tor, la confiance dans les binaires distribués est existentielle : un binaire compromis pourrait identifier des activistes, des journalistes, ou des lanceurs d'alerte.

== La fondation de la communauté (2013–2015)

Lunar a animé une réunion de brainstorming à DebConf13 (DebConf = conférence annuelle Debian), puis une autre à DebConf14. Ces réunions ont produit des patches concrets pour `dpkg` : corrections de tri et introduction des fichiers `.buildinfo` (#emph[Software Bill of Materials] avant l'heure).

En septembre 2014, Holger Levsen a lancé les premiers builds systématiques de *tous* les paquets Debian, deux fois successivement (pour comparer), en partant de zéro. Les graphiques produits ont été présentés par Mike Perry et Seth Schoen au CCCongress (31C3) en décembre 2014 @mikeperry_ccc2014, exposant l'état de la reproductibilité de Debian à l'ensemble de la communauté de sécurité.

En 2015 @lunar_fosdem2015 @lunar_ccccamp2015 :

- Talk FOSDEM par Lunar et Holger Levsen — invitation de la communauté du logiciel libre à rejoindre l'effort
- Talk CCCamp par Lunar — documentation des problèmes courants et de leurs solutions
- Premier #emph[Reproducible Builds Summit] à Athènes
- Spécification `SOURCE_DATE_EPOCH`
- Création de `diffoscope`

== Fast-forward 2023 : la normalisation

En avril 2023, l'équipe de WireGuard Android a annoncé sur sa liste de diffusion @wireguard2023 que ses builds étaient désormais reproductibles et identiques sur leur site web, le Google Play Store, et F-Droid — sans avoir prévenu la communauté Reproducible Builds. Ce détail est révélateur :

> *"On n'a même pas été informés. Les gens font des builds reproductibles comme une partie normale de leur travail maintenant."*

Cette normalisation est l'un des indicateurs les plus clairs du succès du mouvement.

En 2024, les Reproducible Builds sont reconnus à l'échelle institutionnelle :
- Le Whitehouse.gov *exige* des SBOM (#emph[Software Bill of Materials]) pour les logiciels gouvernementaux américains @whitehouse_sbom2021
- Les builds reproductibles et les SBOM vérifiés sont *recommandés* (pas encore exigés) dans les mêmes textes
- La communauté a tenu des summits à Athènes, Berlin, Paris, Marrakech, Venise et Hambourg @rb_summit_history

// ============================================================
// 6. DEBIAN ET LES BUILDS REPRODUCTIBLES
// ============================================================

= Debian et les builds reproductibles

Debian est la distribution Linux qui a investi le plus massivement dans les builds reproductibles, et constitue le terrain d'expérimentation de référence de la communauté.

== Le torture test

Depuis 2013, l'infrastructure CI de Debian reconstruit chaque paquet *deux fois*, dans des environnements délibérément différents pour maximiser les chances de détecter les non-reproductibilités :

#block(
  fill: rgb("#f8fafc"),
  stroke: 0.5pt + luma(200),
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[
  #table(
    columns: (auto, auto),
    stroke: none,
    fill: (_, row) => if calc.odd(row) { luma(248) } else { white },
    inset: 7pt,
    [*Variable modifiée*], [*Méthode*],
    [Date et heure], [Premier build à l'heure courante, second avec une heure différente],
    [Hostname et domaine], [Noms de machine différents entre les deux builds],
    [Filesystem], [`disorderfs` pour randomiser l'ordre des répertoires],
    [Timezone et locale], [Configurations différentes (UTC vs Europe/Berlin, fr_FR vs en_US)],
    [`uid` et `gid`], [Utilisateurs avec des identifiants numériques différents],
    [Noyau et CPU], [Noyaux différents, parfois émulation de microarchitecture différente],
  )
]

Si les deux builds produisent des binaires bit à bit identiques malgré toutes ces variations, le paquet est considéré reproductible.

== Progression historique

#block(
  fill: rgb("#f8fafc"),
  stroke: 0.5pt + luma(200),
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[
  #table(
    columns: (auto, auto, auto, auto, auto),
    stroke: none,
    fill: (_, row) => if calc.odd(row) { luma(248) } else { white },
    inset: 7pt,
    [*Suite Debian*], [*Reproductibles*], [*Non-repro*], [*Échec build*], [*Autre*],
    [stretch], [23 040 (93,2 %)], [1 514 (6,1 %)], [85 (0,3 %)], [80 (0,4 %)],
    [buster], [26 653 (93,9 %)], [1 405 (4,9 %)], [232 (0,8 %)], [108 (0,4 %)],
    [bullseye], [29 698 (96,2 %)], [761 (2,5 %)], [274 (0,9 %)], [127 (0,4 %)],
    [bookworm], [33 240 (96,9 %)], [670 (2,0 %)], [260 (0,8 %)], [124 (0,4 %)],
    [trixie], [33 399 (95,6 %)], [619 (1,8 %)], [673 (1,9 %)], [135 (0,4 %)],
  )
]

La progression est régulière et conséquente : de 24 % lors du premier rebuild en 2013, à plus de 96 % pour bookworm en 2024. La communauté a corrigé plus de 32 000 bugs liés à la reproductibilité en dix ans, soit environ 8 par jour.

== Politique et gouvernance

La politique Debian (#emph[Debian Policy]) évolue progressivement vers l'exigence formelle de reproductibilité @debian_policy_rb :

- *2017* : les paquets *devraient* être compilés de façon reproductible (recommandation)
- *2025 (objectif)* : les paquets reproductibles *ne doivent pas* régresser
- *2025 (objectif)* : les *nouveaux* paquets *doivent* être compilés de façon reproductible
- *2027 (objectif)* : tous les paquets *doivent* être compilés de façon reproductible

Depuis fin 2023, les résultats de reproductibilité CI sont intégrés dans les excuses de migration Debian testing, mais sans pénalité encore. Des pénalités sont prévues pour Debian 14 (#emph[forky]).

== Au-delà du CI : les rebuilders

La reproductibilité dans l'environnement CI est une condition nécessaire mais non suffisante. Pour qu'un utilisateur puisse vérifier indépendamment un binaire distribué par Debian, il faut des *rebuilders* — des machines indépendantes qui reconstruisent les paquets en production, et publient leurs résultats.

La difficulté principale est la nécessité de disposer du même environnement de build exact, ce qui requiert l'accès aux mêmes versions des dépendances. `snapshot.debian.org` archive toutes les versions de tous les paquets Debian, mais souffre de problèmes chroniques de performance et de fiabilité.

La solution en cours de déploiement est `rebuilder-snapshot.debian.net` @rebuilder_snapshot :

- Cache optimisé pour `snapshot.d.o`, stockant uniquement les paquets réellement utilisés comme build-depends
- ~100 Go par architecture et suite (au lieu de téraoctets pour snapshot complet)
- Accessibles via SHA256, chemin et API REST
- Deux instances déjà opérationnelles

// ============================================================
// 7. AU-DELÀ DE DEBIAN
// ============================================================

= Au-delà de Debian et perspectives

== L'écosystème des builds reproductibles

Le mouvement des builds reproductibles s'est étendu bien au-delà de Debian :

#block(
  fill: rgb("#f8fafc"),
  stroke: 0.5pt + luma(200),
  radius: 4pt,
  inset: 10pt,
  width: 100%,
)[
  #table(
    columns: (auto, 1fr),
    stroke: none,
    fill: (_, row) => if calc.odd(row) { luma(248) } else { white },
    inset: 7pt,
    [*Domaine*], [*Projets*],
    [Distributions Linux], [Fedora, Archlinux, NixOS, Guix, OpenWRT, Alpine Linux, Qubes OS],
    [Systèmes firmware], [coreboot, LEDE/OpenWRT],
    [BSD], [NetBSD, FreeBSD],
    [Stores d'applications], [F-Droid (Android), Flathub],
    [Systèmes de build], [Meson (builds reproductibles par défaut), Bazel, Nix],
    [Cryptomonnaies], [Bitcoin Core, de nombreux wallets],
    [Navigateurs], [Tor Browser, Brave, Chromium (objectif)],
  )
]

== Bénéfices inattendus

La recherche de reproductibilité apporte des bénéfices au-delà de la sécurité de la supply chain :

*Réduction des coûts de build.* Un build reproductible est un build dont les artefacts peuvent être mis en cache de façon fiable. Si le même input produit toujours le même output, le cache est 100 % fiable. Des systèmes comme Bazel et Nix l'exploitent pour des gains de temps et de ressources considérables. Pour de grands monorepos, les économies sur les temps de CI peuvent représenter des millions d'euros annuels.

*Validation de l'effet des modifications.* Si un changement ne modifie pas le binaire produit (par exemple, une modification de commentaire ou un refactoring de code mort), un build reproductible le confirme instantanément. Inversement, si un changement censé être purement cosmétique modifie le binaire, c'est une alerte.

*Conformité de licence.* On ne peut être certain qu'un binaire est un Logiciel Libre que si on peut le reconstruire reproduciblement depuis une source donnée. Sans reproductibilité, il est impossible de prouver que le binaire distribué correspond à la source publiée.

*SBOMs (#emph[Software Bill of Materials]) vérifiés.* Les fichiers `.buildinfo` produits par Debian lors des builds reproductibles sont une forme primitive de SBOM : ils listent exactement quelles versions de quels paquets ont été utilisées pour construire un artefact donné. Ces SBOMs sont *vérifiables* si les builds sont reproductibles.

== Théorie vs pratique

Une distinction importante s'est imposée dans la communauté : réussir à produire des builds reproductibles (#emph[CI reproducibility]) est nécessaire mais ne suffit pas. Voici l'état réel des choses :

*Ce qui est fait.* La reproductibilité en environnement CI a été prouvée pour la grande majorité des paquets de distributions majeures (96-97 % pour Debian bookworm). Les outils existent, les patterns de correction sont documentés @theunreproduciblepackage.

*Ce qui reste à faire.* Pour que la promesse de sécurité soit réelle, il faut des *rebuilders indépendants* qui reconstruisent les paquets en production, publient leurs résultats dans un format standardisé, et que des outils côté utilisateur (gestionnaires de paquets) vérifient automatiquement ces résultats avant l'installation.

*L'infrastructure est en construction.* Les rebuilders existent (quelques machines gérées par la communauté), `rebuilder-snapshot.debian.net` lève le principal obstacle technique @rebuilder_snapshot, et la migration Debian testing commencera à imposer des contraintes de reproductibilité en 2025.

#keypoint[
  La reproductibilité à 100 % est une décision *politique*, pas un problème *technique* insurmontable. Les 3-4 % de paquets non-reproductibles restants représentent soit des logiciels abandonnés depuis longtemps, soit des cas techniques difficiles mais résolubles. Pour Debian, 1 % de non-reproductible représente tout de même ~350 logiciels utilisés par des millions d'utilisateurs.
]

== Lien avec SLSA et la supply chain globale

Les builds reproductibles s'inscrivent dans un cadre plus large. Le framework SLSA (#emph[Supply chain Levels for Software Artifacts]) @slsa2023 propose des niveaux d'assurance croissants pour la sécurité de la chaîne d'approvisionnement :

- *SLSA Level 1* : processus de build documenté
- *SLSA Level 2* : build sur infrastructure CI/CD avec logs d'audit
- *SLSA Level 3* : build sur infrastructure dédiée, isolation forte
- *SLSA Level 4* : builds reproductibles + revue par deux personnes

Les builds reproductibles constituent la pierre angulaire du niveau 4 du framework SLSA. Ils permettent de créer des *attestations de provenance* vérifiables : la preuve que tel artefact a été produit depuis telle source, par tel processus de build, et que n'importe qui peut reproduire le résultat.

Les incidents majeurs comme SolarWinds @solarwinds2021 (compromission du build server) ou XZ Utils @xzutils2024 (compromission patiente sur deux ans) auraient été détectables beaucoup plus tôt avec un système de rebuilders reproductibles opérationnel.

// ============================================================
// CONCLUSION
// ============================================================

= Conclusion

Les builds reproductibles constituent une réponse fondamentale à une question fondamentale : peut-on faire confiance aux binaires distribués pour qu'ils correspondent exactement à leur code source ? La réponse traditionnelle était de faire confiance aux auteurs et aux distributeurs. Les builds reproductibles remplacent cette confiance aveugle par une *vérification cryptographique et indépendante*.

La communauté Reproducible Builds a démontré en dix ans que l'objectif est techniquement réalisable à grande échelle. Debian, avec plus de 33 000 paquets reproductibles (96-97 %), est la preuve la plus convaincante. Les outils existent (`diffoscope`, `SOURCE_DATE_EPOCH`, `disorderfs`), les patterns de correction sont documentés, et la communauté est active et bien organisée.

Mais la promesse de sécurité ne se réalisera pleinement que lorsque trois conditions seront réunies : (1) une couverture proche de 100 % des logiciels critiques, (2) une infrastructure de rebuilders indépendants opérationnelle et décentralisée, et (3) une intégration dans les gestionnaires de paquets pour que la vérification soit automatique et transparente pour les utilisateurs.

Ces trois conditions sont en cours de réalisation. L'intégration dans la politique Debian testing, le déploiement de `rebuilder-snapshot.debian.net`, et la reconnaissance institutionnelle (#emph[Whitehouse.gov], ENISA @enisa2021supply, cadre SLSA @slsa2023) montrent que le mouvement est en bonne voie.

#keypoint[
  *Les builds reproductibles ne sont pas une fin en soi.* Ils sont un maillon essentiel dans une chaîne de sécurité qui comprend aussi : la signature cryptographique des artefacts (Sigstore/Cosign), les SBOM, les attestations de provenance (SLSA), et la gouvernance humaine des projets open source. Sans builds reproductibles, tous ces autres mécanismes reposent sur une confiance implicite dans le processus de build qui ne peut pas être vérifiée.
]

#pagebreak()

#bibliography("refs.bib", title: "Références", style: "ieee")
