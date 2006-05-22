package Net::BF2S;

our $VERSION = '0.03';

sub new {
  warn('Use WWW::BF2S instead.  All use of Net::BF2S is deprecated.');
  my $class = shift;
  use WWW::BF2S;
  return WWW::BF2S->new(@_);
}

1;

__END__

=head1 NAME

Net::BF2S - Get Battlefield 2 Player Stats

=head1 SYNOPSIS

Use WWW::BF2S instead.

The root namespace has been changed to WWW to better describe its purpose and usage.

Sorry for the inconvenience.

=head1 AUTHOR

Dusty Wilson, E<lt>bf2s-module@dusty.hey.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson E<lt>http://dusty.hey.nu/E<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
