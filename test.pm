#!/usr/bin/perl

$pwd = (getpwuid($<))[1];

system "stty -echo";
print "Password: ";
chomp($word = <STDIN>);
print "\n";
system "stty echo";

print "pwd: ", $pwd, "\n";
print "crypt: ", crypt($word, $pwd);

if (crypt($word, $pwd) ne $pwd) {
   die "Sorry wrong password\n";
} else {
   print "ok, correct password\n";
}
