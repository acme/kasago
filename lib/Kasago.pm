package Kasago;
use Moose;
use Moose::Util::TypeConstraints;
use File::Slurp;
use Kasago::Analyzer;
use Kasago::Highlighter;
use Kasago::ShortHighlighter;
use KinoSearch;
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::InvIndexer;
use KinoSearch::Searcher;
use KinoSearch::Search::TermQuery;
use KinoSearch::Index::Term;
use Path::Class;
use Perl6::Say;
use PPIAnalyzer;

subtype 'Directory' => as 'Str' => where { -d $_ } =>
    message {"$_ is not a directory"};

coerce 'Directory' => from 'Object' =>
    via { $_->isa('Path::Class::Dir') && $_->stringify };

has 'root' => ( is => 'ro', isa => 'Directory', required => 1, coerce => 1 );

our $VERSION = '0.30';

sub add_files {
    my ( $self, @filenames ) = @_;
    my $root = $self->root;

    my $analyzer   = Kasago::Analyzer->new();
    my $invindexer = KinoSearch::InvIndexer->new(
        invindex => $root,
        create   => 1,
        analyzer => $analyzer,
    );
    $invindexer->spec_field(
        name       => 'filename',
        analyzed   => 0,
        vectorized => 0,
        stored     => 1,
    );
    $invindexer->spec_field(
        name       => 'code',
        analyzed   => 1,
        vectorized => 1,
        stored     => 1,
    );

    foreach my $filename (@filenames) {
        my $perl      = read_file($filename);
        my $tokenizer = PPI::Tokenizer->new( \$perl );
        warn $filename;
        my $tokens = $tokenizer->all_tokens;
        next unless $tokens;
        $perl = join '', map { $_->content } @$tokens;

        my $doc = $invindexer->new_doc;
        $doc->set_value( filename => $filename );
        $doc->set_value( code     => $perl );
        $invindexer->add_doc($doc);
    }

    $invindexer->finish( optimize => 1 );
}

sub search_html {
    my ( $self, $search ) = @_;
    my $root          = $self->root;
    my $analyzer      = Kasago::Analyzer->new();
    my $code_searcher = KinoSearch::Searcher->new(
        invindex => $root,

        #analyzer => $analyzer,
    );

    my $hits = $code_searcher->search( query => $search );
    my $highlighter = Kasago::Highlighter->new( excerpt_field => 'code', );
    $hits->create_excerpts( highlighter => $highlighter );
    return $hits;
}

sub search_html_short {
    my ( $self, $search ) = @_;
    my $root          = $self->root;
    my $analyzer      = Kasago::Analyzer->new();
    my $code_searcher = KinoSearch::Searcher->new(
        invindex => $root,

        #analyzer => $analyzer,
    );

    my $hits = $code_searcher->search( query => $search );
    my $highlighter = Kasago::ShortHighlighter->new( excerpt_field => 'code', );
    $hits->create_excerpts( highlighter => $highlighter );
    return $hits;
}

1;

__END__

=head1 NAME

Kasago - A Perl source code indexer

=head1 SYNOPSIS

  my $kasago = Kasago->new({ dbh => $dbh });
  $kasago->init; # this creates the tables for you
  
  # import/update a directory
  $kasago->import($source, $dir);
  # delete a directory
  $kasago->delete($source);

  my @sources = $kasago->sources;
  my @files   = $kasago->files($source);
  my @tokens  = $kasago->tokens($source, $file);

  # search for a token
  foreach my $token ($kasago->search('orange')){
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }

  # search for a token, merging lines
  foreach my $hit ($kasago->search_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }  

  # search for tokens
  foreach my $token ($kasago->search_more($search)) {
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }

  # searh for tokens, merging lines
  foreach my $hit ($kasago->search_more_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }
  
=head1 DESCRIPTION

L<Kasago> is a module for indexing Perl source code. You can index source trees, 
and then query the index for symbols, strings, and documentation.

L<Kasago> uses the L<PPI> module to parse Perl and stores the index in a PostegreSQL
database. Thus you need to have L<DBD::Pg> installed and a database available for L<Kasago>.

Why is this called Kasago? Because that's the Japanese name for a beautiful fish.

=head1 METHODS

=head2 new

This is the constructor. It takes a L<DBI> database handle as a parameter. This must be
a valid dababase handle for a PostgreSQL database, constructed along the lines of
'my $dbh = DBI->connect("DBI:Pg:dbname=kasago", "", "")':

  my $kasago = Kasago->new({ dbh => $dbh });

=head2 delete

This deletes a source from the index:

  $kasago->delete($source);

=head2 files

Given a source, returns a list of the files indexed in that source:

  my @files   = $kasago->files($source);

=head2 import

This recursively imports a directory into Kasago.
If the source is already indexed, the index is updated.
You pass a source name and the directory path:

  $kasago->import($source, $dir);

=head2 init

This created the tables needed by Kasago in the database. You only need run this
once. If you run this after initialisation, it will delete the index.
  
  $kasago->init;

=head2 search

This searches the index for an individual token:

    foreach my $token ($kasago->search('orange')){
      print $token->source . "/"
        . $token->file . "@"
        . $token->col . ","
        . $token->row . ": "
        . $token->line . "\n";
    }

=head2 search_merged

This searches the index for an individual token, but merges multiple 
tokens on the same line together:

    foreach my $hit ($kasago->search_merged($search)) {
      print $hit->source . "/"
        . $hit->file . "@"
        . $hit->row . ": "
        . $hit->line . "\n";
      foreach my $token (@{ $hit->tokens }) {
        print "  @" . $token->col . ": " . $token->value . "\n";
      }
    }  
    
=head2 search_more

This searches the index for tokens. "orange" would return all hits for orange,
"orange leon" would return all hits for both "orange" and "leon".
"orange -leon" shows all the hits for "orange" but without files that contain "leon",
"+orange +leon" returns hits in files that contain both "orange" and "leon":

  foreach my $token ($kasago->search_more($search)) {
    print $token->source . "/"
      . $token->file . "@"
      . $token->col . ","
      . $token->row . ": "
      . $token->line . "\n";
  }
  
=head2 search_more_merged

This searches the index for tokens as search_more, but merges multiple 
tokens on the same line together:

  foreach my $hit ($kasago->search_more_merged($search)) {
    print $hit->source . "/"
      . $hit->file . "@"
      . $hit->row . ": "
      . $hit->line . "\n";
    foreach my $token (@{ $hit->tokens }) {
      print "  @" . $token->col . ": " . $token->value . "\n";
    }
  }

=head2 sources

This returns a list of the sources currently indexed:

  my @sources = $kasago->sources;
  
=head2 tokens

Given a source and a file, returns a list of the tokens indexed:

  my @tokens  = $kasago->tokens($source, $file);

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.











