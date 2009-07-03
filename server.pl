#!/home/acme/perl-5.10.0/bin//perl
use strict;
use warnings;
use lib 'lib';
use HTTP::Engine;
use Kasago;
use Perl6::Say;

my $kasago = Kasago->new( root => 't/kasago' );

my $engine = HTTP::Engine->new(
    interface => {
        module => 'ServerSimple',
        args   => {
            host => 'localhost',
            port => 1978,
        },
        request_handler => 'main::handle_request',
    },
);
$engine->run;

sub handle_request {
    my $request  = shift;
    my $q = $request->parameters->{q};
    

    
    my $html = qq{
    <html>
    <head>
    <title>search</title>
    </head>
    <body>
    <form method="post" action="/">
    <input type="text" name="q" value="$q">
    <input type="submit" value="Search">
    </form>
    };
    
if ($q)    {
$html .= '<ul>';
my $hits = $kasago->search_html($q);

foreach my $hit (@$hits) {
    my $filename = $hit->{filename};
    my $score    = $hit->{score};
    my $excerpt  = $hit->{excerpt};
    #say "* $filename $score";
    #say $excerpt;
    $html .= "<li> $filename <pre>$excerpt</pre>";
}
$html .= '</ul>';
}    
    
    $html .= "</body></html>";
    return HTTP::Engine::Response->new( body => $html );
}
