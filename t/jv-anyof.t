use Mojo::Base -strict;
use Test::More;
use Swagger2::Validator;

#$SIG{__DIE__} = sub { Carp::confess($_[0]) };

my $validator = Swagger2::Validator->new;
my @errors;

my $schema = {anyOf => [{type => "string", maxLength => 5}, {type => "number", minimum => 0}],};

@errors = $validator->validate("short", $schema);
is "@errors", "", "short";

@errors = $validator->validate("too long", $schema);
is "@errors", "/: Expected string or number. Got something else.", "too long";

@errors = $validator->validate(12, $schema);
is "@errors", "", "number";

@errors = $validator->validate(-1, $schema);
is "@errors", "/: Expected string or number. Got something else.", "negative";

done_testing;
