const { aggregatorsConfig, tokensConfig } = require("../configs");
const { FN, BN } = require("../constants");
// @todo fix `cannot estimate gas; transaction may fail or may require manual gas limit` error on real deploy
const setupInitState = async (mainAccount, accounts) => {
  // Contracts are deployed using the first signer/account by default
  console.log(`Deployer account address: ${mainAccount}`);
  const TokenMockFactory = await ethers.getContractFactory("TokenMock");
  const HybridHiveCoreFactory = await ethers.getContractFactory(
    "HybridHiveCore"
  );
  const AggregatorOperatorFactory = await ethers.getContractFactory(
    "AggregatorOperatorMock"
  );
  const TokenOperatorFactory = await ethers.getContractFactory(
    "TokenOperatorMock"
  );

  const HybridHiveCore = await HybridHiveCoreFactory.deploy();
  await HybridHiveCore.deployTransaction.wait();
  console.log(
    `Core hybridhive contract is deployed to: ${HybridHiveCore.address}`
  );

  const AggregatorOperator = await AggregatorOperatorFactory.deploy();
  await AggregatorOperator.deployTransaction.wait();

  let tx = await AggregatorOperator.setCoreAddress(HybridHiveCore.address);
  await tx.wait();
  console.log(
    `Aggregator operator hybridhive contract is deployed to: ${AggregatorOperator.address}`
  );

  const TokenOperator = await TokenOperatorFactory.deploy();
  await TokenOperator.deployTransaction.wait();

  tx = await TokenOperator.setCoreAddress(HybridHiveCore.address);
  await tx.wait();

  console.log(
    `Token operator hybridhive contract is deployed to: ${TokenOperator.address}`
  );

  //@todo move such functions to helpers folder
  const createNewToken = async (tokenName, tokenSymbol, recipients) => {
    const newToken = await TokenMockFactory.deploy(tokenName, tokenSymbol, 0);
    await newToken.deployTransaction.wait();
    for (recipient of recipients) {
      tx = await newToken.mint(recipient.address, recipient.amount);
      await tx.wait();
    }
    return newToken;
  };

  let tokensList = [];

  for (tokenConfig of tokensConfig(mainAccount, accounts)) {
    const newToken = await createNewToken(
      tokenConfig.name,
      tokenConfig.symbol,
      tokenConfig.holders
    );
    tokensList.push(newToken);
  }

  console.log("All test tokens are deployed");

  const createNewAggregator = async (
    aggregatorName,
    aggregatorSymbol,
    subEntitiesType,
    subEntities,
    aggregatorId
  ) => {
    const subEntitiesWeigths = subEntities.map((entity) => entity.weigth);
    let subEntitiesIds =
      subEntitiesType == 1
        ? subEntities.map((entity) =>
            BN(tokensList[entity.id - 1].address).toString()
          )
        : subEntities.map((entity) => entity.id);

    tx = await HybridHiveCore.createAggregator(
      aggregatorName, // _aggregatorName
      aggregatorSymbol, // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      subEntitiesType,
      subEntitiesIds, // _aggregatedEntities
      subEntitiesWeigths // _aggregatedEntitiesWeights
    );
    await tx.wait();
    console.log("step 1");
    if (subEntitiesType == 1) {
      for (subEntity of subEntities) {
        const tokenAddress = tokensList[subEntity.id - 1].address;
        tx = await HybridHiveCore.addTokenDetails(
          tokenAddress,
          "",
          TokenOperator.address,
          aggregatorId
        );
        await tx.wait();

        console.log("step 2");

        tx = await tokensList[subEntity.id - 1].transferOwnership(
          HybridHiveCore.address
        );
        await tx.wait();

        console.log("step 3", tokenAddress, aggregatorId);
        tx = await TokenOperator.approveTokenConnection(
          tokenAddress,
          aggregatorId
        );
        await tx.wait();

        console.log("step 4");
        // update aggregator by connecting sub entities
      }
    } else if (subEntitiesType == 2) {
      for (subEntity of subEntities) {
        tx = await AggregatorOperator.addAggregatorDetails(
          aggregatorId,
          subEntity.id,
          "",
          AggregatorOperator.address
        );
        await tx.wait();

        console.log("step 5");
      }
    }
  };

  let aggregatorsCount = 0;
  for (aggregatorConfig of aggregatorsConfig()) {
    await createNewAggregator(
      aggregatorConfig.name,
      aggregatorConfig.symbol,
      aggregatorConfig.subEntitiesType,
      aggregatorConfig.subEntities,
      ++aggregatorsCount
    );
    console.log(`Aggregator ${aggregatorsCount} is deployed`);
  }
  console.log("All test aggregators are created");
  console.log("Demo setup is finshed");

  /* schema to setup as an initial state
    Ag[7]
      Ag[5] 60%
        Ag[1] 30%
          Token[1] 20% 2000
            account[owner] 15% 1500  owner
            account[0] 5% 500
          Token[2] 10%
            account[1] 7% 1400
            account[2] 3% 600
        Ag[2] 30%
          Token[3]30%
            account[3] 30% 500
      Ag[6]40%
        Ag[3] 30%
          Token[4] 15%
            account[4] 9% 999
            account[5] 6% 666
          Token[5] 15%
            account[6] 9% 300
            account[7] 6% 200
        Ag[4] 10%
          Token[6] 10%
            account[8] 10% 300

    */
  /*
    Ag[7]
      Ag[5] 55%
        Ag[1] 25%
          Token[1] 15% 5000
            account[owner] 10% 1000  owner
            account[0] 5% 500
          Token[2] 10%
            account[1] 7% 1400
            account[2] 3% 600
        Ag[2] 30%
          Token[3]30%
            account[3] 30% 500
      Ag[6]45%
        Ag[3] 35%
          Token[4] 15%
            account[4] 9% 999
            account[5] 6% 666
          Token[5] 20%
            account[6] 14% 300
            account[7] 6% 200
        Ag[4] 10%
          Token[6] 10%
            account[8] 10% 300
    */

  return {
    HybridHiveCore,
    tokensList,
    mainAccount,
    accounts,
    createNewToken,
    TokenOperator,
    AggregatorOperator,
  };
};

const toPercentageString = (value) => {
  return FN.fromValue(value.toString(), 18).round(17).toString();
};

module.exports = { setupInitState, toPercentageString };
