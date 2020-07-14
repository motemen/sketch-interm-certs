.PHONY: all
all: build/leaf.pem

.PHONY: clean
clean:
	rm -f build/*.pem build/*.csr

build/root-ca.pem:
	@mkdir -p build
	cfssl gencert -initca root-ca.json | cfssljson -bare build/root-ca

build/interm-ca.pem: build/root-ca.pem
	cfssl gencert -initca interm-ca.json | cfssljson -bare build/interm-ca
	cfssl sign -ca build/root-ca.pem -ca-key build/root-ca-key.pem -config config.json -profile interm build/interm-ca.csr | cfssljson -bare build/interm-ca

build/leaf.pem: build/interm-ca.pem
	cfssl gencert -ca build/interm-ca.pem -ca-key build/interm-ca-key.pem -config config.json -profile leaf leaf.json | cfssljson -bare build/leaf
