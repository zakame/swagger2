use Mojo::Base -strict;
use Test::More;
use Swagger2::Validator;

my $validator = Swagger2::Validator->new;
my $schema = {type => 'object',
  properties => {nick => {type => 'string', minLength => 3, maxLength => 10, pattern => qr{^\w+$}}}};

my $data = {nick => 'batman'};
my @errors = $validator->validate($data, $schema);
is "@errors", "", "batman";

$data = {nick => 1000};
@errors = $validator->validate($data, $schema);
is "@errors", "Not a string: (1000)", "integer";

$data = {nick => '2000'};
@errors = $validator->validate($data, $schema);
is "@errors", "", "number as string";

$data = {nick => 'aa'};
@errors = $validator->validate($data, $schema);
is "@errors", "String is too short: 2/3", "too short";

$data = {nick => 'a' x 11};
@errors = $validator->validate($data, $schema);
is "@errors", "String is too long: 11/10", "too long";

$data = {nick => '[nick]'};
@errors = $validator->validate($data, $schema);
like "@errors", qr{String does not match}, "pattern";

done_testing;

