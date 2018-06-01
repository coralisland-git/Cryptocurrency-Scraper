package Exchange::Okex;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{channels} = {}; # store ws channel for each currency
  $self->{config} = {
	    'id' => 'okex',
            'name' => 'Okex',
            'countries' => 'CN', 
            'rateLimit' => 500,
            'base_currency' => 'CNY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://img.bafang.com/v_20180127113007/okex/image/common/logo_okex_v2.png',
                'api' => 'https://www.okex.com/api/v1/',
                'www' => 'https://www.okex.com/',
                'doc' => 'https://www.okex.com/about/rest_api.html',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 1,
            	'ping'  => 20, # seconds between pings
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
            'symbols' => $self->_get_symbols()
   },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    $self->get(
      url => "https://www.okex.com/api/v1/ticker.do?symbol=$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }
}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;

  #my $symbol = $vars{symbol};
  #warn "Subscribed to ".$vars{symbol};
  my @req_channels;
  foreach my $d (@{$self->{config}->{symbols}}) {
    my $symbol = $d->{id};
    push @req_channels, qq[{'event':'addChannel','channel':'ok_sub_spot_${symbol}_ticker'}]
  }

  $self->logger->info($self->config->{id} .": subscribing to ws ticker feed");
  
  $self->subscribe(
      url => 'wss://real.okex.com:10441/websocket',
      request => '['.join(',', @req_channels).']',
      on_result => sub { $self->process_ticker(@_) },
      on_error  => sub { $self->common_error(@_) },
      reconnect_on_finish => 1,
      ping => {
        enabled  => 1,
        interval => $self->can_ping // 30,
        on_ping  => sub {
          my $tx = shift;
          $tx->send('{"event":"ping"}');
        },
      },
  );  
}

sub process_ticker { 
  my $self = shift;
  my $tx = shift;
  my $ws_data = shift || undef;
  my %vars = @_;
   
  my $time;
  
  my $currency;
  my $ws_currency = '';
  if(defined $ws_data) {
    #{"binary":0,"channel":"addChannel","data":{"result":true,"channel":"ok_sub_spot_neo_usdt_ticker"}}
    
    #{"binary":0,"channel":"ok_sub_spot_neo_usdt_ticker","data":{"high":"180","vol":"31851.9237","last":"142.334",  #"low":"138","buy":"142","change":"-17.073","sell":"142.3443","dayLow":"138","close":"142.334","dayHigh":"151.019","open":"146.5891","timestamp":1517337201328}}

      $ws_data = decode_json $ws_data;
      #print  '>>>>>>>>>>>> ' .@$ws_data[0]->{data}->{result};
      if ('HASH' eq ref $ws_data && $ws_data->{event} && $ws_data->{event} eq 'pong') {
        # got a ping response
        $self->logger->info($self->config->{id} .": pong!");
        return;
      } elsif(defined @$ws_data[0]->{data}->{channel} && @$ws_data[0]->{data}->{result}) {
        my $stored_channel_id = @$ws_data[0]->{data}->{channel}; # save for future
        my $symbol = $stored_channel_id;
           $symbol =~s/^ok_sub_spot_(.+)_ticker$/$1/is;
        $self->{channels}->{$stored_channel_id} = $symbol;
        #print "\n>>>>>>>>> Subscribed to  @$ws_data[0]->{data}->{channel} $symbol\n";
        return;
      }
      elsif(defined @$ws_data[0]->{channel}) {
        my $channel_id = @$ws_data[0]->{channel};
        $currency = @$ws_data[0]->{data};
        $time = substr(@$ws_data[0]->{data}->{timestamp}, 0, -3);
        $vars{id} =  $self->{channels}->{$channel_id};
      }
    }
  else {
    $currency = $tx->result->json->{ticker};
    $time = $tx->result->json->{date};
  }

    my $base_currency = $self->config->{base_currency};

    $self->store_ticker(
        source		=> $self->config->{id},
        currency	=> $vars{id},
        status		=> 0, # proper status for the ticker w/o errors
        date_ts		=> $time,
        base_currency 	=> $base_currency,
        base_usd_rate	=> $vars{id}=~m/$base_currency/is ? $self->usd_rates->{ $base_currency }//1 : 1,,
        highest_bid	=> $currency->{buy},
        lowest_ask	=> $currency->{sell},
        opening_price	=> 0,
        closing_price	=> 0, 
        min_price	=> $currency->{low},
        max_price	=> $currency->{high},
        average_price	=> 0,
        units_traded	=> 0,
        volume_1day	=> $currency->{vol},
        volume_7day	=> 0, 
      );
  return 1;
}


sub _get_symbols {
  my $self = shift;
  my @result = ({id => 'ltc_btc'},
               {id => 'eth_btc'},
               {id => 'etc_btc'},
               {id => 'bch_btc'},
               {id => 'btc_usdt'},
               {id => 'eth_usdt'},
               {id => 'ltc_usdt'},
               {id => 'etc_usdt'},
               {id => 'bch_usdt'},
               {id => 'etc_eth'},
               {id => 'bt1_btc'},
               {id => 'bt2_btc'},
               {id => 'btg_btc'},
               {id => 'qtum_btc'},
               {id => 'hsr_btc'},
               {id => 'neo_btc'},
               {id => 'gas_btc'},
               {id => 'qtum_usdt'},
               {id => 'hsr_usdt'},
               {id => 'neo_usdt'},
               {id => 'gas_usdt'},);
  my $new_result;
  
  foreach (@result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_->{id});
    push @{$new_result}, $_;
  }
  
  return $new_result;
}

2;
