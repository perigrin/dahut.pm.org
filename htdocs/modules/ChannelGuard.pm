package Bot::Pluggable::ChannelGuard;
$VERSION = 0.01;
use strict; 
use warnings;
use base qw(Bot::Pluggable::Common);
=pod

=head1 package Bot::Pluggable::Trust

         Common and useful routines for writing Bot::Pluggable Bots

=cut

use POE;

sub new {
    my ($class, @args) = @_;
    my $self = {@args};
    $self->{delay} ||= 3; # set a default;
    return bless $self, ref $class || $class;
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    for my $event qw(set_limit) {
        $self->{_BOT_}->add_event($event);
    }
    for (keys %{ $self->{_BOT_}{Channels} }) {
        $self->{_BOT_}->names($_);
    }   
}

#
# EVENTS
#

sub irc_join {
    my ($self, $bot, $nickstring, $channel) = @_[OBJECT, SENDER, ARG0, ARG1];
    my $nick = $self->nick($nickstring);
    if ($nick eq $bot->{Nick}) {
       $bot->names($channel);
       return 0;
    }
    $self->{_BOT_}{Channels}{$channel}{limit}++;
    my $limit_string = "$channel +l $self->{_BOT_}{Channels}{$channel}{limit}";
    $poe_kernel->delay_set("set_limit", $self->{delay}, ($limit_string));
    $self->{$nick}{$channel} = 1;
    return 0;
}    

sub irc_part {
    my ($self, $bot, $nickstring, $channel) = @_[OBJECT, SENDER, ARG0, ARG1];
    my $nick = $self->nick($nickstring);
    $self->{_BOT_}{Channels}{$channel}{limit}--;
    my $limit_string = "$channel +l $self->{_BOT_}{Channels}{$channel}{limit}";
    $poe_kernel->delay_set("set_limit", $self->{delay}, ($limit_string));
    delete $self->{$nick}{$channel};
    return 0;
}       

sub irc_kick {
    my ($self, $bot, $nickstring, $channel) = @_[OBJECT, SENDER, ARG0, ARG1];
    my $nick = $self->nick($nickstring);
    $self->{_BOT_}{Channels}{$channel}{limit}--;
    my $limit_string = "$channel +l $self->{_BOT_}{Channels}{$channel}{limit}";
    $poe_kernel->delay_set("set_limit", $self->{delay}, ($limit_string));
    delete $self->{$nick}{$channel};
    return 0;
}    

sub irc_quit {
    my ($self, $bot, $nickstring) = @_[OBJECT, SENDER, ARG0];
    my $nick = $self->nick($nickstring);
    for my $channel (keys %{ $self->{$nick} }){
        print STDERR "$nick quit: decrementing $channel\n" if $self->{DEBUG};
        $self->{_BOT_}{Channels}{$channel}{limit}--;
        my $limit_string = "$channel +l $self->{_BOT_}{Channels}{$channel}{limit}";
        $poe_kernel->delay_set("set_limit", $self->{delay}, ($limit_string));
    };
    delete $self->{$nick};
    return 0;
}

sub irc_353 { # Called when we get the repsonse from the NAMES event.
    my ($self, $bot, $server, $message, $kernel) = @_[OBJECT, SENDER, ARG0, ARG1, KERNEL];
    my (undef, $channel, @names) = split(/\s/, $message);
    
    return 0 unless $channel && $channel ne "*";
    
    $names[0] =~ s/^\://; # FFS
    $self->{_BOT_}{Channels}{$channel}{limit} = scalar(@names) + $self->{buffer};
    
    foreach my $raw (@names) {
        my $nick = $raw;
        $nick =~ s/^[\@\+]//;
        print STDERR "saw $nick in $channel\n" if $self->{DEBUG};
        $self->{$nick}{$channel} = 1;
    }
    
    return 0;
}

sub set_limit {
   my ($self, $limit_string) = @_[OBJECT, ARG0];
   print STDERR "$limit_string\n" if $self->{DEBUG};
   $self->{_BOT_}->mode($limit_string);
}