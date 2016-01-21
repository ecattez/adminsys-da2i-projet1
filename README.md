# adminsys-da2i-projet1
## Projet d'Administration Système (Licence DA2I)
### Edouard CATTEZ

---------------------

**Etat**: done

[**Sujet de TP**](http://cristal.univ-lille.fr/~lhoussai/e/da2i/sujet1.txt)

[**Mécanisme de création d'un utilisateur UNIX**](http://www.linux-perl-c.lami20j.fr/contenu/affiche-linux_tuto-4-creation-manuelle-d-un-utilisateur-:-le-mecanisme.html)

---------------------

## Synopsys

Script PERL qui administre des utilisateurs sur la machine courante.

Son utilisation permet :
- d'ajouter 1 à n utilisateurs
- de supprimer 1 à n utilisateurs
- de modifier les données d'1 à n utilisateurs.
  - mot de passe
  - répertoire de travail
  - langage de commande

**Fichiers concernés**

- /etc/passwd
- /etc/shadow
- /etc/group
- /etc/upass

## Utilisation

Afin d'être simple et efficace, l'ajout, la suppression et la modification ont été regroupés au sein d'une et une seule commande :

```
./user.pl <OPTIONS> [VALUES]
```

### Description des options

| Option | Argument | Description |
|:------:|:--------:|:--------------------------|
| h | - | Affiche l'aide de la commande |
| n | - | Indique ce que s'apprête à faire la commande |
| f | - | Force la suppression |
| a | user | Ajoute l'utilisateur `<user>` |
| r | user | Supprime l'utilisateur `<user>` |
| m | user | Modifie l'utilisateur `<user>` |

Les options qui n'existent pas ou qui ne sont pas écrites correctement entraînent automatiquement l'affichage de l'aide (équivalent à l'option -h).

### Exemples d'utilisation

**Créer les utilisateurs catteze, ferrot, fevrer, leleuj**

```
./user.pl -a catteze -a ferrot -a fevrer -a leleuj
```

**Modifier les utilisateurs catteze et leleuj**

```
./user.pl -m catteze -m leleuj
```

**Supprimer les utilisateurs ferrot et fevrer**

```
./user.pl -r ferrot -r fevrer
```

**Supprimer l'utilisateur catteze sans confirmation**

```
./user.pl -f -r catteze
```

## Documentation technique

### A propos de l'ajout

Lors de l'ajout d'un utilisateur, un mot de passe est généré aléatoirement et est stocké dans le fichier `/etc/upass` sous la forme `<user>:<password>`.

**Exemple**

```
toto:raWjCloSusMso
titi:rahBCoI58SVRU
```

Ce fichier est à destination de l'administrateur système qui fournira le mot de passe temporaire à chaque utilisateur qu'il devra changer à sa première connexion.

La génération du mot de passe se fait par l'appel à la fonction perl `crypt(srand, 'random')`.

Toutefois, ce mot de passe est de nouveau crypté avec la même fonction en SHA512 `crypt(password, '$6$sOmEsAlT')` et est stocké dans le fichier `/etc/shadow`.

D'autre part, le répertoire personnel par défaut d'un utilisateur est `/home/<username>` et son langage de commande est `/bin/bash`.

Enfin, un message informatif s'affiche lors de l'ajout d'un utilisateur qui existe déjà et la création ne s'effectue pas.

**Créer des utilisateurs avec un fichier**

Une autre manière de créer des utilisateurs est de prévoir un fichier de login comme-ci après :

```
catteze
ferrot
fevrer
leleuj
vastraa
```

Une fois que le fichier est prêt à être utilisé, il suffit d'exécuter la commande suivante :

```
./user.pl < logins.txt
```

### A propos de la suppression

La suppression se fait avec confirmation par utilisateur sauf si l'option -f est spécifiée. De plus, la suppression d'un utilisateur entraîne la suppression récursive de son répertoire personnel via [File::Path](http://perldoc.perl.org/File/Path.html).

Notons qu'un message d'erreur s'affiche dans le cas de la suppression d'un utilisateur qui n'existe pas/plus.

### A propos de la modification

La modification d'un utilisateur est intéractive, c'est à dire que la commande pose 3 questions à l'utilisateur afin de savoir s'il veut :
- modifier son mot de passe
- modifier la destination de son répertoire personnel
- modifier son langage de commande

La modification du répertoire personnel est récursive dans le cas où la destination n'existerait pas et/où que les dossiers parents au répertoire personnel n'existent pas.

Notons qu'un message d'erreur s'affiche dans le cas de la modification d'un utilisateur qui n'existe pas/plus.
