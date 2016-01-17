#!/usr/bin/perl -w

# Ce script administre des utilisateurs sur la machine.
# Son utilisation permet :
# - d'ajouter 1 à n utilisateurs
# - de supprimer 1 à n utilisateurs
# - de modifier les données d'1 à n utilisateurs.
#   - mot de passe
#   - répertoire de travail
#   - langage de commande

# Les options de la commande :
# -n : voir ce que la commande s'apprête à faire avant de le faire effectivement
# -h : accéde à l'aide d'utilisation de la commande
# -a <user> : ajoute 1 à n utilisateurs
# -r <user> : supprime 1 à n utilisateurs
# -m <user> : modifie 1 à n utilisateurs

use strict;
use FindBin '$Bin';
use File::Copy;
use File::Path qw(make_path remove_tree);
use Getopt::Long;
use Time::HiRes qw(time);

my $root	= $Bin;
my $usage	= "Usage: $0 <OPTIONS> [VALUES...]\n";
my $upass	= 'upass';
my $passwd	= 'passwd';
my $shadow	= 'shadow';
my $group	= 'group';
my ($h, $n, @a, @r, @m);
GetOptions('h' => \$h, 'n' => \$n,'a=s@' => \@a,'r=s@' => \@r,'m=s@' => \@m) or (show_help() and exit 0);

# Crypte un mot de passe
sub crypt_password
{
	return crypt($_[0], '$6$sOmEsAlT');
}

# Affiche l'usage de la commande
sub print_usage
{
	print $usage;
}

# Affiche l'aide des options de la commande
sub print_opt
{
	printf "    %-10s: %4s\n", @_;
}

# Affiche l'aide d'utilisation de la commande
sub show_help
{
	print_usage;
	print_opt "-n", "voir ce que la commande s'apprête à faire sans le faire effectivement";
	print_opt "-h", "accéde à l'aide d'utilisation de la commande";
	print_opt "-a <user>", "ajoute 1 à n utilisateurs";
	print_opt "-r <user>", "supprime 1 à n utilisateurs";
	print_opt "-m <user>", "modifie 1 à n utilisateurs";
}

# Retourne le premier uid disponible
sub get_available_uid
{
	my $uid = 1000;
	while (getpwuid($uid))
	{
		$uid++;
	}
	return $uid;
}

# Retourne le premier gid disponible
sub get_available_gid
{
	my $gid = 1000;
	while (getgrgid($gid))
	{
		$gid++;
	}
	return $gid;
}

# Retourne le répertoire personnel par défaut
sub get_default_home
{
	my $home = $root . '/home/';
	return $home . $_[0];
}

# Retourne le shell par défaut
sub get_default_shell
{
	return '/bin/bash';
}

# Retourne un mot de passe aléatoire
sub get_random_password
{
	return crypt(srand, 'random');
}

# Insère une ligne dans un fichier
sub print_in_file
{
	my ($file, $content) = @_;
	open FILE, '>>', $file or die "open: $!";
	print FILE $content, "\n";
	close FILE or die "close: $!";
}

# Récupère la ligne d'un utilisateur dans un fichier
sub get_in_file
{
	my ($file, $login) = @_;
	
	# Si le fichier n'existe pas, alors la ligne à récupérer non plus
	return undef if not (-e $file);
	
	open FILE, '<', $file or die "open: $!";
	while (<FILE>)
	{
		return $_ if (/^$login/);
	}
	close FILE or die "close: $!";
	
	return undef;
}

# Vérifie si un utilisateur existe, renvoie 1 si oui, 0 sinon
sub exist_user
{
	my $login = $_[0];
	return defined get_in_file($passwd, $login);
}

# Crée le répertoire personnel de l'utilisateur
sub create_home
{
	my $home = $_[0];
	# Création du dossier personnel de l'utilisateur
	make_path($home, {verbose => 0, mode => 0755});
	# Mise en place des fichiers d'initialisation du shell
	system("cp -v /etc/skel/.bash* $home");
	# Définir le propriétaire
	system("chown -vR $login:$login $home");
}

# Crée un utilisateur
sub create_user
{
	my ($login, $home) = ($_[0], get_default_home($_[0]));
	
	if (exist_user($login))
	{
		print "L'utilisateur $login existe déjà.\n";
		return 0;
	}
	
	my ($password, $uid, $gid, $shell) = (get_random_password(), get_available_uid(), get_available_gid(), get_default_shell());
	
	# 1) Ecrit dans un fichier le couple login/mdp pour l'admin sys et les utilisateurs
	# 2) Ecrit dans le fichier passwd
	# 3) Ecrit dans le fichier shadow (le password est crypté)
	# 4) Ecrit dans le fichier group
	my %hash;
	$hash{$upass} = "$login:$password";
	$hash{$passwd} = "$login:x:$uid:$gid::$home:$shell";
	$hash{$shadow} = $login . ':' . crypt_password($password) . ':' . time . ':0:99999:7:::';
	$hash{$group} = "$login:x:$gid:";
	
	while (my ($key, $value) = each %hash)
	{
		print_in_file($key, $value);
	}
	
	create_home($home);
}

