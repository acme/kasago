#!/home/acme/perl-5.10.0/bin/perl
use strict;
use warnings;
use lib qw(lib);
use File::Find::Rule;
use Kasago;
use List::Util qw(shuffle);
use Path::Class;

my $root = shift || die "No path passed";

my $kasago = Kasago->new(root => 't/kasago');

my @filenames
    = shuffle (File::Find::Rule->new()->file->name( '*.pl', '*.pm', '*.t' )->in($root));

# errr, check with PPI
# @filenames = qw(../Dackup/t/perl-5.8.0/t/base/lex.t);
# @filenames = qw(../Dackup/t/perl-5.8.1/wince/bin/search.pl);
# @filenames = qw(../Dackup/t/perl-5.8.0/ext/Encode/t/jperl.t);
# @filenames = qw(../Dackup/t/perl-5.8.1/t/op/utfhash.t)

$kasago->add_files(@filenames);
