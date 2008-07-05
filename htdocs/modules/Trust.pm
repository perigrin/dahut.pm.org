package Bot::Pluggable::Trust;
$VERSION = 0.04;
use strict; 
use warnings;
use base qw(Bot::Pluggable::Common);
=pod

=head1 package Bot::Pluggable::Trust

    A simple Slavorg style Trust module, designed to replace the Mozbot
    Trust module currently employed by Marvin on #axkit-dahut
    
    Much of this code was 'Borrowed' from the Slavorg2 PoCo::Object bot 
    found at http://jerakeen.org/cms/slavorg2 converted over to  
    Bot::Pluggable despite the issues brought up on 
    http://www.jerakeen.org/cms/irc/bots

=cut

use POE;

sub new { 
		my $class = shift;
		my %args = @_;
		return bless \%args, $class 
}

######################################################################################
## Utils
######################################################################################

sub init {
    my $self = shift;
    $self->SUPER::init(@_); 
    for my $event qw(irc_353 dotheopthing) {
        $self->{_BOT_}->add_event($event);
    }  
    $self->load; 
}

sub quit {
    my ($self) = @_;
    $self->save;
    $self->{_BOT_}->shutdown;
    exit;
}

sub load {
    my $self = shift;
    $self->load_channels;
    for my $channel (keys %{ $self->{_BOT_}{Channels} }) {
        warn "Loading Ops" if $self->{DEBUG};
        $self->load_ops($channel);
        warn "Loading Voice" if $self->{DEBUG};
        $self->load_voice($channel);
    }
}

sub save {
    my $self = shift;
    $self->save_channels;
    for my $channel (keys %{ $self->{_BOT_}{Channels} }) {
        warn "Saving Ops" if $self->{DEBUG};
        $self->save_ops($channel);
        warn "Saving Voice" if $self->{DEBUG};
        $self->save_voice($channel);
    }
}

sub load_ops {
    my ($self, $channel) = @_;
    $self->{_BOT_}{Channels}{$channel}{ops} = {};
		 my $file = "$self->{_BOT_}->{Nick}_ops";
    if (open(READ, "$file")) {
        while (<READ>) {
            chomp;
            $self->{_BOT_}{Channels}{$channel}{ops}{$_}++ unless $self->{_BOT_}{Channels}{$channel}{ops}{$_};
        }
        close(READ);
    } else {
        print STDERR "Can't open ops file ($file): $!\n";
    }
}

sub load_voice {
    my ($self, $channel) = @_;
    $self->{_BOT_}{Channels}{$channel}{voice} = {};
		 my $file = "$self->{_BOT_}->{Nick}_voice";
    if (open(READ, "$file")) {
        while (<READ>) {
            chomp;
            $self->{_BOT_}{Channels}{$channel}{voice}{$_}++ unless $self->{_BOT_}{Channels}{$channel}{voice}{$_};
        }
        close(READ);
    } else {
        print STDERR "Can't open voice file ($file): $!\n";
    }
}

sub load_channels {
    my $self = shift;
    $self->{_BOT_}{Channels} = {};
    my $file = $self->{_BOT_}->{Nick}.'_channels';
    if (open(READ, "$file")) {
        while (<READ>) {
            chomp;
            $self->{_BOT_}{Channels}{$_} = {};
        }
        close(READ);
    } else {
        print STDERR "Can't open channels file ($file): $!\n";
    }
}

sub save_ops {
    my ($self, $channel) = @_;
		my $file = "$self->{_BOT_}->{Nick}_ops";
    if (open(READ, ">$file")) {
        print READ "$_\n" for keys(%{$self->{_BOT_}{Channels}{$channel}{ops}});
        close READ;
    } else {
        print STDERR "Can't save ops file ($file): $!\n";
    }
}

sub save_voice {
    my ($self, $channel) = @_;
		my $file = "$self->{_BOT_}->{Nick}_voice";
    if (open(READ, ">")) {
        print READ "$_\n" for keys(%{$self->{_BOT_}{Channels}{$channel}{voice}});
        close READ;
    } else {
        print STDERR "Can't save voice file ($file): $!\n";
    }
}

