// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./comm/Helper.sol";

contract ERA7Card is ERC721,Helper {

  struct ERA7CardEntity {
    uint256 tokenId;
    uint id;
    uint ct;
  }
  
  ERA7CardEntity[] public allCards;
  mapping(address => uint256[]) public playerCards;
  mapping(address => mapping(uint256 => uint)) public playerCardIndexs;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("Era7 NFT", "ERANFT") {}

  function awardCard(address player,uint cardId) external onlyHelper returns (uint256){
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    
    ERA7CardEntity memory card = ERA7CardEntity(newItemId,cardId,block.timestamp);
    allCards.push(card);

    playerCards[player].push(newItemId);
    playerCardIndexs[player][newItemId] = playerCards[player].length;

    _mint(player, newItemId);

    emit AwardCard(player,newItemId,cardId);

    return newItemId;
  }
  
  function approveList(address to, uint256[] memory tokenIds) external {
    uint len = tokenIds.length;
    for(uint i = 0; i < len ; i++){
      approve(to, tokenIds[i]);
    }
  }

  function _transfer(address from,address to,uint256 tokenId) internal virtual override {
    super._transfer(from,to,tokenId);
    _swapTokenOwner(from,to,tokenId);
  }

  function burnList(uint256[] memory tokenIds) external { 
    uint len = tokenIds.length;
    for(uint i = 0; i < len ; i++){
      _burn(tokenIds[i]);
    }
  }

  function burn(uint256 tokenId) external {
    _burn(tokenId);
  }

  function _burn(uint256 tokenId) internal virtual override {
    address owner = ERC721.ownerOf(tokenId);
    _swapTokenOwner(owner,address(0),tokenId);
    super._burn(tokenId);
  }

  function _swapTokenOwner(address from,address to,uint256 tokenId) private{
    if(from != to){
      uint index = playerCardIndexs[from][tokenId];
      if(playerCards[from].length != index){
        uint256 oldToken = playerCards[from][playerCards[from].length - 1];
        playerCards[from][index - 1] = oldToken;
        playerCardIndexs[from][oldToken] = index;
      }
      playerCards[from].pop();
      delete playerCardIndexs[from][tokenId];

      if(to != address(0)){
        playerCards[to].push(tokenId);
        playerCardIndexs[to][tokenId] = playerCards[to].length;
      }
    }
  }

  function totalCard() external view returns(uint256) {
    return allCards.length;
  }

  function getPlayerCards(address player) external view returns (ERA7CardEntity[] memory) {
    uint[] memory list = playerCards[player];
    uint length = list.length;
    ERA7CardEntity[] memory cardList = new ERA7CardEntity[](length);
    for(uint i = 0; i < length ; i++){
      cardList[i] = allCards[list[i] - 1];
    }
    return cardList;
  }

  event AwardCard(address indexed to, uint256 nftId,uint256 cardId);
}
