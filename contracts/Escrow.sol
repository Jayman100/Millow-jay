//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;

    event TransferFrom(address from, address to);
}

contract Escrow {
    address public nftAddress;
    address public inspector;
    address public lender;
    address payable public seller;

    // mapping to update the NFT status to listed (to avoid one nft being listed more than once)

    mapping(uint256 => bool) public isListed;

    // Storing some important values
    mapping(uint256 => uint256) public purchasePrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyer;

    constructor(
        address _nftAddress,
        address payable _seller,
        address _lender,
        address _inspector
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        lender = _lender;
        inspector = _inspector;
    }

    function list(uint _nftId) public {
        // Transfer NFT from seller to this contract

        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);
        isListed[_nftId] = true;

        buyer[_nftId] = msg.sender
    }
}
