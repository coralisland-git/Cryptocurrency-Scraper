package Exchange::Binance;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;
use JSON::XS qw{decode_json encode_json};

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'binance',
            'name' => 'Binance',
            'countries' => 'JP', 
            'rateLimit' => 500,
            'base_currency' => 'USD',
            'has' => {
                'fetchDepositAddress' => 1,
                'CORS' => undef,
                'fetchBidsAsks' => 1,
                'fetchTickers' => 1,
                'fetchOHLCV' => 1,
                'fetchMyTrades' => 1,
                'fetchOrder' => 1,
                'fetchOrders' => 1,
                'fetchOpenOrders' => 1,
		'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/29604020-d5483cdc-87ee-11e7-94c7-d1a8d9169293.jpg',
                'api' => {
                    'web' => 'https://www.binance.com',
                    'wapi' => 'https://api.binance.com/wapi/v3',
                    #'wapi' => 'https://127.0.0.1:6443/wapi/v3',
                    'public' => 'https://api.binance.com/api/v1',
                    'private' => 'https://api.binance.com/api/v3',
                    'v3' => 'https://api.binance.com/api/v3',
                    'v1' => 'https://api.binance.com/api/v1',
                    'wsock' => 'wss://stream.binance.com:9443'
                },
                'www' => 'https://www.binance.com',
                'doc' => 'https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.md',
                'fees' => [
                    'https://binance.zendesk.com/hc/en-us/articles/115000429332',
                    'https://support.binance.com/hc/en-us/articles/115000583311',
		],
            },
            'apis' => {
              'private' => {
                'account' => { 'method' => 'get' },
                'openOrders' => { 'method' => 'get' },
                'allOrders' => { 'method' => 'get' },
              },
              'wapi' => {
                'withdrawHistory.html' => { 'method' => 'get' },
                'depositHistory.html' => { 'method' => 'get' },
                'accountStatus.html' => { 'method' => 'get' },
              },
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => 1,
            },
            'fees' => {
                'trading' => {
		    'taker' => 0.001,
		    'maker' => 0.001,
                },
            },
            'symbols' => undef,
    };

    $self->config->{symbols} = $self->_get_symbols();
}


sub ticker_ws {
  my $self = shift;
  my %vars = @_;

  $self->logger->info($self->config->{id} .": subscribing to ws ticker feed");

  my @symbols_buf;
  foreach my $d (@{$self->{config}->{symbols}}) {
    my $symbol = $d->{id};
    push @symbols_buf, lc $symbol.'@ticker'
  }

  
  $self->subscribe(
      url => $self->api('wsock').'/stream?streams='.join('/',@symbols_buf),
      request => '[]',
      on_result => sub { $self->process_ticker(@_) },
      on_error  => sub { $self->common_error(@_) },
      reconnect_on_finish => 1,
  );  
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://api.binance.com/api/v1/ticker/24hr',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
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

  my $res;
  my $status;
  my $stat_date = time;

  if (defined $ws_data) {
    $ws_data = decode_json $ws_data;
    #print  '>>>>>>>>>>>> ' .Dumper $ws_data if $ENV{DEBUG_WS};
    if ('HASH' eq ref $ws_data && $ws_data->{stream} && $ws_data->{stream} =~'@ticker$') {
      my $d = $ws_data->{data};
      # {"stream":"dashbtc@ticker","data":{"e":"24hrTicker","E":151 774 952 9 612,"s":"DASHBTC","p":"-0.00092300","P":"-1.353","w":"0.06915072","x":"0.06790100","c":"0.06727600","Q":"0.12000000","b":"0.06734700","B":"1.75900000","a":"0.06786100","A":"0.12000000","o":"0.06819900","h":"0.07399900","l":"0.06628100","v":"5069.54700000","q":"350.56283980","O":1517663129612,"C":1517749529612,"F":1399263,"L":1416024,"n":16762}}
      $res = [{
        symbol => $d->{s},
        bidPrice => $d->{b},
        askPrice => $d->{a},
        openPrice => $d->{o},
        prevClosePrice => $d->{x},
        lowPrice => $d->{l},
        highPrice => $d->{h},
        weightedAvgPrice => $d->{w},
        count => $d->{n},
        quoteVolume => $d->{q},
      }];
      $stat_date = sprintf($d->{E} - $d->{E}%1000)/1000;
    } else {
      return;
    }
  } else {
    $res     = $tx->result->json;
    $status  = 0;
  }


  foreach my $d (@$res) {
    $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $d->{symbol},
      status		=> $status,
      date_ts		=> $stat_date,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $d->{bidPrice},
      lowest_ask	=> $d->{askPrice},
      opening_price	=> $d->{openPrice},
      closing_price	=> $d->{prevClosePrice}, 
      min_price		=> $d->{lowPrice},
      max_price		=> $d->{highPrice},
      average_price	=> $d->{weightedAvgPrice},
      units_traded	=> $d->{count},
      volume_1day	=> $d->{quoteVolume},
      volume_7day	=> undef, #$d->{volume_7day}, 
    );
  }

  return 1;
}









sub _get_symbols {
  my $self = shift;

  my $new_result;
  my $result = $self->ua->get($self->api('public').'/exchangeInfo')->result->json->{symbols};
  
  foreach (@$result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_->{symbol});
    push @{$new_result}, {id => $_->{symbol}};
  }
  
  return $new_result;
}





2;


