#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Mojo::mysql;

use Data::Dumper;
use POSIX qw(strftime);
use Try::Tiny;


use Data::Printer;

#use Hash::AutoHash;
use JSON::XS qw{decode_json encode_json};



use Log::Log4perl qw{:easy};

# exchange libs
use lib './lib';
use DataPool::Ticker2;

use Exchange::Bithumb;
use Exchange::HitBtc;
use Exchange::Kraken;
use Exchange::Poloniex;
use Exchange::Binance;
use Exchange::Bittrex;
use Exchange::Bitfinex;
use Exchange::Bitbank;
use Exchange::GDAX;
use Exchange::Okex;

use Exchange::Bitflyer;
use Exchange::Exmo;
use Exchange::Gateio;
use Exchange::Koinex;

use Exchange::Kucoin;
use Exchange::Quoine;
use Exchange::WEX;
use Exchange::CEXIO;
use Exchange::Coinone;
use Exchange::Gemini;
use Exchange::Bitstamp;
use Exchange::Bitz;

use Exchange::BTCBOX;
use Exchange::Btcc;
use Exchange::BTCTurk;
use Exchange::Coinbene;
use Exchange::Gopax;
use Exchange::Korbit;
use Exchange::Lbank;

use Exchange::Livecoin;
use Exchange::Simex;
use Exchange::Sistemkoin;
use Exchange::Upbit;
use Exchange::Vebitcoin;
use Exchange::Zebpay;
use Exchange::OOOBTC;
use Exchange::Yobit;
use Exchange::Liqui;
use Exchange::IDEX;
use Exchange::RightBTC;
use Exchange::ItBit;
use Exchange::Tidex;
use Exchange::ZB;
use Exchange::TradeByTrade;
use Exchange::TopBTC;



# some stuff
$ENV{MOJO_MODE} = "dev";


# init some useful stuff
Log::Log4perl->easy_init({ level => $DEBUG });
my $logger = get_logger();
my $ua  = Mojo::UserAgent->new;
# my $mysql = Mojo::mysql->new('mysql://currency:18today@tickerdb/currency'); # !!TODO: move this config into a separate file, finally! (EM for EM)
my $mysql = Mojo::mysql->new('mysql://root:root@localhost/currency');

my $pTicker = DataPool::Ticker2->new( dbh => $mysql, logger => $logger, bootstrap => 1 );

my $usd_rates = {};
my $exchanges = {};
my $ticker_symbols_filter = {};
my $pool_symbols_filter = {};

my $fetching_state = 0;
my $storing_state = 0;

init();

###################################################

Mojo::IOLoop->recurring(25 => sub { # every 30 seconds
  my $loop = shift;
  ticker30s();
});

Mojo::IOLoop->recurring(20 => sub { # every 20 seconds
  my $loop = shift;
  ticker20s();
});

Mojo::IOLoop->recurring(7200 => sub { # hourly
  my $loop = shift;
  ticker60m();
});


