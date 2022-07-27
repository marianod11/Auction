// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./EnumerableMap.sol";






contract NFTERC721 is ERC721, Ownable {

    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;
    string public baseURI;
    mapping(uint256 => NFTId) public nftID;
    mapping(address => EnumerableSet.UintSet) private _tokenId;
    string public baseExtension = ".json";


    struct NFTId {
        uint256 id;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol) {  
             baseURI = "";
    }

//BALANCE NFT
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _tokenId[owner].length();
    }

//ID NFT
    function tokenOfOwner(address owner) public view  returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](_tokenId[owner].length());
        for(uint i=0; i<_tokenId[owner].length(); i++) {
            tokens[i] = _tokenId[owner].at(i);
        }
        return tokens;
    }

//ID NFT
   function tokenOfOwnerByIndex(address owner, uint256 index) public view  returns (uint256) {
        return _tokenId[owner].at(index);
    }

//MINT NFT
    function mint(address _to) public {
        uint256 id = _totalSupply();

            _tokenId[_to].add(id);

            NFTId memory newNFT = NFTId(
                id
            );
            nftID[id] = newNFT;
             _mintAnElement(_to);
            
    }




//URL COMPLET API  NFT
function tokenURI(uint256 tokenId) public view virtual override  returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        string memory apiUri = nftID[tokenId].id.toString();
        return
            (bytes(currentBaseURI).length > 0 &&
                bytes(apiUri).length > 0)
                ? string(abi.encodePacked(currentBaseURI,apiUri,baseExtension))
                : "";
    }

//TOTAL SUPPLY PUBLIC 
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

//TOTAL SUPPLY INTERNAL 
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }


//MINT ELEMENT
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }


//TRANSFER INTERNO
    function _transfer(address from, address to, uint256 tokenId ) internal virtual override {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        
        _tokenId[from].remove(tokenId);
        _tokenId[to].add(tokenId);

        super._transfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }



    
 

}
