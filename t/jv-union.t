use Mojo::Base -strict;
use Test::More;
use Swagger2::SchemaValidator;

my $validator = Swagger2::SchemaValidator->new;

my $schema1 = {
  type                 => 'object',
  additionalProperties => 0,
  properties           => {test => {type => ['boolean', 'integer'], required => 1}}
};

my $schema2 = {
  type                 => 'object',
  additionalProperties => 0,
  properties           => {
    test => {
      type => [
        {type => "object", additionalProperties => 0, properties => {dog => {type => "string", required => 1}}},
        {
          type                 => "object",
          additionalProperties => 0,
          properties           => {sound => {type => 'string', enum => ["bark", "meow", "squeak"], required => 1}}
        }
      ],
      required => 1
    }
  }
};

my $schema3 = {
  type                 => 'object',
  additionalProperties => 0,
  properties           => {test => {type => [qw/object array string number integer boolean null/], required => 1}}
};

my $result = $validator->validate({test => "strang"}, $schema1);
ok !$result->{valid}, 'boolean or integer against string' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 1}, $schema1);
ok $result->{valid}, 'boolean or integer against integer' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => ['array']}, $schema1);
ok not($result->{valid}), 'boolean or integer against array'
  or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {object => 'yipe'}}, $schema1);
ok !$result->{valid}, 'boolean or integer against object' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 1.1}, $schema1);
ok not($result->{valid}), 'boolean or integer against number'
  or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => !!1}, $schema1);
ok $result->{valid}, 'boolean or integer against boolean' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => undef}, $schema1);
ok !$result->{valid}, 'boolean or integer against null' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {dog => "woof"}}, $schema2);
ok $result->{valid}, 'object or object against object a' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {sound => "meow"}}, $schema2);
ok $result->{valid}, 'object or object against object b nested enum pass'
  or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {sound => "oink"}}, $schema2);
ok not($result->{valid}), 'object or object against object b enum fail'
  or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {audible => "meow"}}, $schema2);
ok !$result->{valid}, 'object or object against invalid object'
  or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 2}, $schema2);
ok !$result->{valid}, 'object or object against integer' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 2.2}, $schema2);
ok !$result->{valid}, 'object or object against number' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => !1}, $schema2);
ok !$result->{valid}, 'object or object against boolean' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => undef}, $schema2);
ok !$result->{valid}, 'object or object against null' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {dog => undef}}, $schema2);
ok not($result->{valid}), 'object or object against object a bad inner type'
  or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => {dog => undef}}, $schema3);
ok $result->{valid}, 'all types against object' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => ['dog']}, $schema3);
ok $result->{valid}, 'all types against array' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 'dog'}, $schema3);
ok $result->{valid}, 'all types against string' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 1.1}, $schema3);
ok $result->{valid}, 'all types against number' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 1}, $schema3);
ok $result->{valid}, 'all types against integer' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => 1}, $schema3);
ok $result->{valid}, 'all types against boolean' or map { diag "reason: $_->{message}" } @{$result->{errors}};

$result = $validator->validate({test => undef}, $schema3);
ok $result->{valid}, 'all types against null' or map { diag "reason: $_->{message}" } @{$result->{errors}};

done_testing;
