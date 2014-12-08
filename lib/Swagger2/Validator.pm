package Swagger2::Validator;

=head1 NAME

Swagger2::Validator - Validate JSON schemas

=head1 DESCRIPTION

L<Swagger2::Validator> is a class for valditing JSON schemas.

=head1 SYNOPSIS

  use Swagger2::Validator;
  my $validator = Swagger2::Validator->new;

  @errors = $validator->validate($data, $schema);

=cut

use Mojo::Base -base;
use Mojo::Util;
use B;

sub E {
  bless {path => $_[0], message => $_[1]}, 'Swagger2::Validator::Error';
}

sub S {
  Mojo::Util::md5_sum(Data::Dumper->new([@_])->Sortkeys(1)->Useqq(1)->Dump);
}

sub _cmp {
  return undef if !defined $_[0] or !defined $_[1];
  return "$_[3]=" if $_[2] and $_[0] >= $_[1];
  return $_[3] if $_[0] > $_[1];
  return "";
}

=head1 ATTRIBUTES

=head2 formats

TODO

=cut

has formats => sub {
};

=head1 METHODS

=head2 validate

  @errors = $self->validate($data, $schema);

Validates C<$data> against a given JSON C<$schema>. C<@errors> will
contain objects with containing the validation errors. It will be
empty on success.

Example error element:

  bless {
    message => "Some description",
    path => "/json/path/to/node",
  }, "Swagger2::Validator::Error"

=cut

sub validate {
  my ($self, $data, $schema) = @_;

  return $self->_validate($data, '', $schema);
}

sub _validate {
  my ($self, $data, $path, $schema) = @_;
  my $type = $schema->{type} || 'any';
  my (@e, @errors);

  if ($schema->{disallow}) {
    die 'TODO: No support for disallow.';
  }

  for my $t (ref $type eq 'ARRAY' ? @$type : ($type)) {
    if (ref $t eq 'HASH') {
      @e = $self->_validate_type_object($data, $path, $t);
      return unless @e;    # valid
      push @errors, @e;
    }
    elsif (my $code = $self->can(sprintf '_validate_type_%s', $t)) {
      @e = $self->$code($data, $path, $schema);
      return unless @e;    # valid
      push @errors, @e;
    }
    else {
      return E $path, "Cannot validate type '$t'";
    }
  }

  if (@errors > 1) {
    my @types = map { ref $_ ? $_->{type} || 'complex' : $_ } @$type;
    my $l = pop @types;
    return E $path, sprintf "Value (%s) did not match %s or %s.", $data // 'null', join(', ', @types), $l;
  }

  return @errors;
}

sub _validate_additional_properties {
  my ($self, $data, $path, $schema) = @_;
  my $properties = $schema->{additionalProperties};
  my @errors;

  if (!$properties and keys %$data) {
    local $" = ', ';
    push @errors, E $path, "Properties not allowed: @{[keys %$data]}.";
  }
  if (ref $properties eq 'HASH') {
    push @errors, $self->_validate_properties($data, $path, $schema);
  }

  return @errors;
}

sub _validate_enum {
  my ($self, $data, $path, $schema) = @_;
  my $enum = $schema->{enum};
  my $m    = S $data;

  for my $i (@$enum) {
    return if $m eq S $i;
  }

  local $" = ', ';
  return E $path, "Not in enum list: @$enum.";
}

sub _validate_pattern_properties {
  my ($self, $data, $path, $schema) = @_;
  my $properties = $schema->{patternProperties};
  my @errors;

  for my $pattern (keys %$properties) {
    my $v = $properties->{$pattern};
    for my $tk (keys %$data) {
      next unless $tk =~ /$pattern/;
      push @errors, $self->_validate(delete $data->{$tk}, "/$tk", $v);
    }
  }

  return @errors;
}

sub _validate_properties {
  my ($self, $data, $path, $schema) = @_;
  my $properties = $schema->{properties};
  my @errors;

  for my $name (keys %$properties) {
    my $v = $properties->{$name};
    if (exists $data->{$name}) {
      push @errors, $self->_validate_enum($data->{$name}, $path, $v) if $v->{enum};
      push @errors, $self->_validate(delete $data->{$name}, "$path/$name", $v);
    }
    elsif ($v->{default}) {
      $data->{$name} = $v->{default};
    }
    elsif ($v->{required}) {
      push @errors, E "$path/$name", "Missing property: ($name)";
    }
  }

  return @errors;
}

sub _validate_required {
  my ($self, $data, $path, $schema) = @_;
  my $properties = $schema->{required};
  my @errors;

  for my $name (@$properties) {
    next if defined $data->{$name};
    push @errors, E "$path/$name", "Missing property: ($name)";
  }

  return @errors;
}

sub _validate_type_any {
  return;
}

