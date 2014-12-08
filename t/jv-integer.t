use Mojo::Base -strict;
use Test::More;
use Swagger2::SchemaValidator;

my $validator = Swagger2::SchemaValidator->new;
my $schema = {type => 'object', properties => {mynumber => {type => 'integer', minimum => 1, maximum => 4}}};

my $data = {mynumber => 1};
my $result = $validator->validate($data, $schema);
ok $result->{valid}, 'min' or map { diag "reason: $_" } $result->{errors};

$data = {mynumber => 4};
$result = $validator->validate($data, $schema);
ok $result->{valid}, 'max' or map { diag "reason: $_" } $result->{errors};

$data = {mynumber => 2};
$result = $validator->validate($data, $schema);
ok $result->{valid}, 'in the middle' or map { diag "reason: $_" } $result->{errors};

$data = {mynumber => 0};
$result = $validator->validate($data, $schema);
ok !$result->{valid}, 'too small' or map { diag "reason: $_" } $result->{errors};

$data = {mynumber => -1};
$result = $validator->validate($data, $schema);
ok !$result->{valid}, 'too small and neg' or map { diag "reason: $_" } $result->{errors};

$data = {mynumber => 5};
$result = $validator->validate($data, $schema);
ok !$result->{valid}, 'too big' or map { diag "reason: $_" } $result->{errors};

done_testing;

