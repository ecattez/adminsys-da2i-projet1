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
use Getopt::Std;
use Time::HiRes qw(time);

my $usage = "Usage: $0 <OPTIONS> [VALUES...]\n";

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

sub create_user
{
	my ($login, $password, $uid, $gid, $name, $home, $shell) = @_;
	open PASSWD, '>>passwd' or die "open: $!";
	print PASSWD "$login:x:$uid:$gid:$name:$home:$shell\n";
	close PASSWD or die "close: $!";
	
	my $password_hash = crypt $password, "\$6\$Ay4p\$";
	open SHADOW, '>>shadow' or die "shadow: $!";
	print SHADOW "$login:$password_hash:" . time . ":0:99999:7:::\n";
	close SHADOW or die "close: $!";
}

sub remove_user
{

}

sub modify_user
{

}

create_user @ARGV;
