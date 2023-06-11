const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

const { aggregatorsConfig, tokensConfig } = require("../scripts/configs");
const { BN, DECIMALS } = require("../scripts/constants");

const { setupInitState, toPercentageString } = require("../scripts/helpers");

/* @todo reorganize test agents, split owner role into different addresses [
  token operator 1,
  token operator 2,
  aggregator operator 1,
  aggregator operator 2,
  user
]
*/

describe("HybridHiveCore", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function initialTestSetup() {
    const [owner, ...accounts] = await ethers.getSigners();
    return await setupInitState(
      owner.address,
      accounts.map((accountObj) => accountObj.address)
    );
  }

  describe("Getter functions", function () {
    it("Should get user token balance correctly", async function () {
      const { HybridHiveCore, tokensList, mainAccount, accounts } =
        await loadFixture(initialTestSetup);
      expect(await tokensList[0].balanceOf(mainAccount)).to.equal(1500);
    });

    it("Should properly calculate global token share", async function () {
      const { HybridHiveCore, tokensList } = await loadFixture(
        initialTestSetup
      );

      let result = await HybridHiveCore[
        "getGlobalValueShare(uint256,address,uint256)"
      ](7, tokensList[0].address, 1500);

      expect(toPercentageString(result)).to.equal("0.15");

      result = await HybridHiveCore[
        "getGlobalValueShare(uint256,uint8,uint256,uint256)"
      ](7, 2, 1, DECIMALS.div(10));

      expect(toPercentageString(result)).to.equal("0.03");
    });

    it("Should properly calculate global aggregator share", async function () {
      const { HybridHiveCore } = await loadFixture(initialTestSetup);

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(6, 3))
      ).to.equal("0.75");

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(7, 1))
      ).to.equal("0.3");

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(7, 6))
      ).to.equal("0.4");

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(7, 4))
      ).to.equal("0.1");
    });

    it("Should properly convert global share into spesific tokens amount", async function () {
      const { HybridHiveCore, tokensList } = await loadFixture(
        initialTestSetup
      );

      expect(
        await HybridHiveCore[
          "getAbsoluteAmountFromShare(uint256,address,uint256)"
        ](7, tokensList[0].address, DECIMALS.div(10))
      ).to.equal("1000");

      expect(
        await HybridHiveCore[
          "getAbsoluteAmountFromShare(uint256,address,uint256)"
        ](7, tokensList[1].address, DECIMALS.mul(3).div(100))
      ).to.equal("600");

      expect(
        await HybridHiveCore[
          "getAbsoluteAmountFromShare(uint256,address,uint256)"
        ](7, tokensList[2].address, DECIMALS.mul(3).div(100))
      ).to.equal("50");
    });

    it("Should properly get root aggregator in the network", async function () {
      const { HybridHiveCore } = await loadFixture(initialTestSetup);

      expect(await HybridHiveCore.getRootAggregator(3)).to.equal(7);
    });
  });

  describe("Сonnecting entities", function () {
    it("Should connect token to the aggregator", async function () {
      const {
        HybridHiveCore,
        mainAccount,
        createNewToken,
        TokenOperator,
        AggregatorOperator,
      } = await loadFixture(initialTestSetup);

      const newToken = await createNewToken("TestToken", "TT", [
        {
          address: mainAccount,
          amount: 1500,
        },
      ]);
      const parentAggregatorId = 1; // @todo recheck that it is impossible to connect token to operator
      await AggregatorOperator.addSubEntity(
        parentAggregatorId,
        BN(newToken.address),
        DECIMALS
      );

      await HybridHiveCore.addTokenDetails(
        newToken.address,
        "",
        TokenOperator.address,
        parentAggregatorId
      );

      await newToken.transferOwnership(HybridHiveCore.address);

      await TokenOperator.approveTokenConnection(
        newToken.address,
        parentAggregatorId
      );

      let result = await HybridHiveCore[
        "getGlobalValueShare(uint256,address,uint256)"
      ](7, newToken.address, 1700);

      expect(toPercentageString(result)).to.equal("0.17");
    });
  });

  describe("Transfers", function () {
    it("Should properly commit the global transfer", async function () {
      const { HybridHiveCore, tokensList, mainAccount, accounts } =
        await loadFixture(initialTestSetup);

      const secondSender = await ethers.getSigner(accounts[6]);

      async function logNetworkTree(rootAggregator, space, globalRoot) {
        const str = new Array(space + 1).join("-");

        if (!globalRoot) globalRoot = rootAggregator;
        let subEntities = await HybridHiveCore.getAggregatorSubEntities(
          rootAggregator
        );
        const aggregatorParent = await HybridHiveCore.getAggregatorParent(
          rootAggregator
        );
        if (aggregatorParent == 0)
          console.log(rootAggregator, ` - global share 100%`);

        for (entityId of subEntities[1]) {
          if (subEntities[0] == 2) {
            const shareOfEntity = await HybridHiveCore.getGlobalAggregatorShare(
              globalRoot,
              entityId
            );
            const totalSupply = await HybridHiveCore.getTotalSupply(
              subEntities[0],
              entityId
            );
            console.log(
              str,
              entityId,
              ` - global share: ${shareOfEntity} (${totalSupply})`
            );

            await logNetworkTree(entityId, space + 2, globalRoot);
          } else {
            const totalSupply = await HybridHiveCore.getTotalSupply(
              subEntities[0],
              entityId
            );
            const shareOfEntity = await HybridHiveCore.getGlobalValueShare(
              globalRoot,
              1,
              entityId,
              totalSupply
            );
            console.log(
              "---- ",
              entityId,
              ` - global share: ${shareOfEntity}  (${totalSupply})`
            );
          }
        }
      }

      async function logAccountGlobalBalance(accountAddress, tokenData) {
        const getUsetBalance = await tokenData.balanceOf(accountAddress);
        const globalTokenShare = await HybridHiveCore[
          "getGlobalValueShare(uint256,address,uint256)"
        ](7, tokenData.address, getUsetBalance);
        console.log(accountAddress, getUsetBalance, globalTokenShare);
      }

      await logAccountGlobalBalance(mainAccount, tokensList[0]);
      await logAccountGlobalBalance(accounts[6], tokensList[4]);

      let tx = await HybridHiveCore.globalTransfer(
        BN(tokensList[0].address),
        BN(tokensList[4].address),
        mainAccount,
        accounts[6],
        500
      );
      tx.wait();
      tx = await HybridHiveCore.connect(secondSender).globalTransfer(
        BN(tokensList[4].address),
        BN(tokensList[0].address),
        accounts[6],
        mainAccount,
        166
      );
      tx.wait();

      await logAccountGlobalBalance(mainAccount, tokensList[0]);
      await logAccountGlobalBalance(accounts[6], tokensList[4]);
    });
  });
});
