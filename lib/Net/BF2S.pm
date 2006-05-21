package Net::BF2S;

our $VERSION = '0.01';

use XML::Simple;
use Data::Dumper;
use LWP::Simple;

sub new {
  my $class = shift;
  my %options = @_;
  my $self = {};
  bless($self, $class); # class-ify it.

  $self->{debugLog} = $options{DebugLog} || 'debug.log';
  $self->{debugLevel} = $options{DebugLevel} || 0;
  $self->{storeFile} = $options{StoreFile} || 'stats.xml';

  eval { $self->{store} = XMLin($self->{storeFile}); }; # read in store XML data (it's okay if it fails/doesn't exist, I think)

  $self->__debug(7, 'Object Attributes:', Dumper($self));

  return $self;
}

sub __debug {
  my $self = shift || return undef;
  return undef unless $self->{debugLog}; # skip unless log file is defined
  my $level = int(shift);
  return undef unless $self->{debugLevel} >= $level; # skip unless log level is as high as this item
  if (open(BF2SDEBUG, ">>$self->{debugLog}")) {
    my $time = localtime();
    foreach my $group (@_) { # roll through many items if they are passed in as an array
      foreach my $line (split(/\r?\n/, $group)) { # roll through items that are multiline, converting to multiple separate lines
        print BF2SDEBUG "[$time] $line\n";
      }
    }
    close(BF2SDEBUG);
  }
  return undef;
}

sub __fetchData {
  my $self = shift || return undef;

  my $urlBase = 'http://bf2s.com/xml.php?pids=';
  my $pidList = {};
  foreach my $pid (@_) {
    next if ($pid =~ m|[^0-9]|); # check for validity
    next if ($self->{store}->{'pid'.$pid}->{updated} + 7200 > time()); # make sure the cached copy is old enough (2 hours)
    $pidList->{$pid}++; # add it to the queue
  }
  $self->__debug(6, 'PIDS REQUESTED:', keys(%{$pidList}));

  my @candidates;
  # TODO: make a list of candidates from the data store (even ones we're not asking for) in order of best to worst

  while (scalar(keys(%{$pidList})) < 64) { # if the request list is shorter than 64 pids (the max per request), we should add more from the cache that need refreshed instead of wasting the opportunity
    my $candidate = shift(@candidates) || last; # get the next candidate from the list (or exit the loop because we've run out of candidates)
    next if ($pidList->{$candidate}); # if it's already in the list, skip it
    $pidList->{$candidate}++; # seems okay, add it to the pidList
  }
  $self->__debug(6, 'PIDS WITH AUTO:', keys(%{$pidList}));
  my $pids = join(',', sort(keys(%{$pidList}))); # join the queue in a proper format

  return $response unless $pids; # only proceed if there is something to fetch

  my $response = get($urlBase.$pids); # fetch the data from the source (bf2s feed)
  #use IO::All; my $response; $response < io('test.xml'); # for testing only (an XML file that has a sample of raw returned data from the feed source)
  return undef unless $response; # if it failed, don't continue

  my $parsedResponse = XMLin($response); # parse the XML into a hashref
  $self->__debug(7, 'PARSEDRESPONSE:', Dumper($parsedResponse));

  $parsedResponse->{player} = $self->__forceArray($parsedResponse->{player});

  my $stats = {};
  foreach my $player (@{$parsedResponse->{player}}) { # store in a normalized structure
    next unless ($pidList->{$player->{pid}}); # probably not necessary, but don't parse things we didn't ask for
    $player->{updated} = time();
    $stats->{$player->{pid}} = $player;
  }
  $self->__debug(7, 'NORMALIZEDRESPONSE:', Dumper($stats));
  $self->__injectIntoDataStore($stats);

  return $stats; # return the response content
}

sub __forceArray {
  my $self = shift;
  my $input = shift;
  return $input if (ref($input) eq 'ARRAY'); # return if already an arrayref
  my $output;
  $output->[0] = $input; # force it to be an item in an arrayref
  return $output; # return the arrayref
}

sub __injectIntoDataStore {
  my $self = shift;
  my $stats = shift;

  foreach my $pid (keys(%{$stats})) {
    next if ($pid =~ m|[^0-9]|); # ensure only numerical pids (is this necessary?)
    $self->{store}->{'pid'.$pid} = $stats->{$pid}; # insert/replace into data store
  }

  my $storeOut = XMLout($self->{store}); # convert hashref data into XML structure
  if ($storeOut) { # only if storeOut is valid/existing (wouldn't want to wipe out our only cache/store with null)
    if (open(STOREFH, '>'.$self->{storeFile})) { # overwrite old store file with new store file
      print STOREFH $storeOut;
      close(STOREFH);
    }
  }

  return undef;
}

sub getStats {
  my $self = shift;
  my @pids = @_;
  my $stats = {};

  $self->__fetchData(@pids); # get fresh data when if necessary

  foreach my $pid (@pids) { # prep the requested data for return
    $stats->{$pid} = $self->{store}->{'pid'.$pid};
  }

  return $stats; # return the requested data
}

1;

__END__

=head1 NAME

Net::BF2S - Get Battlefield 2 Player Stats

=head1 SYNOPSIS

  use Net::BF2S;
  my $bf2 = Net::BF2S->new;
  my $data = $bf2->getStats(45355493,64573414,64318788,64246757,62797217,61091442,64964638,64661842,65431962,58968459);

=head1 DESCRIPTION

Fetches Battlefield 2 player stats from BF2S.

You must use the PID (player ID) when requesting stats.  If you try to request the player stats by player name, the module will ignore it.  You can get the PID from many sources, including the BF2S.com website.

You can only make THREE requests for data in a SIX hour period.  This is a restriction from the feed provider, not of the module.  Try to ask for as much information as possible in one request.  The module (not yet) is written in a way that will try to include a list of "candidates" (a list of PIDs that you've asked for before, but you didn't ask for this time around) that will also be requested in that same request, which is meant to update your local player stat cache when possible.

I'll provide more documentation later.

=head1 SEE ALSO

Uses data feed from Jeff Minard's BF2S MyLeaderBoard API E<lt>http://jrm.cc/extras/mlb/readme.html<gt>.

=head1 TODO

Need to finish the "candidates" list functionality.

=head1 CHANGES

0.01 - Sun May 21 21:52:31 2006 - Dusty Wilson
  New module with basic functionality.

=head1 BUGS

There probably are some.  Let me know what you find.

=head1 AUTHOR

Dusty Wilson, E<lt>bf2s-module@dusty.hey.nu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson E<lt>http://dusty.hey.nu/<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
