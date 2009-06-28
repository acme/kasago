#!perl
use strict;
use warnings;
use lib qw(lib);
use Kasago;
use Perl6::Say;

my $search = shift || die 'no search';

my $kasago = Kasago->new( root => 't/kasago' );
my $hits = $kasago->search_html($search);

foreach my $hit (@$hits) {
    my $filename = $hit->{filename};
    my $score    = $hit->{score};
    my $excerpt  = $hit->{excerpt};
    say "* $filename $score";
    say $excerpt;
}
