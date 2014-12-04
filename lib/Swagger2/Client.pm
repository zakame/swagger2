package Swagger2::Client;

=head1 NAME

Swagger2::Client - A user agent to perform actions on a swagger API

=head1 DESCRIPTION

L<Swagger2::Client> is a user agent which can be used to send request to
an endpoint documented by the L<Swagger2> object.

=head1 SYNOPSIS

  use Swagger2;
  my $swagger = Sswagger2->new("file:///path/to/api-spec.yaml");
  my $ua = $swagger->client;

  print $ua->get("/some_resource", \%params)->body;

  Mojo::IOLoop->delay(
    sub {
      my ($delay) = @_;
      $ua->get("/some_resource", \%params, $delay->begin);
    },
    sub {
      my ($delay, $res) = @_;
    },
  );

=cut

use Mojo::Base -base;

=head1 ATTRIBUTES

=head2 swagger

  $obj = $self->swagger;

Returns a L<Swagger2> object.

=cut

has swagger => sub { die "'swagger' is required in constructor" };

=head1 METHODS

=head2 get

  $res = $self->get($resource, \%parameters);
  $self =  $self->get($resource, \%parameters, sub { my ($self, $res) = @_; ... });

=cut

sub get {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $resource, $params) = @_;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
