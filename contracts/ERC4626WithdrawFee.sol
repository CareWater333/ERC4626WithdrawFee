// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/// @notice ERC4626 tokenized Vault implementation with withdrawal fees
/// @notice based on OpenZeppelin v4.7 (token/ERC20/extensions/ERC4626.sol)
/// @author CareWater (https://github.com/CareWater333/ERC4626WithdrawFee)

// TODO consider making this clonable and therefore initializable

abstract contract ERC4626WithdrawFee is ERC4626 {
    using Math for uint256;
    using SafeERC20 for ERC20;

    address public feeAddress; // if you implement setFeeAddress, make sure you specify onlyOwner or otherwise secure it
    uint32 public immutable withdrawFeeBPS;

    constructor(address _feeAddress, uint32 _withdrawFeeBPS) {
        feeAddress = _feeAddress;
        require(_withdrawFeeBPS < 10000, "Withdraw Fee must be less than 100%");
        withdrawFeeBPS = _withdrawFeeBPS;
    }

    function getWithdrawFeeBPS() public view returns (uint32) {
        return withdrawFeeBPS;
    }

    // Functions overridden from ERC4626

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner)
        public
        view
        virtual
        override
        returns (uint256 assets)
    {
        (assets, ) = _convertToAssetsWithFee(
            balanceOf(owner),
            Math.Rounding.Down
        );
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets)
        public
        view
        virtual
        override
        returns (uint256 shares)
    {
        (shares, ) = _convertToSharesWithFee(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares)
        public
        view
        virtual
        override
        returns (uint256 assets)
    {
        (assets, ) = _convertToAssetsWithFee(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(
            assets <= maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );

        (uint256 shares, uint256 feeAmount) = _convertToSharesWithFee(
            assets,
            Math.Rounding.Up
        );
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        ERC20(asset()).safeTransfer(feeAddress, feeAmount);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        (uint256 assets, uint256 feeAmount) = _convertToAssetsWithFee(
            shares,
            Math.Rounding.Down
        );
        _withdraw(_msgSender(), receiver, owner, assets, shares);
        ERC20(asset()).safeTransfer(feeAddress, feeAmount);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction and a fee in BPS.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amout of shares.
     */
    function _convertToSharesWithFee(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        returns (uint256 shares, uint256 feeAmount)
    {
        uint256 supply = totalSupply();
        if (assets == 0) return (0, 0);
        feeAmount = assets.mulDiv(
            withdrawFeeBPS,
            10000 - withdrawFeeBPS,
            rounding
        );
        assets += feeAmount; // gross up for the fee
        shares = (supply == 0)
            ? assets.mulDiv(
                10**decimals(),
                10**IERC20Metadata(asset()).decimals(),
                rounding
            )
            : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction and a fee in BPS.
     */
    function _convertToAssetsWithFee(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        returns (uint256 assets, uint256 feeAmount)
    {
        uint256 supply = totalSupply();
        assets = (supply == 0)
            ? shares.mulDiv(
                10**IERC20Metadata(asset()).decimals(),
                10**decimals(),
                rounding
            )
            : shares.mulDiv(totalAssets(), supply, rounding);
        feeAmount = assets.mulDiv(withdrawFeeBPS, 10000, rounding);
        assets -= feeAmount;
    }
}
