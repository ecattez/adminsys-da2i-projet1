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
# -n (ou --dry-run) : voir ce que la commande s'apprête à faire sans le faire effectivement
# -h (ou --help)	: accéde à l'aide d'utilisation de la commande
# -a (ou --add)		[value] : ajoute 1 à n utilisateurs
# -r (ou --remove)	[value] : supprime 1 à n utilisateurs
# -m (ou --modify)	[value] : modifie 1 à n utilisateurs

use strict;
use Getopt::Long;
use Time::HiRes qw(time);
use FindBin '$Bin';
use Digest::SHA qw(sha512);

my $root	= $Bin;
my $usage	= "Usage: $0 <OPTIONS> [VALUES...]\n";
my $upass	= 'upass';
my $passwd	= 'passwd';
my $shadow	= 'shadow';
my $group	= 'group';
my ($h, $n, @a, @r, @m);
GetOptions('h' => \$h, 'n' => \$n,'a=s@' => \@a,'r=s@' => \@r,'m=s@{4}' => \@m);

sub crypt_password
{
	return unpack("H*", sha512($_[0]));
}

sub print_usage
{
	print $usage;
}

sub print_opt
{
	printf "    %-24s : %4s\n", @_;
}

sub show_help
{
	print_usage;
	print_opt "-n (ou --dry-run)", "voir ce que la commande s'apprête à faire sans le faire effectivement";
	print_opt "-h (ou --help)", "accéde à l'aide d'utilisation de la commande";
	print_opt "-a (ou --add) <value>", "ajoute 1 à n utilisateurs";
	print_opt "-r (ou --remove) <value>", "supprime 1 à n utilisateurs";
	print_opt "-m (ou --modify) <value>", "modifie 1 à n utilisateurs";
}

sub get_available_uid
{
	my $uid = 1000;
	while (getpwuid($uid))
	{
		$uid++;
	}
	return $uid;
}

sub get_available_gid
{
	my $gid = 1000;
	while (getgrgid($gid))
	{
		$gid++;
	}
	return $gid;
}

sub get_default_home
{
	my $home = $root . '/home/';
	mkdir $home unless -d $home;
	return $home . $_[0];
}

sub get_default_shell
{
	return '/bin/bash';
}

sub get_random_password
{
	return crypt(srand, 'random');
}

sub print_in_file
{
	my ($file, $content) = @_;
	open FILE, '>>', $file or die "open: $!";
	print FILE $content, "\n";
	close FILE or die "close: $!";
}

# <login>
sub create_user
{
	my ($login, $home) = ($_[0], get_default_home($_[0]));
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
	
	# Création du dossier personnel de l'utilisateur
	mkdir $home or die "mkdir: $!";
	# Mise en place des fichiers d'initialisation du shell
	#system("cp -v /etc/skel/.bash* $home");
	# Attribution des droits
	#system("chmod -v 0755 $home");
	# Définir le propriétaire
	#system("chown -vR $login:$login $home");
}

sub remove_user_from_file
{
	my ($file, $login) = @_;
	my @list;
	
	# Supprimer dans le fichier passwd
	open FILE, '<', $file or die "open: $!";
	while (<FILE>)
	{
		push(@list, $_) unless (/^$login/);
	}
	close FILE or die "close: $!";
	
	open FILE, '>', $file or die "open: $!";
	print FILE @list;
	close FILE or die "close: $!";
}

# <login>
sub remove_user
{
	my $login = $_[0];
	my @files = ($passwd, $shadow, $group);
	foreach (@files)
	{
		remove_user_from_file($_, $login);
	}
}

# <login, password, home, shell>
sub modify_user
{

}

# Test de commande sans effet
sub dry_run
{

}

if ($h)
{
	show_help();
}
elsif ($n)
{

}
elsif (@a)
{
	foreach (@a)
	{	
		create_user $_;
	}
}
elsif (@r)
{
	foreach (@r)
	{
		remove_user $_;
	}
}
elsif (@m)
{
	foreach (@m)
	{
		modify_user $_;
	}
}
else
{
	while(<STDIN>)
	{
		chomp;
		create_user $_;
	}
}