sub save_channels {
    my ($self) = @_;
    my $file = $self->{_BOT_}->{Nick}.'_channels';
    if (open(READ, ">$file")) {
        print READ "$_\n" for keys(%{$self->{_BOT_}{Channels}});
        close READ;
    } else {
        print STDERR "Can't save channels file ($file): $!\n";
    }
}

sub check_ops {
		my ($self, $nick, $channel) = @_;
		if ($nick eq $self->{owner}) {
			 return 1; #Bawhahaha!
		}
		elsif ($channel) {
			 return $self->{_BOT_}{Channels}{$channel}{ops}{$nick};
		} 
		else {
			 for $channel (keys %{ $self->{_BOT_}{Channels} }) {
			 		 return 1 if $self->{_BOT_}{Channels}{$channel}{ops}{$nick};
			 }
		}		
}

sub check_voice {
		my ($self, $nick, $channel) = @_;
		if ($channel) {
			 return $self->{_BOT_}{Channels}{$channel}{voice}{$nick};
		} else {
			 for $channel (keys %{ $self->{_BOT_}{Channels} }) {
			 		 return 1 if $self->{_BOT_}{Channels}{$channel}{voice}{$nick};
			 }
		}		
}

sub list_ops {
		my $self = shift;
		my %ops = ();
 	  for my $channel (keys %{ $self->{_BOT_}{Channels} }) {
			   for my $user (keys %{ $self->{_BOT_}{Channels}{$channel}{ops} }) {
           $ops{$user}++ 
       }
		}
		return [$$self{owner}, keys %ops];
}

sub nick {
   my ($self, $nickstring) = @_;
		my ($nick, undef) = split(/!/, $nickstring, 2);
		return $nick;
}		

sub trust {
    my ($self, $channel, $target, $nick) = @_;
    if ($self->check_ops($target, $channel)) {
        return "But I already trust $target";
    } elsif (!($self->check_ops($nick, $channel))) {
        return "But I don't trust >you<, $nick";
    } elsif (!$channel) {
        return "Uh, you need to tell me that again in a channel.";
    } else {
        print STDERR "Trusting '$target' due to '$nick'\n";
        $self->{_BOT_}{Channels}{$channel}{ops}{$target}++;
        delete $self->{_BOT_}{Channels}{$channel}{voice}{$target} if $self->{_BOT_}{Channels}{$channel}{voice}{$target};
        $self->save;
        return "OK, $nick";
    }
}

sub believe {
    my ($self, $channel, $target, $nick) = @_;
    if ($self->check_voice($target, $channel)) {
        return "But I already believe $target";
    } elsif ($self->check_ops($target, $channel)) {
        return "But I already >trust< $target";
    } elsif (!($self->check_ops($nick, $channel))) {
        return "But I don't trust >you<, $nick";
    } elsif (!$channel) {
        return "Uh, you need to tell me that again in a channel.";
    } else {
        $self->{_BOT_}{Channels}{$channel}{voice}{$target}++;
        $self->save;
        return "OK, $nick"
    }
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
        delete $self->{_BOT_}{Channels}{$channel}{ops}{$target};
        delete $self->{_BOT_}{Channels}{$channel}{voice}{$target} if $self->{_BOT_}{Channels}{$channel}{voice}{$target};
        $self->save;
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
        delete $self->{_BOT_}{Channels}{$channel}{voice}{$target};
        $self->save();
        return "Ok, $nick";
    }
}

sub check_trust { 
    my ($self, $channel, $target, $nick) = @_;
    if ($self->check_ops($target)) {
        return "Yes, I trust $target.";
    } else {
        return "No, I don't trust $target.";
    }
}

sub trust_where {
		my ($self, $channel, $target) = @_;
		my @rooms = ();
   if ($target eq $$self{owner}) {
        @rooms = keys %{ $self->{_BOT_}{Channels} };
   }
   else {
        for my $channel (keys %{ $self->{_BOT_}{Channels} }) {
        push @rooms, $channel if $self->{_BOT_}{Channels}{$channel}{ops}{$target};
        }
   }
  	return "I trust $target in ". CORE::join(', ', @rooms) if ($rooms[0]); 
		return "I don't trust $target anywhere";
}

