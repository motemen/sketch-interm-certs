#!/usr/bin/env bats

test_host_ok() {
    openssl s_client -CApath /etc/ssl/certs -quiet -verify_quiet -no_ign_eof -verify_return_error -connect "$@" < /dev/null 2>&1
}

test_host_ng() {
    if test_host_ok "$@"; then
        return 1
    else
        return 0
    fi
}

@test "ok: example.com" {
    test_host_ok example.com:443
}

@test "ng: incomplete-chain.badssl.com" {
    test_host_ng incomplete-chain.badssl.com:443
}

@test "ng: self-signed site" {
    test_host_ng localhost:443
}

@test "ok: with intermediate certificates example.com" {
    test_host_ok example.com:443 -CAfile /opt/intermediate-certs/ca-bundle.crt
}

@test "ok: with intermediate certificates incomplete-chain.badssl.com" {
    test_host_ok incomplete-chain.badssl.com:443 -CAfile /opt/intermediate-certs/ca-bundle.crt
}

@test "ng: with intermediate certificates self-signed site" {
    test_host_ng localhost:443 -CAfile /opt/intermediate-certs/ca-bundle.crt
}

@test "ok: with intermediate certificates and -partial_chain example.com" {
    test_host_ok example.com:443 -CAfile /opt/intermediate-certs/ca-bundle.crt -partial_chain
}

@test "ok: with intermediate certificates and -partial_chain incomplete-chain.badssl.com" {
    test_host_ok incomplete-chain.badssl.com:443 -CAfile /opt/intermediate-certs/ca-bundle.crt -partial_chain
}

@test "ok: with intermediate certificates and -partial_chain self-signed site" {
    test_host_ok localhost:443 -CAfile /opt/intermediate-certs/ca-bundle.crt -partial_chain
}
