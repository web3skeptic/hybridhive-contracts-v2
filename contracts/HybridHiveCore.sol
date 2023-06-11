// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {UD60x18, convert} from "@prb/math/src/UD60x18.sol";

import "./interfaces/IHybridHiveCore.sol";
import "./modules/HybridHiveGeneralGetters.sol";

// @todo replace it with an interface
import "./mocks/TokenMock.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract HybridHiveCore is IHybridHiveCore, HybridHiveGeneralGetters {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*
        @todo
        1. add events and event emiting
        2. create error codes
        3. avoid circles in the tree
        4. recheck all access rights
        5. add tokens decimals
        6. try to make tokens erc1155 compatible
    */

    //MODIFIER

    modifier onlyOperator(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            //require(_tokenSet.contains(_entityId));
            require(_tokensData[_entityId].operator == msg.sender);
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            require(_aggregatorIds.contains(_entityId));
            require(_aggregatorsData[_entityId].operator == msg.sender);
        } else revert("Unknown entity type");

        _;
    }

    function mintToken(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public onlyOperator(IHybridHiveCore.EntityType.TOKEN, _tokenId) {
        address tokenAddress = address(uint160(_tokenId));
        TokenMock(tokenAddress).mint(_account, _amount);
    }

    function burnToken(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public onlyOperator(IHybridHiveCore.EntityType.TOKEN, _tokenId) {
        address tokenAddress = address(uint160(_tokenId));
        TokenMock(tokenAddress).burn(_account, _amount);
    }

    function createAggregator(
        string memory _aggregatorName,
        string memory _aggregatorSymbol,
        string memory _aggregatorURI,
        address _aggregatorOperator, // @todo FOR future implementaionsЖcheck if it has appropriabe fields like `delegate`
        uint256 _parentAggregator,
        IHybridHiveCore.EntityType _aggregatedEntityType,
        uint256[] memory _aggregatedEntities, // @todo add validation _aggregatedEntities.len == _aggregatedEntitiesWeights.len
        uint256[] memory _aggregatedEntitiesWeights // @todo should be equal to denminator
    ) public returns (uint256) {
        // @todo allow creation of aggregators only to operatos
        // @todo add validations
        require(_aggregatorOperator != address(0));
        require(
            _aggregatedEntities.length == _aggregatedEntitiesWeights.length
        );

        uint256 newAggregatorId = _aggregatorIds.length() + 1;
        assert(!_aggregatorIds.contains(newAggregatorId)); // there should be no such aggregator id
        _aggregatorIds.add(newAggregatorId);

        IHybridHiveCore.AggregatorData storage newAggregator = _aggregatorsData[
            newAggregatorId
        ]; // skip the first token index
        newAggregator.name = _aggregatorName;
        newAggregator.symbol = _aggregatorSymbol;
        newAggregator.uri = _aggregatorURI;
        newAggregator.operator = _aggregatorOperator; // @todo creator operator should be set as operator by default
        newAggregator.parentAggregator = _parentAggregator;
        newAggregator.aggregatedEntityType = _aggregatedEntityType;

        for (uint256 i = 0; i < _aggregatedEntitiesWeights.length; i++) {
            _addSubEntities(
                newAggregatorId,
                _aggregatedEntities[i],
                _aggregatedEntitiesWeights[i]
            );
        }

        _aggregatorsData[newAggregatorId].totalWeight = 0;

        return newAggregatorId;
    }

    function _addSubEntities(
        uint256 _parentAggregatorId,
        uint256 _entityId,
        uint256 _weight
    ) internal {
        _weights[_parentAggregatorId][_entityId] = _weight;
    }

    // GENERAL FUCNCTIONS
    // @todo REWORK IT
    // @todo what if few aggregatorks added token
    function addTokenDetails(
        address _tokenAddress,
        string memory _tokenURI,
        address _tokenOperator,
        uint256 _parentAggregatorId
    ) public {
        require(_tokenOperator != address(0));
        // @todo verify that there is such function
        // @todo move to modifier
        require(msg.sender == TokenMock(_tokenAddress).owner());
        uint256 tokenId = uint256(uint160(_tokenAddress));

        IHybridHiveCore.TokenData storage newToken = _tokensData[tokenId]; // skip the first token index
        newToken.uri = _tokenURI;
        newToken.operator = _tokenOperator;
        newToken.parentAggregator = _parentAggregatorId;
    }

    function approveTokenConnection(
        address _tokenAddress,
        uint256 _parentAggregatorId
    )
        public
        onlyOperator(
            IHybridHiveCore.EntityType.TOKEN,
            uint256(uint160(_tokenAddress))
        )
    {
        require(address(this) == TokenMock(_tokenAddress).owner());
        uint256 tokenId = uint256(uint160(_tokenAddress));

        require(_tokenSet.add(tokenId));
        require(_subEntities[_parentAggregatorId].add(tokenId));

        _tokensData[tokenId].parentAggregator = _parentAggregatorId;

        _aggregatorsData[_parentAggregatorId].totalWeight += _weights[
            _parentAggregatorId
        ][tokenId];
    }

    function deleteTokenConnection(
        uint256 _parentAggregatorId,
        address _tokenAddress,
        address _newTokenOwner
    )
        public
        onlyOperator(
            IHybridHiveCore.EntityType.TOKEN,
            uint256(uint160(_tokenAddress))
        )
    {
        require(address(this) == TokenMock(_tokenAddress).owner());
        uint256 tokenId = uint256(uint160(_tokenAddress));

        require(_tokenSet.remove(tokenId));
        require(_subEntities[_parentAggregatorId].remove(tokenId));

        _tokensData[tokenId].parentAggregator = 0;
        _weights[_parentAggregatorId][tokenId] = 0;
        _aggregatorsData[_parentAggregatorId].totalWeight -= _weights[
            _parentAggregatorId
        ][tokenId];

        TokenMock(_tokenAddress).transferOwnership(_newTokenOwner);
    }

    // @todo recheck if it is sufficient to approve tokens connection
    function addAggregatorDetails(
        uint256 _parentAggregatorId,
        uint256 _aggregatorId,
        string memory _aggregatorURI,
        address _aggregatorOperator
    )
        public
        onlyOperator(IHybridHiveCore.EntityType.AGGREGATOR, _aggregatorId)
    {
        require(_aggregatorId != 0);
        require(_aggregatorIds.contains(_aggregatorId));
        require(_subEntities[_parentAggregatorId].add(_aggregatorId));
        // @todo validate that there is no such token address
        // assert(!_tokenSet.contains(_tokenAddress));

        IHybridHiveCore.AggregatorData storage newAggregator = _aggregatorsData[
            _aggregatorId
        ]; // skip the first token index
        newAggregator.uri = _aggregatorURI;
        newAggregator.operator = _aggregatorOperator;
        newAggregator.parentAggregator = _parentAggregatorId;

        _aggregatorsData[_parentAggregatorId].totalWeight += _weights[
            _parentAggregatorId
        ][_aggregatorId];
    }

    function deleteAggregatorConnection(
        uint256 _parentAggregatorId,
        uint256 _entityId
    ) public onlyOperator(IHybridHiveCore.EntityType.AGGREGATOR, _entityId) {
        require(_aggregatorIds.remove(_entityId));
        require(_subEntities[_parentAggregatorId].remove(_entityId));

        // @todo remove weight also, recheck if needed
        _aggregatorsData[_entityId].parentAggregator = 0;
        _weights[_parentAggregatorId][_entityId] = 0;

        _aggregatorsData[_parentAggregatorId].totalWeight -= _weights[
            _parentAggregatorId
        ][_entityId];
    }

    /**
     *
     * Workflow to connect token to the platform/ store token address as uint256 just for compatibility reasons
     * Step 1: Aggregator aggreed to connect token adding the weight
     * Step 2: The owner might set operator and uri
     * Step 3: Transfer token ownership to the Core platform
     * Step 4: Confirm to add token to the list and add token weight
     *
     */
    // @todo REWORK IT
    // @todo addd disconect function
    function isTokenConnected(
        address _tokenAddress
    ) public view returns (bool) {
        return TokenMock(_tokenAddress).owner() == address(this); // @todo update meta-transactions
    }

    function isTokenConnected(
        uint256 _tokenAddress
    ) public view returns (bool) {
        return
            TokenMock(address(uint160(_tokenAddress))).owner() == address(this); // @todo update meta-transactions
    }

    // @todo restrict control to onlyOperatorValidator
    // @todo rework for new token standart

    // @audit rework, in terms of security
    // @audit check if token is connected
    function addSubEntity(
        uint256 _parentAggregatorId,
        uint256 _entityId, // if it is ERC20 token it should be uint256(TOKEN_ADDRESS)
        uint256 _weight
    )
        public
        onlyOperator(IHybridHiveCore.EntityType.AGGREGATOR, _parentAggregatorId)
    {
        require(_aggregatorIds.contains(_parentAggregatorId));
        require(!_subEntities[_parentAggregatorId].contains(_entityId));
        require(_weights[_parentAggregatorId][_entityId] == 0);
        // @todo verify that there is not such sub entity in whole hive

        _addSubEntities(_parentAggregatorId, _entityId, _weight);
    }

    function removeSubEntity(
        uint256 _parentAggregatorId,
        uint256 _entityId // if it is ERC20 token it should be uint256(TOKEN_ADDRESS)
    )
        public
        onlyOperator(IHybridHiveCore.EntityType.AGGREGATOR, _parentAggregatorId)
    {
        require(_aggregatorIds.contains(_parentAggregatorId));
        require(_subEntities[_parentAggregatorId].remove(_entityId));

        _weights[_parentAggregatorId][_entityId] = 0;
        // @todo verify that there is not such sub entity in whole hive
    }

    // GLOBAL TRANSFER
    /*
    @todo separate adding of the global transfer to the pending list and execution of it
    to prevent frontfuning of the tokens buring
    function addGlobalTransfer(
        IHybridHiveCore.GlobalTransfer memory _globalTransferConfig
    ) public {
        // @todo add access validation
        _globalTransfer[totalGlobalTransfers] = _globalTransferConfig;
        totalGlobalTransfers++;
    }
    function globalTransferExecution(uint256 _globalTransferId)
    */

    // @audit precalculate path on frontend and only do the validation off-chain
    function globalTransfer(
        uint256 _tokenFromId,
        uint256 _tokenToId,
        address _sender,
        address _recipient,
        uint256 _amount
    ) public {
        // @todo add validation
        // @todo validate if it is same as root of `_tokenToId`

        require(_sender == msg.sender);

        uint256 rootAggregator = getRootAggregator(
            _tokensData[_tokenFromId].parentAggregator
        );
        uint256 alternativeRootAggregator = getRootAggregator(
            _tokensData[_tokenToId].parentAggregator
        );

        // check that both tokens are part of the same network
        require(rootAggregator == alternativeRootAggregator);

        // @todo optimize it
        uint256 entityId = _tokenFromId;
        uint256 parentEntity = _tokensData[entityId].parentAggregator;
        uint256 parentTotalSupplay = TokenMock(address(uint160(entityId)))
            .totalSupply();
        UD60x18 operationalShare = convert(_amount).div(
            convert(parentTotalSupplay)
        );
        uint256 operationalValue;

        TokenMock(address(uint160(_tokenFromId))).burn(_sender, _amount);
        while (parentEntity != 0) {
            operationalValue = convert(
                convert(_weights[parentEntity][entityId]).mul(operationalShare)
            );

            _weights[parentEntity][entityId] -= operationalValue;
            _aggregatorsData[parentEntity].totalWeight -= operationalValue;

            entityId = parentEntity;
            parentEntity = _aggregatorsData[entityId].parentAggregator;
            parentTotalSupplay = _aggregatorsData[parentEntity].totalWeight;
            if (parentEntity != 0)
                operationalShare = convert(operationalValue).div(
                    convert(parentTotalSupplay)
                );
        }

        // generate path down
        uint256 pathDownLength = 0;
        entityId = _tokenToId;
        parentEntity = _tokensData[_tokenToId].parentAggregator;
        while (parentEntity != 0) {
            pathDownLength++;
            entityId = parentEntity;
            parentEntity = _aggregatorsData[parentEntity].parentAggregator;
        }
        uint256[] memory pathDown = new uint256[](pathDownLength + 1);

        parentEntity = _tokensData[_tokenToId].parentAggregator;
        for (uint256 i = 1; parentEntity != 0; i++) {
            pathDown[pathDownLength - i] = parentEntity;
            parentEntity = _aggregatorsData[parentEntity].parentAggregator;
        }
        pathDown[pathDownLength] = _tokenToId;

        for (uint256 i = 0; i < pathDown.length - 1; i++) {
            entityId = pathDown[i + 1];
            parentEntity = pathDown[i];
            if (i == pathDown.length - 2) {
                parentTotalSupplay = TokenMock(address(uint160(entityId)))
                    .totalSupply();
            } else {
                parentTotalSupplay = _aggregatorsData[entityId].totalWeight;
            }

            uint256 _weight = _weights[parentEntity][entityId];

            _weights[parentEntity][entityId] += operationalValue;
            _aggregatorsData[parentEntity].totalWeight += operationalValue;

            operationalValue = convert(
                convert(parentTotalSupplay).mul(convert(operationalValue)).div(
                    convert(_weight)
                )
            );

            operationalShare = convert(parentTotalSupplay).div(
                convert(_weight)
            );
        }

        TokenMock(address(uint160(_tokenToId))).mint(
            _recipient,
            operationalValue
        );
    }

    // INTERNAL FUNCTIONS

    // GETTER FUNCTIONS

    function getGlobalAggregatorShare(
        uint256 _networkRootAggregator,
        uint _aggregatorId
    ) public view returns (UD60x18) {
        uint256 entityId = _aggregatorId;
        uint256 parentAggregatorId = _aggregatorsData[_aggregatorId]
            .parentAggregator;
        UD60x18 globalShare = getRelativeWeight(parentAggregatorId, entityId);
        while (parentAggregatorId != _networkRootAggregator) {
            entityId = parentAggregatorId;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;

            globalShare = globalShare.mul(
                getRelativeWeight(parentAggregatorId, entityId)
            );
        }

        return globalShare;
    }

    function getRelativeWeight(
        uint256 _parentAggregatorId,
        uint256 _entityId
    ) public view returns (UD60x18) {
        // @todo add validation
        // check if _parentAggregatorId has _entityId child
        uint256 parentTotalSupply = _aggregatorsData[_parentAggregatorId]
            .totalWeight;
        uint256 childAbsoluteShareValue = _weights[_parentAggregatorId][
            _entityId
        ];

        return convert(childAbsoluteShareValue).div(convert(parentTotalSupply));
    }

    // @todo unfinalized
    function getGlobalValueShare(
        uint256 _networkRootAggregator,
        address _tokenAddress,
        uint256 _absoluteAmount
    ) public view returns (UD60x18) {
        uint256 tokenId = uint256(uint160(_tokenAddress));
        return
            getGlobalValueShare(
                _networkRootAggregator,
                IHybridHiveCore.EntityType.TOKEN,
                tokenId,
                _absoluteAmount
            );
    }

    function getGlobalValueShare(
        uint256 _networkRootAggregator,
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId,
        uint256 _absoluteAmount
    ) public view returns (UD60x18) {
        // @todo add validation
        // @todo add validate if aggregator is root _networkRootAggregator
        uint256 totalAmount;
        uint256 entityId = _entityId;
        uint256 parentAggregatorId;

        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            totalAmount = TokenMock(address(uint160(entityId))).totalSupply();
            parentAggregatorId = _tokensData[entityId].parentAggregator;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            totalAmount = _aggregatorsData[entityId].totalWeight;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;
        }

        UD60x18 globalShare = convert(_absoluteAmount).div(
            convert(totalAmount)
        );

        while (parentAggregatorId != _networkRootAggregator) {
            globalShare = globalShare.mul(
                getRelativeWeight(parentAggregatorId, entityId)
            );

            entityId = parentAggregatorId;
            parentAggregatorId = _aggregatorsData[entityId].parentAggregator;
        }
        return
            globalShare.mul(
                getRelativeWeight(_networkRootAggregator, entityId)
            );
    }

    function getAbsoluteAmountFromShare(
        uint256 _networkRootAggregator,
        address _tokenAddress,
        UD60x18 _globalShare
    ) public view returns (uint256) {
        uint256 tokenId = uint256(uint160(_tokenAddress));
        return
            getAbsoluteAmountFromShare(
                _networkRootAggregator,
                IHybridHiveCore.EntityType.TOKEN,
                tokenId,
                _globalShare
            );
    }

    /**
     *   @dev opposite to getGlobalValueShare function
     *   calculate amount of tokens (_tokenId) based on global share
     */
    function getAbsoluteAmountFromShare(
        uint256 _networkRootAggregator,
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId,
        UD60x18 _globalShare
    ) public view returns (uint256) {
        // @todo add validation
        // @todo add validate if aggregator is root _networkRootAggregator
        uint256 totalAmount;
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            // @todo recheck if it possible
            totalAmount = TokenMock(address(uint160(_entityId))).totalSupply();
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            totalAmount = _aggregatorsData[
                _aggregatorsData[_entityId].parentAggregator
            ].totalWeight;
        }
        UD60x18 totalSupplyShare = getGlobalValueShare(
            _networkRootAggregator,
            _entityType,
            _entityId,
            totalAmount
        );

        // validate if toke supply exceeds the given _globalShare
        // @todo rewrite it according to the fixed point math
        // recheck if there is a need in requirement statement
        //require(totalSupplyShare > _globalShare);

        return
            convert(
                convert(totalAmount).mul(_globalShare).div(totalSupplyShare)
            );
    }

    /**
     * Get the amount of tokens in specific branch
     *
     * @param _aggregatorId aggregator Id
     *
     * @return amount of tokens in spesific network branch under the _aggregatorId
     *
     */
    function getTokenNumberInNetwork(
        uint256 _aggregatorId
    ) public view returns (uint256) {
        return _getTokenNumberInNetwork(_aggregatorId);
    }

    function _getTokenNumberInNetwork(
        uint256 _entityId
    ) private view returns (uint256) {
        if (
            _aggregatorsData[_entityId].aggregatedEntityType ==
            IHybridHiveCore.EntityType.TOKEN
        ) return _subEntities[_entityId].length();
        else {
            uint256 tokensCount = 0;
            for (uint256 i = 0; i < _subEntities[_entityId].length(); i++) {
                tokensCount += _getTokenNumberInNetwork(
                    _subEntities[_entityId].at(i)
                );
            }
            return tokensCount;
        }
    }

    /**
     * Get the list of token ids in the branch with the specified root
     *
     * @param _aggregatorId aggregator Id
     *
     * @return array of tokens
     *
     */
    function getTokensInNetwork(
        uint256 _aggregatorId
    ) public view returns (uint256[] memory) {
        uint256 tokensNumber = _getTokenNumberInNetwork(_aggregatorId);
        uint256[] memory tokensIdList = new uint[](tokensNumber);
        (tokensIdList, ) = _getTokensInNetwork(_aggregatorId, tokensIdList, 0);
        return tokensIdList;
    }

    function _getTokensInNetwork(
        uint256 _entityId,
        uint256[] memory leafArray,
        uint256 index
    ) private view returns (uint256[] memory, uint256) {
        if (
            _aggregatorsData[_entityId].aggregatedEntityType ==
            IHybridHiveCore.EntityType.TOKEN
        ) {
            for (uint256 i = 0; i < _subEntities[_entityId].length(); i++) {
                leafArray[index] = _subEntities[_entityId].at(i);
                index++;
            }

            return (leafArray, index);
        } else {
            for (uint256 i = 0; i < _subEntities[_entityId].length(); i++) {
                (leafArray, index) = _getTokensInNetwork(
                    _subEntities[_entityId].at(i),
                    leafArray,
                    index
                );
            }
            return (leafArray, index);
        }
    }
}
