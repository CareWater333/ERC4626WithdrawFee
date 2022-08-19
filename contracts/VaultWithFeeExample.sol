// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC4626WithdrawFee.sol";


/// @notice Vault conforming to ERC4626 to demonstrate withdrawal fees.
/// @notice For more robust implementations, see https://github.com/CareWater333/ERC4626ManagedVaults
/// @author CareWater (https://github.com/CareWater333/ERC4626WithdrawFee)

contract VaultWithFeeExample is ERC4626WithdrawFee, Ownable {
    using SafeERC20 for ERC20;
    using Math for uint256;

    // Events
    event makeInvestmentEvent(address indexed receiver, uint256 amount);

    event returnInvestmentEvent(address indexed investor, uint256 amount, uint256 basis);

    event setOffChainNAVEvent(uint256 oldNAV, uint256 newNAV);

    // Variables
    uint256 offChainNAV;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _managerTreasury,
        uint32 _managerFeeBPS
    ) ERC4626(_asset) ERC20(_name, _symbol) ERC4626WithdrawFee(_managerTreasury, _managerFeeBPS) {}

    // Investment manager functions

    function transferForOffChainInvestment(address receiver, uint256 amount) public onlyOwner {
        ERC20(asset()).safeTransfer(receiver, amount);
        offChainNAV += amount;
        emit makeInvestmentEvent(receiver, amount);
    }

    function returnFromOffChainInvestment(address investor, uint256 amount, uint256 basis) public onlyOwner {
        offChainNAV -= basis;
        ERC20(asset()).safeTransferFrom(investor, address(this), amount);
        emit returnInvestmentEvent(investor, amount, basis);
    }

    function getOffChainNAV() public view returns (uint256) {
        return offChainNAV;
    }

    function setOffChainNAV(uint256 amount) public onlyOwner returns (uint256 oldNAV) {
        oldNAV = offChainNAV;
        offChainNAV = amount;
        emit setOffChainNAVEvent(oldNAV, amount);
        return oldNAV;
    }

    function totalAssets() public view override returns (uint256) {
        return offChainNAV + ERC20(asset()).balanceOf(address(this));
    }

}