# Supprime un utilisateur dans un fichier
sub remove_user_from_file
{
	my ($file, $login) = @_;
	my @list;
	my $save;
	
	# Supprimer le user dans le fichier spécifié
	open FILE, '<', $file or die "open: $!";
	while (<FILE>)
	{
		if (/^$login/)
		{
			$save = $_;
		}
		else
		{		
			push(@list, $_);
		}
	}
	close FILE or die "close: $!";
	
	# On réécrit le fichier sans la ligne sauvegardée
	open FILE, '>', $file or die "open: $!";
	print FILE @list;
	close FILE or die "close: $!";
	
	return $save;
}

# Supprime un utilisateur
sub remove_user
{
	my $login = $_[0];
	my $user = remove_user_from_file($passwd, $login);
	
	# Si l'utilisateur est vide, c'est qu'il n'existe pas
	if ($user)
	{
		my @info = split(':', $user);
		my $home = $info[5];
	
		my @files = ($shadow, $group);
		foreach (@files)
		{
			remove_user_from_file($_, $login);
		}
	
		# Suppression du répertoire personnel de l'utilisateur
		remove_tree($home);
	}
	else
	{
		print "Impossible de supprimer $login. Cet utilisateur n'existe pas ou a été supprimé.\n";
	}
}

# Saisie et retourne une donnée avec confirmation de saisie
sub set_and_confirm
{
	my @prompt = @_;
	my @answer;
	do
	{
		print $prompt[0], ': ';
		$answer[0] = <STDIN>;
		chomp $answer[0];
		print $prompt[1], ': ';
		$answer[1] = <STDIN>;
		chomp $answer[1];
		print 'Erreur: les informations saisies sont différentes', "\n" if ($answer[0] ne $answer[1])
	} while ($answer[0] ne $answer[1]);
	return $answer[0];
}

# Modifie un utilisateur <password, home, shell>
sub modify_user
{
	my $login = $_[0];
	my $userInfo = get_in_file($passwd, $login);
	if ($userInfo)
	{
		my @info = split(':', $userInfo);
		if (yes_no('Modifier le mot de passe ?'))
		{
			# On cache l'affichage du prompt
			system('stty','-echo');
			my @infoShadow = split(':', get_in_file($shadow, $login));
			my $pass;
			do
			{
				print 'Saisir mot de passe actuel: ';
				$pass = <STDIN>;
				chomp $pass;
				$pass = crypt_password($pass);
				print 'Mot de passe incorrect', "\n" if ($pass ne $infoShadow[1]);
			} while ($pass ne $infoShadow[1]);
			
			$pass = set_and_confirm('Nouveau mot de passe', 'Confirmer nouveau mot de passe');
			# On affiche de nouveau le prompt
			system('stty','echo');
			
			$infoShadow[1] = crypt_password($pass);
			remove_user_from_file($shadow, $login);
			$" = ':';
			print_in_file($shadow, "@infoShadow");
			$" = '';
			
		}
		if (yes_no('Modifier le répertoire personnel ?'))
		{
			print "Répertoire actuel: $info[5]\n";
			my $home = set_and_confirm('Nouveau répertoire', 'Confirmer nouveau répertoire');
			make_path($home, {verbose => 0, mode => 0755});
			move($info[5], $home);
			system("chown -vR $login:$login $home");
			$info[5] = $home;
		}
		if (yes_no('Modifier le langage de commande ?'))
		{
			print "Langage de commande actuel: $info[6]";
			$info[6] = set_and_confirm('Nouveau langage de commande', 'Confirmer nouveau langage de commande');
		}
		remove_user_from_file($passwd, $login);
		$" = ':';
		print_in_file($passwd, "@info");
		$" = '';
	}
}

# Question oui/non
sub yes_no
{
	my $answer;
	my $question = $_[0];
	do {
		print $question, ' (y/n) ';
		$answer = lc <STDIN>;
		chomp $answer;
	} while not ($answer eq 'y' or $answer eq 'n');
	return $answer eq 'y';
}

# Indique ce que la commande s'apprête à faire (option -n) avant de l'exécuter
sub dry_run
{
	my $message = $_[0];
	print $message, "\n";
	
	# On s'arrête immédiatement si l'utilisateur répond non pour continuer la commande
	exit 0 if not yes_no('Voulez-vous continuer ?');
}

$SIG{INT} = sub { system('stty','echo'); exit(0); };

if ($h)
{
	show_help();
}
elsif (@a)
{
	dry_run("Vous vous apprêtez à ajouter 1 ou plusieurs utilisateurs") if ($n);
	foreach (@a)
	{	
		create_user $_;
	}
	print "Les mots de passes temporaires des utilisateurs sont disponibles dans le fichier upass\n";
}
elsif (@r)
{
	dry_run("Vous vous apprêtez à supprimer 1 ou plusieurs utilisateurs") if ($n);
	foreach (@r)
	{
		remove_user $_;
	}
}
elsif (@m)
{
	dry_run("Vous vous apprêtez à modifier 1 ou plusieurs utilisateurs") if ($n);
	foreach (@m)
	{
		modify_user $_;
	}
}
# On envoit le contenu d'un fichier sur la ligne de commande
else
{
	dry_run("Vous vous apprêtez à ajouter 1 ou plusieurs utilisateurs") if ($n);
	while(<STDIN>)
	{
		chomp;
		create_user $_;
	}
	print "Les mots de passes temporaires des utilisateurs sont disponibles dans le fichier upass\n";
}
