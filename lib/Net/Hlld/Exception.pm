package Net::Hlld::Exception;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends 'Throwable::Error';

1;
__END__
=pod

=head1 NAME

Net::Hlld::Exception -- Base class for Net::Hlld exceptions

=head1 SYNOPSIS

  package Net::Hlld::Exception::UnicornRelated;
  use Moo;
  extends 'Net::Hlld::Exception';
  has 'horns' => (is => 'ro',
                  default => 1);

=head1 DESCRIPTION

This is a L<Throwable::Error>-derived exception class for L<Net::Hlld>
exceptions.

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
