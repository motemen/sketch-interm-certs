#!/usr/bin/env perl
use strict;
use warnings;
use LWP::UserAgent;
use Net::SSLeay;
use Test::More;

my $ua_vanilla = LWP::UserAgent->new;
my $ua_with_interm_full_chain = LWP::UserAgent->new(
    ssl_opts => {
        SSL_ca_file => '/opt/intermediate-certs/ca-bundle.crt',
        SSL_ca_path => '/etc/ssl/certs',
        SSL_create_ctx_callback => sub {
            my $ctx = shift;
            my $param = Net::SSLeay::CTX_get0_param($ctx);
            my $rv = Net::SSLeay::X509_VERIFY_PARAM_get_flags($param);
            Net::SSLeay::X509_VERIFY_PARAM_clear_flags($param, Net::SSLeay::X509_V_FLAG_PARTIAL_CHAIN());
            Net::SSLeay::CTX_set1_param($ctx, $param);
        },
    }
);
my $ua_with_interm_partial_chain = LWP::UserAgent->new(
    ssl_opts => {
        SSL_ca_file => '/opt/intermediate-certs/ca-bundle.crt',
        SSL_ca_path => '/etc/ssl/certs',
    }
);

sub test {
    my ($ok, $ua, $host) = @_;
    my $res = $ua->get($host);
    is !!$res->is_success, !!$ok, ($ok ? 'ok' : 'ng') . " $host"
        or diag $res->status_line;
}

sub test_ok { unshift @_, 1; goto &test }
sub test_ng { unshift @_, 0; goto &test }

subtest 'Vanilla UA' => sub {
    test_ok $ua_vanilla, 'https://www.example.com/';
    test_ng $ua_vanilla, 'https://incomplete-chain.badssl.com/';
    test_ng $ua_vanilla, 'https://localhost/';
};

subtest 'UA with intermediate certificates full chain' => sub {
    test_ok $ua_with_interm_full_chain, 'https://www.example.com/';
    test_ok $ua_with_interm_full_chain, 'https://incomplete-chain.badssl.com/';
    test_ng $ua_with_interm_full_chain, 'https://localhost/';
};

subtest 'UA with intermediate certificates partial chain' => sub {
    test_ok $ua_with_interm_partial_chain, 'https://www.example.com/';
    test_ok $ua_with_interm_partial_chain, 'https://incomplete-chain.badssl.com/';
    test_ok $ua_with_interm_partial_chain, 'https://localhost/';
};

done_testing;
