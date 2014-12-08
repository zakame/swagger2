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
use B;

=head1 METHODS

=head2 validate

  @errors = $self->validate($data, $schema);

=cut

sub validate {
  my ($self, $data, $schema) = @_;

  return $self->_validate($data, '', $schema);
}

sub _validate {
  my ($self, $data, $path, $schema) = @_;
  my $validator = sprintf '_validate_type_%s', $schema->{type} || 'object';

  return $self->$validator($data, $path, $schema);
}

sub _validate_additional_properties {
  my ($self, $data, $path, $schema) = @_;
  my $properties = $schema->{additionalProperties};
  my @errors;

  if (!$properties and keys %$data) {
    local $" = ', ';
    push @errors, {path => $path, message => "These additional properties are not allowed: @{[keys %$data]}"};
  }
  if (ref $properties eq 'HASH') {
    push @errors, $self->_validate_properties($data, $path, $schema);
  }

  return @errors;
}

sub _validate_pattern_properties {
  my ($self, $data, $path, $schema) = @_;
  my $properties = $schema->{patternProperties};
  my @errors;

  for my $pattern (keys %$properties) {
    my $v = $properties->{$pattern};
    my $validator = sprintf '_validate_type_%s', $v->{type} || 'object';

    for my $tk (keys %$data) {
      next unless $tk =~ /$pattern/;
      push @errors, $self->$validator(delete $data->{$tk}, "/$tk", $v);
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
    my $validator = sprintf '_validate_type_%s', $v->{type} || 'object';

    if (exists $data->{$name}) {
      push @errors, $self->$validator(delete $data->{$name}, "$path/$name", $v);
    }
    elsif ($v->{required}) {
      push @errors, {path => "$path/$name", message => "'$name' is required in object."};
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
    push @errors, {path => "$path/$name", message => "'$name' is required in object."};
  }

  return @errors;
}

sub _validate_type_array {
  my ($self, $data, $path, $schema) = @_;
  my @errors;

  if (ref $data ne 'ARRAY') {
    return {path => $path, message => "$data is not an array"};
  }

  $data = [@$data];

  if (defined $schema->{minItems} and $schema->{minItems} > @$data) {
    push @errors, {path => $path, message => sprintf 'Not enough items. %s/%s', int @$data, $schema->{minItems}};
  }

  if (defined $schema->{maxItems} and $schema->{maxItems} < @$data) {
    push @errors, {path => $path, message => sprintf 'Too many items. %s/%s', int @$data, $schema->{maxItems}};
  }

  if ($schema->{uniqueItems}) {
    push @errors, {path => $path, message => 'TODO: "uniqueItems"'};
  }

  if (ref $schema->{items} eq 'ARRAY') {
    my @v = @{$schema->{items}};

    if (my $a = $schema->{additionalItems}) {
      push @v, $a while @v < @$data;
    }

    if (@v == @$data) {
      for my $i (0 .. @v - 1) {
        my $validator = sprintf '_validate_type_%s', $schema->{items}{type} || 'object';
        push @errors, $self->$validator($data->[$i], "$path/$i", $v[$i]);
      }
    }
    else {
      push @errors, {path => $path, message => sprintf "Invalid number of items. %s/%s", int(@$data), int(@v)};
    }
  }
  elsif (ref $schema->{items} eq 'HASH') {
    my $validator = sprintf '_validate_type_%s', $schema->{items}{type} || 'object';
    for my $i (0 .. @$data - 1) {
      push @errors, $self->$validator($data->[$i], "$path/$i", $schema->{items});
    }
  }
}

sub _validate_type_numeric {
  my ($self, $value, $path, $schema) = @_;
  my @errors;

  # Number logic (from Mojo::JSON)
  unless (B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK) and 0 + $value eq $value and $value * 0 == 0) {
    return {path => $path, message => "'$value' is not a number."};
  }

  if (defined $schema->{minimum}) {
    if ($schema->{exclusiveMinimum}) {
      unless ($value >= $schema->{minimum}) {
        push @errors, {path => $path, message => "$value < $schema->{minimum}"};
      }
    }
    else {
      if ($value < $schema->{minimum}) {
        push @errors, {path => $path, message => "$value <= $schema->{minimum}"};
      }
    }
  }

  if (defined $schema->{maximum}) {
    if ($schema->{exclusiveMaximum}) {
      if ($value > $schema->{maximum}) {
        push @errors, {path => $path, message => "$value > $schema->{maximum}"};
      }
    }
    else {
      unless ($value <= $schema->{maximum}) {
        push @errors, {path => $path, message => "$value >= $schema->{maximum}"};
      }
    }
  }

  if (my $d = $schema->{divisibleBy}) {
    unless (int($value / $d) == $value / $d) {
      push @errors, {path => $path, message => "'$value is not divisible by $d."};
    }
  }

  return @errors;
}

sub _validate_type_object {
  my ($self, $data, $path, $schema) = @_;
  my @errors;

  # make sure _validate_xxx() does not mess up original $data
  $data = {%$data};

  if (defined $schema->{maxProperties} and $schema->{maxProperties} < keys %$data) {
    push @errors,
      {path => $path, message => sprintf 'Too many properties. %s/%s', int(keys %$data), $schema->{maxProperties}};
    push @errors, {path => $path, message => 'Too many properties'};
  }
  if (defined $schema->{minProperties} and $schema->{minProperties} > keys %$data) {
    push @errors,
      {path => $path, message => sprintf 'Not enough properties. %s/%s', int(keys %$data), $schema->{minProperties}};
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
  if ($schema->{required}) {
    push @errors, $self->_validate_required($data, $path, $schema);
  }

  return @errors;
}

sub _validate_type_string {
  my ($self, $value, $path, $schema) = @_;
  my @errors;

  if (!defined $value or ref $value) {
    $value = defined $value ? qq('$value') : q(null);
    return {path => $path, message => "$value is not a string."};
  }

  if (defined $schema->{maxLength}) {
    if ($schema->{maxLength} < length $value) {
      push @errors,
        {path => $path, message => sprintf "String is too long. %s/%s", length($value), $schema->{maxLength}};
    }
  }

  if (defined $schema->{minLength}) {
    if ($schema->{minLength} < length $value) {
      push @errors,
        {path => $path, message => sprintf "String is too long. %s/%s", length($value), $schema->{minLength}};
    }
  }
  if (defined $schema->{pattern}) {
    my $p = $schema->{pattern};
    unless ($value =~ /$p/) {
      push @errors, {path => $path, message => "String does not match '$p'"};
    }
  }


  return @errors;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
