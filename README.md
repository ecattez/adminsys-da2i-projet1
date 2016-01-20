# adminsys-da2i-projet1
## Projet d'Administration Système (Licence DA2I)
### Edouard CATTEZ

---------------------

**Etat**: en développement

[**Sujet de TP**](http://cristal.univ-lille.fr/~lhoussai/e/da2i/sujet1.txt)

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

[TODO] Option -f

**A propos de l'ajout**

Lors de l'ajout d'un utilisateur, un mot de passe est généré aléatoirement et est stocké dans le fichier `/etc/upass` sous la forme `<user>:<password>`. Ce fichier est à destination de l'administrateur système qui fournira le mot de passe temporaire à chaque utilisateur qu'il devra changer à sa première connexion.

La génération du mot de passe se fait par l'appel à la fonction perl `crypt(srand, 'random')`.

Toutefois, ce mot de passe est de nouveau crypté avec la même fonction en SHA512 `crypt(password, '$6$sOmEsAlT')` et est stocké dans le fichier `/etc/shadow`.

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

**A propos de la suppression**

[TODO] La suppression se fait avec confirmation par utilisateur sauf si l'option -f est spécifiée.

La suppression d'un utilisateur entraîne la suppression récursive de son répertoire personnel.

**A propos de la modification**

La modification d'un utilisateur est intéractive, c'est à dire que la commande pose 3 questions à l'utilisateur afin de savoir s'il veut :
- modifier son mot de passe
- modifier la destination de son répertoire personnel
- modifier son langage de commande

La modification du répertoire personnel est récursive dans le cas où la destination n'existerait pas et/où que les dossiers parents au répertoire personnel n'existent pas.

#### Exemples d'utilisation

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
