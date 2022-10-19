# Identidade Empresarial Digital - Contracts
Example contract codes for the Lift Learning DeFi/Web3 course. 

This example project uses [Foundry](https://getfoundry.sh/) as the development framework.

## Install dependencies

 ```
 git submodule update --init --recursive
 ```

## Compile

```
forge build
```

## Test

```
forge test
```

## Configure and run local testnet
Create the `.env` file with the RPC endpoint and issuer private key.

```bash
RPC_URL_ANVIL=http://localhost:8545

ISSUER_PRIVATE_KEY=XXX
```

Start anvil:

```
anvil
```

## Deploy the Credential contract

```
forge script script/Credential.s.sol:CredentialScript -f anvil --broadcast
```