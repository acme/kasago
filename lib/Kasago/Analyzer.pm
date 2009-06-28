package Kasago::Analyzer;
use strict;
use warnings;
use Perl6::Say;
use PPI;
use PPI::Tokenizer;
use base qw( KinoSearch::Analysis::Analyzer );

sub transform {
    my ( $self, $inversion ) = @_;
    my $new_inversion = KinoSearch::Analysis::Inversion->new();

    #    $inversion->next;
    my $perl = $inversion->next->get_text;

    my $pos_inc      = 0;
    my $start_offset = 0;
    my $tokenizer    = PPI::Tokenizer->new( \$perl );
    my $tokens       = $tokenizer->all_tokens;

    foreach my $token (@$tokens) {
        my $class          = ref($token);
        my $content        = $token->content;
        my $content_length = length($content);
        my $stop_offset    = $start_offset + $content_length;

        # say "$class ($start_offset, $content_length)";
        my $text;

        if (   $class eq 'PPI::Token::Whitespace'
            || $class eq 'PPI::Token::Structure'
            || $class eq 'PPI::Token::Number'
            || $class eq 'PPI::Token::Number::Float'
            || $class eq 'PPI::Token::Number::Hex'
            || $class eq 'PPI::Token::Number::Octal'
            || $class eq 'PPI::Token::Number::Exp'
            || $class eq 'PPI::Token::Number::Binary'
            || $class eq 'PPI::Token::Number::Version'
            || $class eq 'PPI::Token::Prototype'
            || $class eq 'PPI::Token::Operator'
            || $class eq 'PPI::Token::Separator'
            || $class eq 'PPI::Token::Regexp::Match'
            || $class eq 'PPI::Token::Regexp::Substitute'
            || $class eq 'PPI::Token::Regexp::Transliterate'
            || $class eq 'PPI::Token::HereDoc'
            || $class eq 'PPI::Token::Data'
            || $class eq 'PPI::Token::QuoteLike::Regexp'
            || $class eq 'PPI::Token::Label'
            || $class eq 'PPI::Token::ArrayIndex'
            || $class eq 'PPI::Token::Cast'
            || $class eq 'PPI::Token::Magic'
            || $class eq 'PPI::Token::Attribute'
            || $class eq 'PPI::Token::End' )
        {

            # ignore
        } elsif (
            $class eq 'PPI::Token::Word'
            || $class eq 'PPI::Token::Symbol'

            )
        {

            # keep
            $text = $token->content;

            #tesay $token->content;
        } elsif ( $class eq 'PPI::Token::Comment'
            || $class eq 'PPI::Token::Quote::Single'
            || $class eq 'PPI::Token::Quote::Double'
            || $class eq 'PPI::Token::Quote::Interpolate'
            || $class eq 'PPI::Token::Quote::Literal'
            || $class eq 'PPI::Token::QuoteLike::Command'
            || $class eq 'PPI::Token::QuoteLike::Words'
            || $class eq 'PPI::Token::QuoteLike::Backtick'
            || $class eq 'PPI::Token::QuoteLike::Readline'
            || $class eq 'PPI::Token::Pod' )
        {

            # analyze
        } else {
            $content = substr( $content, 0, 40 );
            die "missing $class: [$content]";
        }

        if ($text) {

            # say "$text";
            my $substr = substr( $perl, $start_offset,
                $stop_offset - $start_offset );

            die "  $substr != $text" if $substr ne $text;

            my $token = KinoSearch::Analysis::Token->new(
                text         => $text,
                start_offset => $start_offset,
                end_offset   => $stop_offset,
                pos_inc      => $pos_inc++,
            );
            # warn "$text / $start_offset / $stop_offset / $pos_inc";
            $new_inversion->append($token);

        }
        $start_offset += $content_length;
    }

    $inversion->reset;

    $new_inversion->reset;
    return $new_inversion;
}

1;