sub check_belief {
    my ($self, $channel, $target, $nick) = @_;
    if ($self->check_voice($target) || $self->check_ops($target)) {
        return "Yes, I believe $1.";
    } else {
        return "No, I don't believe $1.";
    }
}

sub believe_where {
		my ($self, $channel, $target) = @_;
		my %rooms = ();
		for my $channel (keys %{ $self->{_BOT_}{Channels} }) {
				$rooms{$channel}++ if $self->{_BOT_}{Channels}{$channel}{ops}{$target};
				$rooms{$channel}++ if $self->{_BOT_}{Channels}{$channel}{voice}{$target};
		}
  	return "I believe $target in ". CORE::join(', ', keys %rooms) if (keys %rooms); 
		return "I don't trust $target anywhere";
}

sub join {
	my ($self, $channel, $target, $nick) = @_;
  if ($self->check_ops($nick)) {
      my $channel = $1;
      print STDERR "Told to join $channel by '$nick'\n";
      $self->{_BOT_}->join($channel);
      $self->{_BOT_}{Channels}{$channel}= {};
      $self->save();
      # TODO this is bad, we should make sure we sucessfully join the channel, really.
			return "Joined $channel. I'll remember this.";
  } else {
		  return "Sorry, $nick, I don't trust you.";
  }		
}

sub part {
  my ($self, $channel, $target, $nick) = @_;
  if ($self->check_ops($nick)) {
      my $channel = $1;
      print STDERR "Told to leave $channel by $nick\n";
      $self->{_BOT_}->part($channel);
      delete $self->{_BOT_}{Channels}{$channel};
      eval { $self->save() };
      if ($@) { warn "there was a problem saving: $@" };
			return "Ok, $nick, bye. I'll remember this.";
  } else {
    return "Sorry, $nick, I don't trust you.";
  }
}

sub told {
    my ($self, $nick, $channel, $message) = @_;
    my $sender = $channel || $nick;
    
    my $PUNC_RX = qr([?.!]?);
    my $NICK_RX = qr([][a-z0-9^`{}_|\][a-z0-9^`{}_|\-]*)i;

    # Trust 
    if ($message =~ /^trust\s+($NICK_RX)$PUNC_RX/i) {
        my $target = $1;
        my $res = $self->trust($channel, $target, $nick);
        $self->tell($sender, $res);
    }
    # Believe 
    elsif ($message =~ /^believe\s+($NICK_RX)$PUNC_RX/i) {
        my $target = $1;
        my $res = $self->believe($channel, $target, $nick);
        $self->tell($sender, $res);
    }
    # Distrust 
    elsif ($message =~ /^distrust\s+($NICK_RX)$PUNC_RX/i) {
        my $target = $1;
        my $res = $self->distrust($channel, $target, $nick);
        $self->tell($sender, $res);
    }
    # Disbelief
    elsif ($message =~ /^disbelieve\s+($NICK_RX)$PUNC_RX/i) {
        my $target = $1;
        my $res = $self->disbelieve($channel, $target, $nick);
        $self->tell($sender, $res);
    }
    # Check Trust
    elsif ($message =~ /^do\s+you\s+trust\s+($NICK_RX)$PUNC_RX/i) {
        my $target = $1;
        my $res = $self->check_trust($channel, $target, $nick);
        $self->tell($sender, $res);
    }
		elsif ($message =~ /^where\s+do\s+you\s+trust\s+($NICK_RX)$PUNC_RX/i) {
		    my $target = $1;
        my $res = $self->trust_where($channel, $target, $nick);
        $self->tell($sender, $res);
    }
    # Check Belief
    elsif ($message =~ /^do\s+you\s+believe\s+($NICK_RX)$PUNC_RX/i) {
        my $target = $1;
        my $res = $self->check_belief($channel, $target, $nick);
        $self->tell($sender, $res);
		}
		elsif ($message =~ /^where\s+do\s+you\s+believe\s+($NICK_RX)$PUNC_RX/i) {
		    my $target = $1;
        my $res = $self->believe_where($channel, $target, $nick);
        $self->tell($sender, $res);
    }
    # Op on Command
		elsif ($message =~ /^do\s+the\s+op\s+thing$PUNC_RX/i) {
			  $self->dotheopthing();
		}
    # report owner
    elsif ($message =~ /^who\s+is\s+your\s+owner$PUNC_RX/i) {
	  		$self->tell($sender, "I'm owned by $$self{owner}");
		}
    # report all trusts
    elsif ($message =~ /^who\s+do\s+you\s+trust$PUNC_RX/i) {
				$self->tell($sender, "I trust: ".CORE::join(', ', @{ $self->list_ops }));
		}
    # report nick back to sender
		elsif ($message =~/^who\s+am\s+i$PUNC_RX/i) { 
			  $self->tell($sender, "You are $nick");
    }      
    ##################################################################
    ## Other things.

    # Help
    elsif ($message =~ /^help/i) {
        $self->tell($sender, "I'm an opbot. I op people I trust ($self->{_BOT_}->{Nick}, trust <nick>), and voice people I believe ($self->{_BOT_}->{Nick}, believe <nick>).");
        $self->tell($sender, "You can invite me to other channels you want me to look after, and kick me out if I annoy you.");
    }
    # Join
    elsif ($message =~ /^join\s+(.*)$/i) {
	 			 my $target = $1;
         my $res = $self->join($channel, $target, $nick);
				 $self->tell($sender, $res);
    }
    # Leave
    elsif ($message =~ /^(?:leave|part)\s+(.*)$/i) {
 	 			 my $target = $1;
         my $res = $self->part($channel, $target, $nick);
				 $self->tell($sender, $res);
    }
    elsif ($message =~ /^(?:quit)$/i) {
 	      my $target = $1;
         my $res = $self->quit($nick);
				 $self->tell($sender, $res);
    }	 
}

