package Net::Hlld::Exception::Network;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends 'Net::Hlld::Exception';

1;
=pod

=head1 NAME

Net::Hlld::Exception::Action -- Class for Net::Hlld exceptions related to user actions

=head1 SYNOPSIS

  eval { $client->info('foo') };
  if (my $exception = $@) {
      if (blessed $exception
          and $exception->isa('Net::Hlld::Exception::Network')) {
          if ($exception->message =~ m/Bad hostname '.*') {
              # complain to user about bad connection info
          }
          $exception->rethrow;
      } else {
          # ...
      }
  }

=head1 DESCRIPTION

This is a L<Throwable::Error>-derived exception class for L<Net::Hlld>
exceptions.  It is a subclass of L<Net::Hlld::Exception>.

Instances of this class are intended to be created and thrown when a
network error occurs, e.g. the socket cannot be opened successfully.

=head1 ATTRIBUTES

No new attributes.

=head1 METHODS

No new methods.

=head1 SEE ALSO

L<Net::Hlld>

=head1 AUTHOR

Fabrice Gabolde <fgabolde@weborama.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Weborama.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 USA.

=cut
