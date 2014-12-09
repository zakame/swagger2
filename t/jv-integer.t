use Mojo::Base -strict;
use Test::More;
use Swagger2::Validator;

my $validator = Swagger2::Validator->new;
my $schema = {type => 'object', properties => {mynumber => {type => 'integer', minimum => 1, maximum => 4}}};

my $data = {mynumber => 1};
my @errors = $validator->validate($data, $schema);
is "@errors", "", "min";

$data = {mynumber => 4};
@errors = $validator->validate($data, $schema);
is "@errors", "", "max";

$data = {mynumber => 2};
@errors = $validator->validate($data, $schema);
is "@errors", "", "in the middle";

$data = {mynumber => 0};
@errors = $validator->validate($data, $schema);
is "@errors", "/mynumber: 0 < minimum(1)", 'too small';

$data = {mynumber => -1};
@errors = $validator->validate($data, $schema);
is "@errors", "/mynumber: -1 < minimum(1)", 'too small and neg';

$data = {mynumber => 5};
@errors = $validator->validate($data, $schema);
is "@errors", "/mynumber: 5 > maximum(4)", "too big";

$data = {mynumber => "2"};
@errors = $validator->validate($data, $schema);
is "@errors", "/mynumber: Not a number: (2)", "a string";

done_testing;