sub tell {
    my ($self, $target, $message) = @_;
    $self->{_BOT_}->privmsg($target, $message) if $target and $message; 
}

    
######################################################################################
## Event handlers
######################################################################################

sub irc_001 {
    my ($self, $bot, $kernel) = @_[OBJECT, SENDER, KERNEL];
    $self->init($bot);
		 $bot->join($_) for keys %{ $self->{_BOT_}{Channels} };
    $kernel->delay_set("dotheopthing", $$self{delay} || 10, $bot);
		 return 0;
}

sub irc_public {
    my ($self, $bot, $nickstring, $channels, $message) = @_[OBJECT, SENDER, ARG0, ARG1, ARG2];  
    my $nick = $self->nick($nickstring);
    my $me = $bot->{Nick};
    if ($message =~ /^\s*$me[\:\,\;\.]?\s*(.*)$/) {
        $self->told($nick, $channels->[0], $1);
    }
    return 0 if (time - ( $self->{recent_names} || 0 ) < 10);
    $self->{recent_names} = time;
    $bot->names($channels->[0]);
		return 0;
}    

sub irc_invite {
    my ($self, $bot, $nickstring, $channel) = @_[OBJECT, SENDER, ARG0, ARG1];
    my $nick = $self->nick($nickstring);
    if ($self->check_ops($nick)) {
        print STDERR "Invited to $channel by $nick\n";
        $bot->join($channel);
        $self->{_BOT_}{Channels}{$channel}++;
        $self->save($bot);
        # TODO this is bad, we should make sure we sucessfully join the channel, really.
        return 1;
    } else {
        $self->tell($bot, $nick, "Sorry, I don't trust you enough");
        return 0;
    }
}

sub irc_kick {
    my ($self, $kernel, $nickstring, $channel, $kicked, $reason) = @_[OBJECT, KERNEL, ARG0, ARG1, ARG2, ARG3];
    if ($kicked eq $self->{Nick}) {
        print STDERR "Kicked from $channel by $nickstring ($reason)\n";
        $kernel->delay_set("join", 2, $channel);
    }
		return 0;
}

