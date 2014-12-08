use Mojo::Base -strict;
use Test::More;
use Swagger2::SchemaValidator;

my $validator = Swagger2::SchemaValidator->new;

my $schema = {
  type => 'object',
  properties =>
    {username => {minLength => 1, maxLength => 64, required => 1}, password => {minLength => 6, required => 1},},
};

ok $validator->validate({username => 'abc', password => 'abcdef'},   $schema)->{valid};
ok $validator->validate({username => 'abc', password => 'abcdefgh'}, $schema)->{valid};
ok not $validator->validate({username => 'abc', password => 'abcde'}, $schema)->{valid};
ok not $validator->validate({username => 'abc'},      $schema)->{valid};
ok not $validator->validate({password => 'abcdefgh'}, $schema)->{valid};
ok not $validator->validate({username => '',         password => 'abcdefgh'}, $schema)->{valid};
ok not $validator->validate({username => ('a' x 65), password => 'abcdefgh'}, $schema)->{valid};

done_testing;
