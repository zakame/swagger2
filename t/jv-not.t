use Mojo::Base -strict;
use Test::More;
use Swagger2::Validator;

my $validator = Swagger2::Validator->new;
my $schema = {not => {type => "string"}};
my @errors;

@errors = $validator->validate(12, $schema);
is "@errors", "", "not string";
@errors = $validator->validate("str", $schema);
is "@errors", "/: Should not match.", "is string";

done_testing;
