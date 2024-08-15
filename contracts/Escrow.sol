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

    modifier onlyBuyer(uint256 _nftId) {
        require(msg.sender == buyer[_nftId], "Only buyer can call this method");

        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");

        _;
    }

    //modifier to allow only the owner of NFT to call a particular function like Listing the NFT
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this method");

        _;
    }

    // mapping to update the NFT status to listed (to avoid one nft being listed more than once)

    mapping(uint256 => bool) public isListed;

    // Storing some important values
    mapping(uint256 => uint256) public purchasePrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyer;

    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) public approval;

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

    function list(
        uint256 _nftId,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // Transfer NFT from seller to this contract

        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);
        isListed[_nftId] = true;

        purchasePrice[_nftId] = _purchasePrice;
        escrowAmount[_nftId] = _escrowAmount;
        buyer[_nftId] = _buyer;
    }

    //Deposits earnest money into the contract (can only be called the buyer of the nft)

    function depositEarnest(uint256 _nftId) public payable onlyBuyer(_nftId) {
        require(
            msg.value >= escrowAmount[_nftId],
            "earnest amount must be equal to or greater than escrow amount."
        );

        // (bool sent, bytes memory data) = address(this).call{value: msg.value}(
        //     ""
        // );
        // require(sent, "failed to send ether");
    }

    // Updates the inspection status (can only be called only by the inspector)

    function updateInspectionStatus(
        uint256 _nftId,
        bool _passed
    ) public onlyInspector {
        inspectionPassed[_nftId] = _passed;
    }

    //Approve Sale

    function approveSale(uint256 _nftId) public {
        approval[_nftId][msg.sender] = true;
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Finalize sale
    //Todo: -> require inspection status(add more items  here, like appraisal)
    //Todo: -> require sale to be authorized
    //Todo: -> require funds to be correct amount
    //Todo: -> Transfer NFT to buyer
    //Todo: -> Transfer funds to seller

    // prettier-ignore
    function finalizeSale(uint256 _nftId) public  {
        require(inspectionPassed[_nftId], "Inspection not passed");

        require(approval[_nftId][buyer[_nftId]],"need to be approved  by the buyer first");
        
        require(approval[_nftId][seller],"need to be approved by the seller first");
        
        require(approval[_nftId][lender],"need to be approved by the lender first" );

        require(address(this).balance  >= purchasePrice[_nftId], "funds to to be correctly input");   

        // Delisting the nft -> set the status to false

        isListed[_nftId] = false;

        // Transfer funds to seller
       (bool sent, )= payable(seller).call{value: address(this).balance}("");
        require(sent, "failed to send ether");

        // Transfer NFT to buyer
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftId], _nftId);
    }
}
