// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../HybridHiveCore.sol";
import "../interfaces/IHybridHiveCore.sol";

contract AggregatorOperatorMock is Ownable {
    HybridHiveCore public hybridHiveCore;

    function setCoreAddress(address _hybridHiveCore) public {
        hybridHiveCore = HybridHiveCore(_hybridHiveCore);
    }

    function addSubEntity(
        uint256 _parentAggregatorId,
        uint256 _entityId,
        uint256 _weight
    ) public onlyOwner {
        hybridHiveCore.addSubEntity(_parentAggregatorId, _entityId, _weight);
    }

    function addAggregatorDetails(
        uint256 _parentAggregatorId,
        uint256 _aggregatorId,
        string memory _aggregatorURI,
        address _aggregatorOperator
    ) public onlyOwner {
        hybridHiveCore.addAggregatorDetails(
            _parentAggregatorId,
            _aggregatorId,
            _aggregatorURI,
            _aggregatorOperator
        );
    }

    function deleteAggregatorConnection(
        uint256 _parentAggregatorId,
        uint256 _entityId
    ) public onlyOwner {
        hybridHiveCore.deleteAggregatorConnection(
            _parentAggregatorId,
            _entityId
        );
    }
}
