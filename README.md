# hybridhive smart contracts

Frontend application: https://github.com/markfender/hybridhive-app

hybridhive is a protocol which increases the economic power, sovereignty & liquidity of communities by connecting their tokens to each other

They are connected to a so-called “hive”. Being part of the hive gives communities the combined power that transcends individual tokens. This leads to increased liquidity, price-stability and lower exchange fees for the communities inside the hives

## Run the project locally

1. Install general dependancies:

```
yarn
```

2. Run local hardhat node with:

```
npx hardhat node
```

3. Deploy the contract to the local environment

```
npx hardhat run ./scripts/index.js --network hardhat
```

## Deploy contract

1. Run the tests to verify that everything works as excpected:

```
npx hardhat test
```

2. Deploy contracts to the desiered network. *Please note that the default deploy script sets up some tokens and aggregators by default.*

```
npx hardhat run ./scripts/index.js --network SOME_NETWORK
```
