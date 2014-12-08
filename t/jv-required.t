use Mojo::Base -strict;
use Test::More;
use Swagger2::SchemaValidator;

my $validator = Swagger2::SchemaValidator->new;
my $schema1   = {type => 'object', properties => {mynumber => {required => 1}}};
my $schema2   = {type => 'object', properties => {mynumber => {required => 0}}};
my $schema3   = {type => 'object', properties => {mynumber => {optional => 1}}};
my $schema4   = {type => 'object', properties => {mynumber => {optional => 0}}};

my $data1 = {mynumber => 1};
my $data2 = {mynumbre => 1};

my $result = $validator->validate($data1, $schema1);
ok $result->{valid}, 'A' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data2, $schema1);
ok !$result->{valid}, 'B' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data1, $schema2);
ok $result->{valid}, 'C' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data2, $schema2);
ok $result->{valid}, 'D' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data1, $schema3);
ok $result->{valid}, 'E' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data2, $schema3);
ok $result->{valid}, 'F' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data1, $schema4);
ok $result->{valid}, 'G' or map { diag "reason: $_" } @{$result->{errors}};

$result = $validator->validate($data2, $schema4);
ok !$result->{valid}, 'H' or map { diag "reason: $_" } @{$result->{errors}};

done_testing;

