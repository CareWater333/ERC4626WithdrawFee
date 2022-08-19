# ERC4626 Withdraw Fee - enable fees on any ERC4626 portfolio

A nearly drop-in implementation of ERC4626 that enables fees for any portfolio. Simply substitute this for ERC4626 and set your fee and fee address in the constructor, and *tada* you're charging withdrawal fees.

# Overview

Withdrawal fees are nice because they reward long-term holders with lower overall fees while discouraging jumping in and out. Also, it's nice as a vault manager to get paid.

This implementation sets the fee address and amount in the constructor, but if you have access control of some type enabled, it's easy to add setters for the treasury address and fee amount (examples are in comments in the code).

# Usage

Set `.env` and run `npx hardhat node` then `npx hardhat run scripts/VaultWithFeeExample.ts --network localhost`

### Prerequisites

Before running any command, make sure to install dependencies:

```sh
$ npx hardhat
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ npx hardhat compile
```

### Test

Run the tests (comimg soon):

```sh
$ npx hardhat test
```

### Deploy contract to netowrk (requires private key and Alchemy API key)

```
npx hardhat run --network goerli ./scripts/deploy.ts
```

### Validate a contract with etherscan (requires API key)

```
npx hardhat verify --network <network> <DEPLOYED_CONTRACT_ADDRESS>
```
