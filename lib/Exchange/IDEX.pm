package Exchange::IDEX;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'idex',
            'name' => 'IDEX',
            'countries' => 'PA', 
            'rateLimit' => 500, # no info
            'base_currency' => 'PAB',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => '',
                'api' => 'https://api.idex.market/',
                'www' => 'https://idex.market/',
                'doc' => 'https://github.com/AuroraDAO/idex-api-docs',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.2 / 100,
                    'taker' => 0.2 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->post(
    url => 'https://api.idex.market/returnTicker',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currencies  	= $tx->result->json;

  foreach my $c (keys %{$currencies}) {
    my $d = $currencies->{$c};
    if ($d->{last} ne 'N/A')
    {
      $self->store_ticker(
        source    => $self->config->{id},
        currency    => $c,
        status    => 0, # proper status for the ticker w/o errors
        date_ts   => time,
        base_currency   => $self->config->{base_currency},
        base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid => $d->{highestBid} eq 'N/A' ? 0 : $d->{last},
        lowest_ask  => $d->{lowestAsk} eq 'N/A' ? 0 : $d->{last},
        opening_price => 0,
        closing_price => $d->{last} eq 'N/A' ? 0 : $d->{last},
        min_price   => $d->{high} eq 'N/A' ? 0 : $d->{high},
        max_price   => $d->{low} eq 'N/A' ? 0 : $d->{low},
        average_price => 0,
        units_traded  => 0,
        volume_1day => $d->{baseVolume} eq 'N/A' ? 0 : $d->{baseVolume},
        volume_7day => 0, 
      );
    }
  }

  return 1;
}

2;