sub irc_mode {
    my ($self, $bot, $nickstring, $channel, $mode, @ops) = @_[OBJECT, SENDER, ARG0 .. $#_];
    # Poking ops every time ops get poked would be very silly. So we only do
    # if it was us what woz opped, so we can wake up and op other people.
    delete $self->{_BOT_}{Channels}{$channel}{to_op} and $bot->names($channel) if (grep($self->{_BOT_}{Nick}, @ops)) and $channel;
		return 0;
}

sub irc_msg {
    my ($self, $bot, $nickstring, $recipients, $message) = @_[OBJECT, SENDER, ARG0, ARG1, ARG2];
    my $nick = $self->nick($nickstring);
    $self->told($nick, undef, $message);
		return 0;
}

sub irc_nick {
    my ($self, $bot, $from, $to) = @_[OBJECT, SENDER, ARG0, ARG1];
    # If people change nicks, we should notice if they need opping.
    delete $self->{_BOT_}{Channels}{$_}{to_op} and $bot->names($_) for (keys(%{$self->{_BOT_}{Channels}}));
		return 0;
}

sub irc_join {
   my ($self, $bot, $nickstring, $channel) = @_[OBJECT, SENDER, ARG0, ARG1];
		if ($channel) {
      delete $self->{_BOT_}{Channels}{$channel}{to_op};
      $bot->names($channel);
		}
   return 0;
}

sub irc_353 { # Called when we get the repsonse from the NAMES event.
    my ($self, $bot, $server, $message, $kernel) = @_[OBJECT, SENDER, ARG0, ARG1, KERNEL];
    # Names.
    my (undef, $channel, @names) = split(/\s/, $message);
    $names[0] =~ s/^\://; # FFS

    return 0 unless $channel && $channel ne "*";

    foreach my $raw (@names) {
        my $nick = $raw;
        $nick =~ s/^[\@\+]//;

        my $opped = ($raw =~ /^\@/) ? "opped" : "";
        my $voice = ($raw =~ /^\+/) ? "voiced" : "";

        if ($self->check_ops($nick, $channel)) {
            if ($opped) {
                delete $self->{_BOT_}{Channels}{$channel}{to_op}{$nick};
            } else {
                $self->{_BOT_}{Channels}{$channel}{to_op}{$nick}++;
            }
        }
    
        if ($self->check_voice($nick)) {
            if ($voice or $opped) {
                delete $self->{_BOT_}{Channels}{$channel}{to_voice}{$nick};
            } else {
                $self->{_BOT_}{Channels}{$channel}{to_voice}{$nick}++;
            }
        }
    }
		return 0;
}

sub dotheopthing {
    my ($self, $bot) = @_[OBJECT, ARG0];
    foreach my $channel (keys(%{$self->{_BOT_}{Channels}})) {
        # Organize our data a bit so we can figure out what the hell we're gonna do
        my $change_mode = {};
        $$change_mode{$_} = 'o' for keys(%{$self->{_BOT_}{Channels}{$channel}{to_op}});
        $$change_mode{$_} = 'v' for keys(%{$self->{_BOT_}{Channels}{$channel}{to_voice}});
        
        # Cleverness here groups people into lots of three, so we don't
        # flood the channel with op messages if we have to op lots of
        # people.
        #
        # I've gone ahead and combined both the voice and ops 
        # so it will do things like +oov baud, ubu, axdahut
        my $multi_op = []; my $modes = [];
        for my $nick (keys(%$change_mode)) {
            next if (time() - ( $self->{_BOT_}{Channels}{$channel}{recent_ops}{$nick} || 0) < $$self{lag});
            $self->{_BOT_}{Channels}{$channel}{recent_ops}{$nick} = time;
            if (scalar(@$multi_op) < 3) { # Spec says 4. Clients rarely do > 3. So I use 3.
               push(@$multi_op, $nick);
               push(@$modes, $$change_mode{$nick});
            } else {
              $bot->mode("$channel +".CORE::join('', @$modes).' '.CORE::join(" ", @$multi_op)); 
              $multi_op = [$nick];
              $modes = [$$change_mode{$nick}]
            }
            $bot->mode("$channel +".CORE::join('', @$modes).' '.CORE::join(" ", @$multi_op));   
        }
        delete $self->{_BOT_}{Channels}{$channel}{to_op};
        delete $self->{_BOT_}{Channels}{$channel}{to_voice};
    }
    $poe_kernel->delay_set("dotheopthing", $$self{delay} || 10, $bot);
    return 1;
}

1;
__END__

=pod

    Change Log
    v0.03
				 07-Feb-2003 12:55 AM -- Multi-Channel Hacked in ... I think (chris)
		v0.02
         2/5/2003 9:32 PM -- Started Documentation (chris)

=cut