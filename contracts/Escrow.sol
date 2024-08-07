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
}
