package Bot::Pluggable::Summon;
$VERSION = 0.02;
use strict; 
use warnings;

=pod

=head1 package Bot::Pluggable::Summon

        A Summon Package, used to summon people to channels.

=cut

use base qw(Bot::Pluggable::Common);
use POE;

sub summon {
    my ($self, $channel, $target, $nick) = @_;
    $target = lc($target);
    if ( not $channel ) {
        return "Can't summon unless you're in a channel";
    } 
    elsif ($target eq $self->{_BOT_}->{Nick}) {  
        return "Are you mental?";
    } 
    elsif (defined($self->{$target})) {
        $self->tell($target, "You are summoned in $channel by $nick");
        return "Summoned $target to $channel"; 
    } 
    else {
        return "I don't think I've ever seen $target.";
    }
}

sub seen {
    my ($self, $channel, $target, $nick) = @_;
    $target = lc($target); 
    if ($target eq $self->{_BOT_}->{Nick}) {  
        return "Are you mental?";
    } 
    elsif (defined($self->{$target})) {
        return "I last saw $target at $$self{$target}{when} in $$self{$target}{where}";
    } 
    else {
        return "I don't think I've ever seen $target.";
    }
}

sub dump {
    my ($self, $sender) = @_;
    for my $nick (keys %$self) {
        next if $nick eq '_BOT_';
        $self->tell($sender, "I've seen $nick at $self->{$nick}{when} in $self->{$nick}{where}.");
    }
}

sub told {
    my ($self, $nick, $channel, $message) = @_;
    my $sender = $channel || $nick;
    for ($message) {
        /^summon (\S+)/i      && do { $self->tell($sender, $self->summon($channel, $1, $nick)) };
        /^seen ([^?]+)[?.!]?/i        && do { $self->tell($sender, $self->seen($channel, $1, $nick)) };
        /^who have you seen[?.!]?/i && do { $self->dump($sender) };
    }
}


###############
#
#    EVENTS
#
###############

sub irc_public {
    my ($self, $bot, $nickstring, $channels, $message) = @_[OBJECT, SENDER, ARG0, ARG1, ARG2];  
    my $nick = $self->nick($nickstring);
    $self->{$nick} = {when=>time, where=>$$channels[0]};
    my $me = $bot->{Nick};
    if ($message =~ /^\s*$me[\:\,\;\.]?\s*(.*)$/) {
        $self->told($nick, $channels->[0], $1);
    }
		 return 0;
}
