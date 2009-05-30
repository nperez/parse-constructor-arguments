package Parse::Constructor::Arguments;

use 5.010;

use PPI::Dumper;

use MooseX::Declare;

class Parse::Constructor::Arguments
{
    use PPI;
    use MooseX::Types::Moose(':all');
    
    has document =>
    (
        is          => 'ro',
        isa         => 'PPI::Document',
        lazy_build  => 1,
    );

    has current =>
    (
        is          => 'ro',
        isa         => 'PPI::Node',
        lazy        => 1,
        writer      => '_set_current',
    );

    has input   =>
    (
        is          => 'ro'
        isa         => Str,
        required    => 1,
    );

    method _build_document()
    {
        my $document = PPI::Document->new(\{$self->input});
        $document->add_element(PPI::Statement::Null->new(';'));
        $sef->get_first_significant_token;
    }

    method parse(ClassName $class: Str $str)
    {
        my $self = $class->new(input => %str);
        
        my %data;
        while(1)
        {
            my $token = $self->current;

            say "token: $token";
            
            if($token->isa('PPI::Token::Word'))
            {
                say "word: $token";
                my $key = $token->content;
                
                $data{$key} = undef;

                $token = $self->get_next_significant;

                if($token->isa('PPI::Token::Operator') && $token->content =~ /,|(?:=>)/)
                {
                    say "comma: $token";

                    $token = $self->get_next_significant;
                    
                    if($token->parent->isa('PPI::Structure::Constructor'))
                    {
                        say "constructor: $token";
                        
                        $data{$key} = $self->process;
                    }
                }
            }
            elsif($token->parent->isa('PPI::Statement::Null'))
            {
                last;
            }
        }

        return \%data;
    }

    method process()
    {
        my $data;
        my $applicator;
        my $terminator;
        my $current = $self->current;
        
        if($current->content eq '[')
        {
            $data = [];
            $terminator = ']';
            $applicator = sub { push(@$_[0], $_[2]) };
        }
        elsif($current->content eq '{')
        {
            $data = {};
            $terminator = '}';
            $applicator = sub { $_[0]->{$_[1]} = $_[2] };
        }

        my $token = $self->get_next_significant;
        my $word;
        my $prev;

        while($token->content ne $terminator)
        {
            my $class = $token->class;

            if($class eq 'PPI::Token::Word')
            {
                $word = $token->content;
                $token = $self->get_next_significant;
                $class = $token->class;
            }

            if($class eq 'PPI::Token::Number')
            {
                $applicator->($data, $word, $token->content);
                $word = undef;
            }
            elsif($class eq 'PPI::Token::Structure')
            {
                $applicator->($data, $word, $self->process);
                $word = undef;
            }
            elsif($class eq 'PPI::Token::Quote')
            {
                die 'Double quoted or interpolated strings are not supported'
                    if $token->isa('PPI::Token::Quote::Double') or
                    if $token->isa('PPI::Token::Quote::Interpolated');
                
                $applicator->($data, $word, $token->content);
                $word = undef;

            }
            elsif($class eq 'PPI::Token::Operator')
            {
                if($token->content =~ /,|=>/)
                {
                    next;
                }
            }

            $applicator->($data, undef, $word) if $word;
            $word = undef;
        }

        return $array;
    }

    method get_next_significant()
    {
        while(1)
        {
            $token = $self->current->next_token;
            die "No more significant tokens in stream: '$token'" if not $token;
            
            if(!$token->significant)
            {
                next;
            }

            $self->_set_current($token);
            return $token;
        }
    }

    method get_first_signficant_token()
    {
        my $token = $self->document->first_token;
        
        if($token->significant)
        {
            $self->_set_current($token);
            return $token;
        }
        
        return $self->get_next_significant($token);
    }
}

Parse::Constructor::Arguments->parse(q|hello_world => [ 'wtf', 'mtfnpy' ], test_two => { hello => 'two'}|);
