const { FN, BN, DECIMALS } = require("../constants");

const accounts = [
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
  "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
  "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
  "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
  "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
  "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
  "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
  "0xBcd4042DE499D14e55001CcbB24a551F3b954096",
  "0x71bE63f3384f5fb98995898A86B02Fb2426c5788",
  "0xFABB0ac9d68B0B445fB7357272Ff202C5651694a",
  "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec",
  "0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097",
  "0xcd3B766CCDd6AE721141F452C550Ca635964ce71",
  "0x2546BcD3c84621e976D8185a91A922aE77ECEc30",
  "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E",
  "0xdD2FD4581271e230360230F9337D5c0430Bf44C0",
  "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",
];

const aggregatorsConfig = () => {
  return [
    {
      name: "Aggregator[1]",
      symbol: "AG[1]",
      subEntitiesType: 1,
      subEntities: [
        {
          id: 1,
          weigth: DECIMALS.mul(2).div(3),
        },
        {
          id: 2,
          weigth: DECIMALS.div(3),
        },
      ],
    },
    {
      name: "Aggregator[2]",
      symbol: "AG[2]",
      subEntitiesType: 1,
      subEntities: [
        {
          id: 3,
          weigth: DECIMALS,
        },
      ],
    },
    {
      name: "Aggregator[3]",
      symbol: "AG[3]",
      subEntitiesType: 1,
      subEntities: [
        {
          id: 4,
          weigth: DECIMALS.div(2),
        },
        {
          id: 5,
          weigth: DECIMALS.div(2),
        },
      ],
    },
    {
      name: "Aggregator[4]",
      symbol: "AG[4]",
      subEntitiesType: 1,
      subEntities: [
        {
          id: 6,
          weigth: DECIMALS,
        },
      ],
    },
    {
      name: "Aggregator[5]",
      symbol: "AG[5]",
      subEntitiesType: 2,
      subEntities: [
        {
          id: 1,
          weigth: DECIMALS.div(2),
        },
        {
          id: 2,
          weigth: DECIMALS.div(2),
        },
      ],
    },
    {
      name: "Aggregator[6]",
      symbol: "AG[6]",
      subEntitiesType: 2,
      subEntities: [
        {
          id: 3,
          weigth: DECIMALS.mul(3).div(4),
        },
        {
          id: 4,
          weigth: DECIMALS.div(4),
        },
      ],
    },
    {
      name: "Aggregator[7]",
      symbol: "AG[7]",
      subEntitiesType: 2,
      subEntities: [
        {
          id: 5,
          weigth: DECIMALS.mul(3).div(5),
        },
        {
          id: 6,
          weigth: DECIMALS.mul(2).div(5),
        },
      ],
    },
  ];
};

const tokensConfig = (mainAccount, accounts) => {
  return [
    {
      name: "Token[1]",
      symbol: "TKN[1]",
      holders: [
        {
          address: mainAccount,
          amount: 1500,
        },
        {
          address: accounts[1],
          amount: 500,
        },
      ],
    },
    {
      name: "Token[2]",
      symbol: "TKN[2]",
      holders: [
        {
          address: accounts[1],
          amount: 1400,
        },
        {
          address: accounts[2],
          amount: 600,
        },
      ],
    },
    {
      name: "Token[3]",
      symbol: "TKN[3]",
      holders: [
        {
          address: accounts[3],
          amount: 500,
        },
      ],
    },
    {
      name: "Token[4]",
      symbol: "TKN[4]",
      holders: [
        {
          address: accounts[4],
          amount: 999,
        },
        {
          address: accounts[5],
          amount: 666,
        },
      ],
    },
    {
      name: "Token[5]",
      symbol: "TKN[5]",
      holders: [
        {
          address: accounts[6],
          amount: 300,
        },
        {
          address: accounts[7],
          amount: 200,
        },
      ],
    },
    {
      name: "Token[6]",
      symbol: "TKN[6]",
      holders: [
        {
          address: accounts[8],
          amount: 300,
        },
      ],
    },
  ];
};

module.exports = { aggregatorsConfig, tokensConfig };
