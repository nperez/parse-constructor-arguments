package Parse::Constructor::Arguments;

use 5.010;

use PPI;
use PPI::Dumper;

sub parse
{
    my ($class, $str) = @_;
    
    my $doc = PPI::Document->new(\$str);
    my %data;

    while(1)
    {
        my $token;
        eval { $token = get_next_significant($doc) };
        return undef if $@;
        
        if($token->isa('PPI::Token::Word'))
        {
            my $sub;
            eval { $sub = get_next_significant($doc) };
            return undef if $@;

            if($sub->isa('PPI::Structure::Constructor'))
            {
                say "$sub";
                last;
            }
        }
    }
}

sub get_next_significant
{
    my $doc = shift;
    
    while(1)
    {
        my $token = $doc->next_token;
        die 'No more significant tokens in stream' if not $token;
        next if !$token->significant;
        return $token;
    }
}

Parse::Constructor::Arguments->parse(q|hello_world => [ 'wtf', 'mtfnpy' ], test_two => { hello => 'two'}|);
