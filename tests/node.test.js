const fetch = require("node-fetch");
const https = require("https");
const fs = require("fs");
const env = require("process").env;

const withExtraCACerts = !!env["NODE_EXTRA_CA_CERTS"];

describe(
  "default agent" + (withExtraCACerts ? " with NODE_EXTRA_CA_CERTS" : ""),
  () => {
    const agent = new https.Agent({});

    test("ok: www.example.com", async () => {
      await expect(
        fetch("https://www.example.com", { agent })
      ).resolves.toEqual(expect.anything());
    });

    if (withExtraCACerts) {
      test("ok: incomplete-chain.badssl.com", async () => {
        await expect(
          fetch("https://incomplete-chain.badssl.com", { agent })
        ).resolves.toEqual(expect.anything());
      });
    } else {
      test("ng: incomplete-chain.badssl.com", async () => {
        await expect(
          fetch("https://incomplete-chain.badssl.com", { agent })
        ).rejects.toThrow();
      });
    }

    test("ng: localhost", async () => {
      await expect(fetch("https://localhost", { agent })).rejects.toThrow();
    });
  }
);

describe("with intermediate certificates", () => {
  const agent = new https.Agent({
    ca: [
      fs.readFileSync("/etc/ssl/certs/ca-certificates.crt"),
      fs.readFileSync("/opt/intermediate-certs/ca-bundle.crt")
    ]
  });

  test("ok: www.example.com", async () => {
    await expect(fetch("https://www.example.com", { agent })).resolves.toEqual(
      expect.anything()
    );
  });

  test("ok: incomplete-chain.badssl.com", async () => {
    await expect(
      fetch("https://incomplete-chain.badssl.com", { agent })
    ).resolves.toEqual(expect.anything());
  });

  test("ng: localhost", async () => {
    await expect(fetch("https://localhost", { agent })).rejects.toThrow(
      "reason: unable to get issuer certificate"
    );
  });
});
