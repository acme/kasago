#!perl
use strict;
use warnings;
use lib qw(lib);
use Cwd;
use Path::Class;
use Kasago;
use Test::More tests => 15;

dir('t/kasago')->rmtree;
dir('t/kasago')->mkpath;
my $kasago = Kasago->new( root => 't/kasago' );
$kasago->add_files('t/small/hello.pl');

my ( $hits, $hit, $filename, $excerpt );

my @hits = @{ $kasago->search_html('use') };
is( @hits, 1 );
$hit      = $hits[0];
$filename = $hit->{filename};

#die $filename;
$excerpt = $hit->{excerpt};

#die $excerpt;
is( $filename, 't/small/hello.pl' );
is( $excerpt, '#!perl
<strong>use</strong> strict;
<strong>use</strong> warnings;

my $sexy = 1;

$sexy = $sexy * 2;

print &quot;Hello world!\n&quot;;'
);

@hits = @{ $kasago->search_html('strict') };
is( @hits, 1 );
$hit      = $hits[0];
$filename = $hit->{filename};
$excerpt  = $hit->{excerpt};
is( $filename, 't/small/hello.pl' );
is( $excerpt, '#!perl
use <strong>strict</strong>;
use warnings;

my $sexy = 1;

$sexy = $sexy * 2;

print &quot;Hello world!\n&quot;;'
);

@hits = @{ $kasago->search_html('warnings') };
is( @hits, 1 );
$hit      = $hits[0];
$filename = $hit->{filename};
$excerpt  = $hit->{excerpt};
is( $filename, 't/small/hello.pl' );
is( $excerpt, '#!perl
use strict;
use <strong>warnings</strong>;

my $sexy = 1;

$sexy = $sexy * 2;

print &quot;Hello world!\n&quot;;'
);

@hits = @{ $kasago->search_html('$sexy') };
is( @hits, 1 );
$hit      = $hits[0];
$filename = $hit->{filename};
$excerpt  = $hit->{excerpt};
is( $filename, 't/small/hello.pl' );
is( $excerpt, '#!perl
use strict;
use warnings;

my <strong>$sexy</strong> = 1;

<strong>$sexy</strong> = <strong>$sexy</strong> * 2;

print &quot;Hello world!\n&quot;;'
);

@hits = @{ $kasago->search_html('print') };
is( @hits, 1 );
$hit      = $hits[0];
$filename = $hit->{filename};
$excerpt  = $hit->{excerpt};
is( $filename, 't/small/hello.pl' );
is( $excerpt, '#!perl
use strict;
use warnings;

my $sexy = 1;

$sexy = $sexy * 2;

<strong>print</strong> &quot;Hello world!\n&quot;;'
);

__END__

my $source = "Acme-Colour";
my $dir = dir(cwd, "t", "Acme-Colour-1.00");
$kasago->import($source, $dir);
is_deeply([ $kasago->sources ], [$source]);
is_deeply(
  [ $kasago->files($source) ],
  [
    'Build.PL',    'CHANGES', 'MANIFEST',           'META.yml',
    'Makefile.PL', 'README',  'lib/Acme/Colour.pm', 'test.pl'
  ]
);
is(scalar($kasago->tokens($source, 'Build.PL')),           48);
is(scalar($kasago->tokens($source, 'CHANGES')),            100);
is(scalar($kasago->tokens($source, 'MANIFEST')),           19);
is(scalar($kasago->tokens($source, 'META.yml')),           25);
is(scalar($kasago->tokens($source, 'Makefile.PL')),        42);
is(scalar($kasago->tokens($source, 'README')),             392);
is(scalar($kasago->tokens($source, 'lib/Acme/Colour.pm')), 890);
is(scalar($kasago->tokens($source, 'test.pl')),            867);

my @tokens = $kasago->search('orange');
is(scalar(@tokens),    4);
is($tokens[0]->source, 'Acme-Colour');
is($tokens[0]->row,    113);
is($tokens[0]->col,    25);
is($tokens[0]->value,  'orange');
is($tokens[0]->file,   'test.pl');
is($tokens[0]->line,   '$c = Acme::Colour->new("orange");');
is($tokens[3]->source, 'Acme-Colour');
is($tokens[3]->row,    117);
is($tokens[3]->col,    23);
is($tokens[3]->value,  'orange');
is($tokens[3]->file,   'test.pl');
is($tokens[3]->line,   'is("$c", "dark red", "orange and brown is dark red");');

my @hits = $kasago->search_merged('orange');
is(scalar(@hits),                 3);
is($hits[0]->row,                 113);
is(scalar(@{ $hits[0]->tokens }), 1);
is($hits[1]->row,                 115);
is(scalar(@{ $hits[1]->tokens }), 2);
is($hits[2]->row,                 117);
is(scalar(@{ $hits[2]->tokens }), 1);

@tokens = $kasago->search_more('orange brown');

@tokens = $kasago->search('regenerated');
is(scalar(@tokens),    0);

$kasago->delete('Acme-Colour');
is_deeply([ $kasago->sources ], []);
@tokens = $kasago->search('orange');
is(scalar(@tokens), 0);

$dir = dir(cwd, "t", "Acme-Colour-1.01");
$kasago->import($source, $dir);
is_deeply([ $kasago->sources ], ['Acme-Colour']);
@tokens = $kasago->search('regenerated');
is(scalar(@tokens), 1);