sub _validate_type_array {
  my ($self, $data, $path, $schema) = @_;
  my @errors;

  if (ref $data ne 'ARRAY') {
    $data //= 'null';
    return E $path, "Not an array: ($data)";
  }

  $data = [@$data];

  if (defined $schema->{minItems} and $schema->{minItems} > @$data) {
    push @errors, E $path, sprintf 'Not enough items. %s/%s', int @$data, $schema->{minItems};
  }
  if (defined $schema->{maxItems} and $schema->{maxItems} < @$data) {
    push @errors, E $path, sprintf 'Too many items. %s/%s', int @$data, $schema->{maxItems};
  }
  if ($schema->{uniqueItems}) {
    my %uniq;
    for (@$data) {
      next if !$uniq{S($_)}++;
      push @errors, E $path, 'Unique items required.';
      last;
    }
  }
  if (ref $schema->{items} eq 'ARRAY') {
    my @v = @{$schema->{items}};

    if (my $a = $schema->{additionalItems}) {
      push @v, $a while @v < @$data;
    }

    if (@v == @$data) {
      for my $i (0 .. @v - 1) {
        push @errors, $self->_validate($data->[$i], "$path/$i", $v[$i]);
      }
    }
    else {
      push @errors, E $path, sprintf "Invalid number of items. %s/%s", int(@$data), int(@v);
    }
  }
  elsif (ref $schema->{items} eq 'HASH') {
    for my $i (0 .. @$data - 1) {
      push @errors, $self->_validate($data->[$i], "$path/$i", $schema->{items});
    }
  }

  return @errors;
}

sub _validate_type_boolean {
  my ($self, $value, $path, $schema) = @_;

  return E $path, 'Not boolean: (null)' if !defined $value;
  return if "$value" eq "1" or "$value" eq "0";
  return E $path, "Not boolean: ($value)";
}

sub _validate_type_integer {
  my ($self, $value, $path, $schema) = @_;
  my @errors = $self->_validate_type_number($value, $path, $schema);

  return @errors if @errors;
  return if $value =~ /^\d+$/;
  return E $path, "Not an integer: ($value)";
}

sub _validate_type_null {
  my ($self, $value, $path, $schema) = @_;

  return E $path, 'Not null.' if defined $value;
  return;
}

sub _validate_type_number {
  my ($self, $value, $path, $schema) = @_;
  my @errors;

  unless (defined $value) {
    return E $path, "Not a number: (null)";
  }
  unless (B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK) and 0 + $value eq $value and $value * 0 == 0) {
    return E $path, "Not a number: ($value)";
  }

  if (my $e = _cmp($schema->{minimum}, $value, $schema->{exclusiveMinimum}, '<')) {
    push @errors, E $path, "$value $e minimum($schema->{minimum})";
  }
  if (my $e = _cmp($value, $schema->{maximum}, $schema->{exclusiveMaximum}, '>')) {
    push @errors, E $path, "$value $e maximum($schema->{maximum})";
  }
  if (my $d = $schema->{divisibleBy}) {
    unless (int($value / $d) == $value / $d) {
      push @errors, E $path, "$value is not divisible by $d.";
    }
  }

  return @errors;
}

sub _validate_type_object {
  my ($self, $data, $path, $schema) = @_;
  my @errors;

  if (ref $data ne 'HASH') {
    $data //= 'null';
    return E $path, "Not an object: ($data)";
  }

  # make sure _validate_xxx() does not mess up original $data
  $data = {%$data};

  if (ref $schema->{required} eq 'HASH') {
    push @errors, $self->_validate_required($data, $path, $schema);
  }
  if (defined $schema->{maxProperties} and $schema->{maxProperties} < keys %$data) {
    push @errors, E $path, sprintf 'Too many properties. %s/%s', int(keys %$data), $schema->{maxProperties};
  }
  if (defined $schema->{minProperties} and $schema->{minProperties} > keys %$data) {
    push @errors, E $path, sprintf 'Not enough properties. %s/%s', int(keys %$data), $schema->{minProperties};
  }
  if ($schema->{properties}) {
    push @errors, $self->_validate_properties($data, $path, $schema);
  }
  if ($schema->{patternProperties}) {
    push @errors, $self->_validate_pattern_properties($data, $path, $schema);
  }
  if (exists $schema->{additionalProperties}) {
    push @errors, $self->_validate_additional_properties($data, $path, $schema);
  }

  return @errors;
}

sub _validate_type_string {
  my ($self, $value, $path, $schema) = @_;
  my @errors;

  if (!defined $value or ref $value) {
    $value = defined $value ? qq($value) : q(null);
    return E $path, "Not a string: ($value)";
  }
  if (B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK) and 0 + $value eq $value and $value * 0 == 0) {
    return E $path, "Not a string: ($value)";
  }
  if (defined $schema->{maxLength}) {
    if (length($value) > $schema->{maxLength}) {
      push @errors, E $path, sprintf "String is too long: %s/%s", length($value), $schema->{maxLength};
    }
  }
  if (defined $schema->{minLength}) {
    if (length($value) < $schema->{minLength}) {
      push @errors, E $path, sprintf "String is too short: %s/%s", length($value), $schema->{minLength};
    }
  }
  if (defined $schema->{pattern}) {
    my $p = $schema->{pattern};
    unless ($value =~ /$p/) {
      push @errors, E $path, "String does not match '$p'";
    }
  }

  return @errors;
}

package    # hide from
  Swagger2::Validator::Error;

use overload q("") => sub { shift->{message} }, bool => sub {1}, fallback => 1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
