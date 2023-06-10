// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IHybridHiveCore.sol";
import "./HybridHiveStorage.sol";

// @todo separate functions for tokens from functions for aggregators

contract HybridHiveGeneralGetters is HybridHiveStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function getEntityName(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (string memory) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].name;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].name;
        }
    }

    function getEntitySymbol(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (string memory) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].symbol;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].symbol;
        }
    }

    function getEntityURI(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (string memory) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].uri;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].uri;
        }
    }

    function getTotalSupply(
        IHybridHiveCore.EntityType _entityType,
        uint256 _entityId
    ) public view returns (uint256) {
        if (_entityType == IHybridHiveCore.EntityType.TOKEN) {
            return _tokensData[_entityId].totalSupply;
        } else if (_entityType == IHybridHiveCore.EntityType.AGGREGATOR) {
            return _aggregatorsData[_entityId].totalWeight;
        }
    }

    /**
     * Get the absolute balance of spesific token
     *
     * @param _tokenId token Id
     * @param _account: address of which we what to calculate the token global share
     *
     * Requirements:
     * _tokenId might not be equal to 0
     * _tokenId should exist
     */
    function getTokenBalance(
        uint256 _tokenId,
        address _account
    ) public view returns (uint256) {
        require(_tokenId > 0);
        require(_tokenIds.contains(_tokenId));

        return _balances[_tokenId][_account];
    }

    // @todo add comments
    function getAllowedTokenHolders(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        //@todo add validations if
        return _allowedHolders[_tokenId].values();
    }

    /**
     * Check if account is allowed to hold spesific token
     *
     * @param _tokenId token Id
     * @param _account account to check
     *
     */
    function isAllowedTokenHolder(
        uint256 _tokenId,
        address _account
    ) public view returns (bool) {
        return _allowedHolders[_tokenId].contains(_account);
    }

    // @todo add comments
    // @todo add validation, and notice that it doesn't work for tokens
    function getRootAggregator(
        uint256 _aggregatorId
    ) public view returns (uint256) {
        require(_aggregatorIds.contains(_aggregatorId), "E001");
        if (_aggregatorsData[_aggregatorId].parentAggregator == 0)
            return _aggregatorId;
        return
            getRootAggregator(_aggregatorsData[_aggregatorId].parentAggregator);
    }

    /**
     * Get the id of the aggregator parent
     *
     * @param _aggregatorId aggregator id
     *
     * @return 0 - if no parent, aggregator parent if exists
     * Requirements:
     * aggregator with such id should exist
     */
    function getAggregatorParent(
        uint256 _aggregatorId
    ) public view returns (uint256) {
        require(_aggregatorIds.contains(_aggregatorId));
        //@todo check if parent connected this aggregator as a child
        return _aggregatorsData[_aggregatorId].parentAggregator;
    }

    /**
     * Get the type and list of aggregator sub entities
     *
     * @param _aggregatorId aggregator id
     *
     * @return
     * EntityType - UNDEFINED if no subentities,
     * uint256[] memory - list of tokens or aggregators Id
     *
     * Requirements:
     * aggregator with such id should exist
     */
    function getAggregatorSubEntities(
        uint256 _aggregatorId
    ) public view returns (IHybridHiveCore.EntityType, uint256[] memory) {
        //@todo check if sub entities connected this aggregator as a parent
        require(_aggregatorIds.contains(_aggregatorId));

        return (
            _aggregatorsData[_aggregatorId].aggregatedEntityType,
            _subEntities[_aggregatorId].values()
        );
    }
}