sub init {
  my $db = $mysql->db;
  $db->query(qq|
    select exchange, currency_raw as symbol, concat_ws('-',exchange,currency_raw) as pool_key 
    from exchange_currency_key 
    where currency_in is not null and currency_out is not null 
    order by exchange;
  |)->hashes->map(sub {
    $ticker_symbols_filter->{ $_->{exchange} }->{ $_->{symbol} } = 1;
    $pool_symbols_filter->{ $_->{pool_key} } = 1;
  });


  $pTicker->keys_whitelist($pool_symbols_filter);


  ticker60m(); # get and cache actual echange rates

  # $exchanges->{bithumb}   = Exchange::Bithumb->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bithumb});
  # $exchanges->{hitbtc}    = Exchange::HitBtc->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{hitbtc});
  # $exchanges->{kraken}    = Exchange::Kraken->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{kraken});
  # $exchanges->{poloniex}  = Exchange::Poloniex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{poloniex});
  # $exchanges->{binance}   = Exchange::Binance->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{binance});
  # $exchanges->{bittrex}   = Exchange::Bittrex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bittrex});
  # $exchanges->{bitbank}   = Exchange::Bitbank->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bitbank});
  # $exchanges->{bitfinex}  = Exchange::Bitfinex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bitfinex});
  # $exchanges->{gdax}      = Exchange::GDAX->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{gdax});
  # $exchanges->{okex}      = Exchange::Okex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{okex});
  # $exchanges->{bitflyer}  = Exchange::Bitflyer->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bitflyer});
  # $exchanges->{gateio}    = Exchange::Gateio->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{gateio});
  # $exchanges->{koinex}    = Exchange::Koinex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{koinex});
  # $exchanges->{exmo}      = Exchange::Exmo->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{exmo});
  # $exchanges->{kucoin}    = Exchange::Kucoin->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{kucoin});
  # $exchanges->{quoine}    = Exchange::Quoine->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{quoine});
  # $exchanges->{wex}       = Exchange::WEX->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{wex});
  # $exchanges->{cexio}     = Exchange::CEXIO->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{cexio});
  # $exchanges->{coinone}   = Exchange::Coinone->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{coinone});
  # $exchanges->{gemini}    = Exchange::Gemini->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{gemini});
  # $exchanges->{bitstamp}    = Exchange::Bitstamp->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bitstamp});
  # $exchanges->{bitz}    = Exchange::Bitz->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{bitz});
  # $exchanges->{btcbox}    = Exchange::BTCBOX->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{btcbox});
  # $exchanges->{btcc}    = Exchange::Btcc->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{btcc});
  # $exchanges->{btcturk}    = Exchange::BTCTurk->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{btcturk});
  # $exchanges->{coinbene}    = Exchange::Coinbene->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{coinbene});
  # $exchanges->{gopax}    = Exchange::Gopax->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{gopax});
  # $exchanges->{korbit}    = Exchange::Korbit->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{korbit});
  # $exchanges->{lbank}    = Exchange::Lbank->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{lbank});
  # $exchanges->{livecoin}    = Exchange::Livecoin->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{livecoin});
  # $exchanges->{simex}    = Exchange::Simex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{simex});
  # $exchanges->{sistemkoin}    = Exchange::Sistemkoin->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{sistemkoin});
  # $exchanges->{upbit}    = Exchange::Upbit->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{upbit});
  # $exchanges->{vebitcoin}    = Exchange::Vebitcoin->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{vebitcoin});
  # $exchanges->{zebpay}    = Exchange::Zebpay->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{zebpay});
  # $exchanges->{ooobtc}    = Exchange::OOOBTC->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{ooobtc});
  # $exchanges->{yobit}    = Exchange::Yobit->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{yobit});
  # $exchanges->{liqui}    = Exchange::Liqui->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{liqui});
  # $exchanges->{idex}    = Exchange::IDEX->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{idex});
  # $exchanges->{rightbtc}    = Exchange::RightBTC->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{rightbtc});
  # $exchanges->{itbit}    = Exchange::ItBit->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{itbit});
  # $exchanges->{tidex}    = Exchange::Tidex->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{tidex});
  # $exchanges->{zb}    = Exchange::ZB->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{zb});
  $exchanges->{topbtc}    = Exchange::TopBTC->new(ua => $ua, logger => $logger, usd_rates => $usd_rates, pool => $pTicker, symbols_filter => $ticker_symbols_filter->{topbtc});


}


sub ticker20s {
  $logger->info("Storing data/20 (".$pTicker->count." keys, ".$pTicker->updated_count." updated)");
  $pTicker->store();
}


sub ticker30s {
  $logger->info("Fetching data/30");
  return if $fetching_state == 1;
  $fetching_state = 1;
  foreach my $t (keys %$exchanges) {
    $logger->info( "processing $t" );
    if ($exchanges->{$t}->can_wsock('ticker') && !$exchanges->{$t}->ws_ticker_subscriptions) {
      # subscribe/resubscribe to ws ticker feed
      eval {
        $exchanges->{$t}->ticker_ws; # from now on, the exchange module should handle subscription to all symbols itself (GDAX inspired change) - EM 20180202
      };
    } elsif ($exchanges->{$t}->can_rest &&! $exchanges->{$t}->ws_ticker_subscriptions) {
      # fetch rest tickers
      eval {
        $exchanges->{$t}->ticker();    
      };
    } else {
      # do nothing, we still have active subscriptions there
      $logger->info($t." has ".$exchanges->{$t}->ws_ticker_subscriptions." active subscriptions");
    }
  }
  $fetching_state = 0;
}

sub ticker60m {
  $logger->info("Fetching exchange rates/3600");
  $ua->get('https://api.fixer.io/latest?base=USD' => \&process_exchange_rates );
}

sub ticker10s {
}

sub process_exchange_rates {
  my ($ua, $tx) = @_;
  my $res   	= $tx->result->json;

  my $base 	= $res->{base};
  my $stat_date = $res->{date};

  foreach my $c (keys %{$res->{rates}}) {
    $mysql->db->query('insert into exchange_rates values (?, ?, now(),  ?, ?, ?, ?)', 
      undef, 'fixer.io', $base, $c, $stat_date, $res->{rates}->{$c},
    );
    $usd_rates->{$c} = $res->{rates}->{$c};
  }
}

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
