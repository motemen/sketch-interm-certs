This is a study repository which examines how to get HTTPS sites which are valid except lacking intermediate certificates, while correctly fail to get sites which are backed by self-signed certificates.

Running tests
-------------

    % make -C self-signed
    % docker-compose up -d # and wait for service to be up
    % docker-compose exec main ./tests/run

Above script does:

 * Create self-signed root CA, then intermediate and leaf certificates signed by the root
 * Create a Docker image which contains:
   * A bundle of trusted intermediate certificates from [Common CA Database](https://www.ccadb.org/)
   * The self-signed intermediate certificate but without the self-signed root
 * Start a local HTTPS server with self-signed intermediate certificate
 * Test for each language (openssl client, Perl, Go and Node):
   * that an HTTPS site correctly configured can be got right
   * that an HTTPS site missing intermediate certificate can be got right with local trusted intermediate certificate
   * that an HTTPS site backed by self-signed CA cannot be got right even with local self-signed intermediate certificate (full chain verification)
     * optionally, test partial chain verification
