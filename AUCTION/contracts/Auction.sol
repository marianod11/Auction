pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NFTERC721.sol";


contract ChaSubasta {

    IERC20 public USDT;
    NFTERC721 public NFT;

    uint public sig = 0;


    constructor(address _usdt, address _nft){
        USDT= IERC20 (_usdt);
        NFT= NFTERC721(_nft);
    }


    mapping(uint => NftSubasta) public Subasta;

    mapping(address=> mapping(uint => Auction)) public BidCount;

    mapping(uint => mapping(address => bool)) public isConfirmed;

    address[] public users;


    modifier onlyOwner(address _address, uint _sig) {
        require(isConfirmed[_sig][_address], "not owner");
        _;
    }

    modifier sigExists(uint _sig) {
        require(_sig <= sig, "no existe esa subasta");
        _;
    }

    modifier notExecuted(uint _sig) {
        NftSubasta storage infoSubasta = Subasta[_sig];
        require(!infoSubasta.executed, "Sig ya ejecutada");
        _;
    }


    struct NftSubasta{
        address seller;
        address buyer;
        uint id;
        uint precio;
        bool sold;
        uint finalPrice;
        bool executed;
    }

    struct Auction {
        uint sig;
        address buyer;
        uint count;
        bool approvado;
    }


    event createListing(address seller, uint id, uint price, uint sig);
    event bidAuction(uint sig, address bider, uint countn);
    event acceptBid(uint sig, address buyer, uint count);
    event trasnferToken(address seller, address buyer, uint id);
    event trasferNFT(address buyer, address seller, uint count);

//APPROVE ALL NFTS
    function appoveAllNFT() external {
        uint balance = NFTERC721(NFT).balanceOf(msg.sender);
        require (balance > 0, "mayor a 0");
        uint[] memory idsOwner = NFT.tokenOfOwner(msg.sender);
        for(uint i = 0; i< idsOwner.length; i++){
            NFTERC721(NFT).approve(address(this), idsOwner[i]);
        }
    }


//APPROVE TOKENS
    function aprovveTokenERC20() external{
        uint totalSupply = IERC20(USDT).totalSupply();
          IERC20(USDT).approve(address(this), totalSupply);
    }



//CREATE AUCTION
    function createAuction(uint _id, uint _priceMin) external {
        require(NFTERC721(NFT).exists(_id), "no lo tenes");

         sig += 1;
         NftSubasta memory nftSubasta = NftSubasta(
            msg.sender,
            0x0000000000000000000000000000000000000000,
            _id,
            _priceMin,
            false,
            0,
            false
        );

        Subasta[sig] = nftSubasta;
        isConfirmed[sig][msg.sender] = true;

        emit createListing(msg.sender, _id, _priceMin, sig);
    }



//OFERT AUCTION
    function biderAuction(uint _sig, uint _count) public sigExists(_sig) {
        uint balance = IERC20(USDT).balanceOf(msg.sender);
        require(balance >= _count, "no tenes tanto");

        NftSubasta storage infoSubasta = Subasta[_sig];
        require(_count > infoSubasta.precio, "te falta dinero!!");

        Auction memory nftAution = Auction(
            _sig,
            msg.sender,
            _count,
            false
        );

        BidCount[msg.sender][_sig] = nftAution;
        users.push(msg.sender);

        emit bidAuction(_sig, msg.sender, _count);

    }



//ACEPT OFFERT
    function acceptAution(address _user, uint _sig) public
        onlyOwner(msg.sender, _sig)
        sigExists(_sig){
        
        NftSubasta storage infoSubasta = Subasta[_sig];
        uint cantidadFinal = BidCount[_user][_sig].count;

        infoSubasta.buyer = _user;
        infoSubasta.sold = true;
        infoSubasta.finalPrice = cantidadFinal;

        BidCount[_user][_sig].approvado = true;

        isConfirmed[_sig][_user] = true;

        emit acceptBid(_sig, _user,cantidadFinal );

    }






//TRASNFER PROFITS
    function changeTransaccion (uint _sig) public 
        onlyOwner(msg.sender, _sig)
        notExecuted(_sig) 
        sigExists(_sig) { 

        NftSubasta storage infoSubasta = Subasta[_sig];

        require(infoSubasta.sold == true, "no fue vendido");
        uint256 allowance = IERC20(USDT).allowance(msg.sender, address(this));
        require( infoSubasta.finalPrice > 0, "You need to sell at least some tokens");
        require(allowance >=  infoSubasta.finalPrice, "Check the token allowance");
        if(infoSubasta.finalPrice > 0){
            require(IERC20(USDT).transferFrom(infoSubasta.buyer, infoSubasta.seller, infoSubasta.finalPrice));
            NFTERC721(NFT).safeTransferFrom(infoSubasta.seller, infoSubasta.buyer, infoSubasta.id);
        }

        infoSubasta.executed = true;

        isConfirmed[_sig][infoSubasta.buyer] = false;
        isConfirmed[_sig][infoSubasta.seller] = false;

        emit trasferNFT(infoSubasta.seller, infoSubasta.buyer, infoSubasta.id);
        emit trasnferToken(infoSubasta.buyer, infoSubasta.seller, infoSubasta.finalPrice);

    }






}

