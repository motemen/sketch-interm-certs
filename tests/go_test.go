package main

import (
	"testing"

	"crypto/tls"
	"crypto/x509"
	"errors"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"time"
)

func buildTransportWithIntermCertsFullChain() http.RoundTripper {
	rootCAs, err := x509.SystemCertPool()
	if err != nil {
		log.Fatal(err)
	}

	intermPEM, err := ioutil.ReadFile("/opt/intermediate-certs/ca-bundle.crt")
	if err != nil {
		log.Fatal(err)
	}

	return &http.Transport{
		DialTLS: func(network, addr string) (net.Conn, error) {
			host, _, err := net.SplitHostPort(addr)
			if err != nil {
				return nil, err
			}

			conf := &tls.Config{
				InsecureSkipVerify: true,
				VerifyPeerCertificate: func(rawCerts [][]byte, verifiedChains [][]*x509.Certificate) error {

					// https://github.com/golang/go/blob/go1.14.4/src/crypto/tls/handshake_client.go#L793
					certs := make([]*x509.Certificate, len(rawCerts))
					for i, asn1Data := range rawCerts {
						cert, err := x509.ParseCertificate(asn1Data)
						if err != nil {
							return errors.New("tls: failed to parse certificate from server: " + err.Error())
						}
						certs[i] = cert
					}

					opts := x509.VerifyOptions{
						Roots:         rootCAs,
						CurrentTime:   time.Now(),
						DNSName:       host,
						Intermediates: x509.NewCertPool(),
					}
					for _, cert := range certs[1:] {
						opts.Intermediates.AddCert(cert)
					}

					opts.Intermediates.AppendCertsFromPEM(intermPEM)
					_, err = certs[0].Verify(opts)

					return err
				},
			}

			return tls.Dial(network, addr, conf)
		},
	}
}

func buildTransportWithIntermCertsParialChain() http.RoundTripper {
	rootCAs, err := x509.SystemCertPool()
	if err != nil {
		log.Fatal(err)
	}

	intermPEM, err := ioutil.ReadFile("/opt/intermediate-certs/ca-bundle.crt")
	if err != nil {
		log.Fatal(err)
	}

	rootCAs.AppendCertsFromPEM(intermPEM)

	return &http.Transport{
		TLSClientConfig: &tls.Config{
			RootCAs: rootCAs,
		},
	}
}

func testHostOK(t *testing.T, client *http.Client, host string) {
	t.Helper()

	_, err := client.Get("https://" + host)
	if err != nil {
		t.Error(err)
	}
}

func testHostNG(t *testing.T, client *http.Client, host string) {
	t.Helper()

	_, err := client.Get("https://" + host)
	if err == nil {
		t.Errorf("must error: %s", host)
	}
}

func TestDefaultClient(t *testing.T) {
	client := &http.Client{}
	testHostOK(t, client, "example.com")
	testHostNG(t, client, "incomplete-chain.badssl.com")
	testHostNG(t, client, "localhost")
}

func TestFullChain(t *testing.T) {
	client := &http.Client{
		Transport: buildTransportWithIntermCertsFullChain(),
	}
	testHostOK(t, client, "example.com")
	testHostOK(t, client, "incomplete-chain.badssl.com")
	testHostNG(t, client, "localhost")
}

func TestPartialChain(t *testing.T) {
	client := &http.Client{
		Transport: buildTransportWithIntermCertsParialChain(),
	}
	testHostOK(t, client, "example.com")
	testHostOK(t, client, "incomplete-chain.badssl.com")
	testHostOK(t, client, "localhost")
}
