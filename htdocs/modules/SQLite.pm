package Bot::Pluggable::Trust::SQLite;
$VERSION = 0.04;
use strict;
use warnings;
use base qw(Bot::Pluggable::Trust);

=pod

=head1 package Bot::Pluggable::Trust::SQLite

         This is just like Bot::Pluggable::Trust except that it uses SQLite to    
         provide for the backend userdata.

=cut

use DBI;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_DBH_} = DBI->connect("dbi:SQLite:dbname=$$self{dbfile}","","");
    $self->load_schema;
    $self->load;
    return $self;
}

sub load_schema {
    my ($self) = @_;   
    my $query = qq{ SELECT name FROM sqlite_master
                    WHERE type='table'
                    AND ( name = 'channel'
                       OR name = 'voice'
                       OR name = 'ops'
                        )
                    ORDER BY name
                  };
    return if defined @{ $self->{_DBH_}->selectall_arrayref($query) }[0];
    my @new_tables = (
        qq{CREATE TABLE ops (
            name TEXT,
            channel TEXT,
            UNIQUE(name, channel)
        )},
        qq{CREATE TABLE voice (
            name TEXT,
            channel TEXT,
            UNIQUE(name, channel)
        )},
        qq{CREATE TABLE channel (
            name TEXT UNIQUE
        )},
    );   
    for my $query (@new_tables) {
        $self->{_DBH_}->do($query) or die "Can't Create Table: $query";
    }
    return;
}

sub load_channels {
    my $self = shift;
    $self->{_BOT_}{Channels} = {};
    my $query = qq{ SELECT name FROM channel };
    my $channels = $self->{_DBH_}->selectall_arrayref($query); 
        if ($DBI::errstr){ die "$DBI::errstr - $query"}
    for my $channel (@$channels) {
        $channel = $$channel[0];
        warn "Loading $channel" if $self->{DEBUG};
        $self->{_BOT_}{Channels}{$channel} = {};
    }
}

sub load_ops {
    my ($self, $channel) = @_;
    #$channel =~ s/#//;
    $self->{_BOT_}{Channels}{$channel}{ops} = {};
    my $query = qq{ SELECT name 
                    FROM ops 
                    WHERE channel = '$channel' };
                      
		 my $users = $self->{_DBH_}->selectall_arrayref($query); 
        if ($DBI::errstr){ die "$DBI::errstr - $query"};
    for my $user (@$users) {
        #$channel = '#'.$channel;
        warn "Loading $channel +o $$user[0]" if $self->{DEBUG};
        $self->{_BOT_}{Channels}{$channel}{ops}{$$user[0]}++
    } 
}

sub load_voice {
    my ($self, $channel) = @_;
    #$channel =~ s/#//;
    $self->{_BOT_}{Channels}{$channel}{voice} = {};    
    my $query = qq{ SELECT name 
                    FROM voice  
                    WHERE channel = '$channel' };
                         
		 my $users = $self->{_DBH_}->selectall_arrayref($query); 
        if ($DBI::errstr){ die "$DBI::errstr - $query"}
    for my $user (@$users) {
        #$channel = '#'.$channel;
        warn "Loading $channel +v $$user[0]" if $self->{DEBUG};
        $self->{_BOT_}{Channels}{$channel}{voice}{$$user[0]}++
    }
}

sub save_channels {
    my ($self) = @_;
    for my $channel (keys %{ $self->{_BOT_}{Channels} }) {
        warn "Saving $channel" if $self->{DEBUG};
        #$channel =~ s/#//g;
        my $query = qq{ REPLACE INTO channel(name) VALUES('$channel') };
        die "$query" unless $self->{_DBH_}->do($query); 
    }
}

sub save_ops {
    my ($self, $channel) = @_;
    for my $user (keys %{ $self->{_BOT_}{Channels}{$channel}{ops} }) {
        warn "Saving $channel +o $user" if $self->{DEBUG};
        #$channel =~ s/#//g;
        my $query = qq{ REPLACE INTO ops(name, channel) VALUES('$user', '$channel') };
        die "$query" unless $self->{_DBH_}->do($query);
    }
}

sub save_voice {
    my ($self, $channel) = @_;
    for my $user (keys %{ $self->{_BOT_}{Channels}{$channel}{voice} }) {
        warn "Saving $channel +v $user" if $self->{DEBUG};
        #$channel =~ s/#//g;
        my $query = qq{ REPLACE INTO voice(name, channel) VALUES('$user', '$channel') };
        die "$query" unless $self->{_DBH_}->do($query);
    }
}


sub part {
  my ($self, $channel, $target, $nick) = @_;
  if ($self->check_ops($nick)) {
      my $channel = $1;
      print STDERR "Told to leave $channel by $nick\n";
      eval { for my $query ( 
                 qq{DELETE FROM channel WHERE name = '$channel'},
                 qq{DELETE FROM ops WHERE channel = '$channel'},
                 qq{DELETE FROM voice WHERE channel = '$channel'},
             ) {  $self->{_DBH_}->do($query)  }
      };
      if ($@) { warn "there was a problem: $@";
                return "I seem to be having trouble doing that";
      }
      $self->{_BOT_}->part($channel);
      delete $self->{_BOT_}{Channels}{$channel};
      return "Ok, bye. I'll remember this.";
  }
  return "Sorry, $nick, I don't trust you.";
}

sub distrust {
    my ($self, $channel, $target, $nick) = @_;
    if (!($self->check_ops($target, $channel))) {
        return "But I don't trust $target";
    } elsif (!($self->check_ops($nick, $channel))) {
        return "But I don't trust >you<, $nick";
    } elsif ($self->{owner} eq $target) {
        print STDERR "$nick tried to distrust $$self{owner}. Telling him to fuck right off.\n";
        return "Yeah, right. As if.";
    } elsif (!$channel) {
        return "Uh, you need to tell me that again in a channel.";				 
    } else {
        print STDERR "Distrusting '$target' due to '$nick'\n";
        eval { for my $query ( 
                 qq{DELETE FROM ops WHERE name = '$target'},
             ) {  $self->{_DBH_}->do($query)  }
        };
        if ($@) { warn "there was a problem: $@";
                return "I seem to be having trouble doing that";
        }
        delete $self->{_BOT_}{Channels}{$channel}{ops}{$target};
        delete $self->{_BOT_}{Channels}{$channel}{voice}{$target} if $self->{_BOT_}{Channels}{$channel}{voice}{$target};
        return "Ok, $nick"
    }
}

sub disbelieve {
    my ($self, $channel, $target, $nick) = @_;
    if (!($self->check_voice($target, $channel))) {
        return "But I don't believe $target";
    } elsif ($self->check_ops($target, $channel)) {
        return "But I >trust< $target";
    } elsif (!($self->check_ops($nick))) {
        return "But I don't trust >you<, $nick";
    } elsif (!$channel) {
        return "Uh, you need to tell me that again in a channel.";
		} else {
        print STDERR "Distrusting '$target' due to '$nick'\n";
        eval { for my $query ( 
                 qq{DELETE FROM voice WHERE nick = '$target'},
             ) {  $self->{_DBH_}->do($query)  }
        };
        if ($@) { warn "there was a problem: $@";
                return "I seem to be having trouble doing that";
        }
        delete $self->{_BOT_}{Channels}{$channel}{voice}{$target};
        $self->save;
        return "Ok, $nick"
    }
}