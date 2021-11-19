// nft交易市场
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./comm/SafeMath.sol";
import "./comm/Helper.sol";
import "./IERA7Card.sol";

contract ERA7CardMarketPlace is Helper {

  address public coin;
  address public nft;

  uint256[] public sellingNfts;
  mapping(uint256 => uint256) public sellingNftIndexs;

  struct MarketPlaceNftInfo{
    uint256 tokenId;
    uint price;
    address owner;
    uint upTime;
  }
  mapping(uint256 => MarketPlaceNftInfo) public nftMap;

  constructor() {}

  function initAddress(address coin_,address nft_) external onlyHelper {
    require((coin_ != address(0) && nft_ != address(0)), "ERA7CardMarketPlace initAddress: address error");

    coin = coin_;
    nft = nft_;
  }

  function withdraw(address taxWallet) external onlyHelper returns(bool){
    require(taxWallet != address(0), "ERA7CardMarketPlace withdraw: taxWallet error");

    uint256 val = IERC20(coin).balanceOf(address(this));
    require(val > 0, "ERA7CardMarketPlace withdraw: val error");
    
    IERC20(coin).transfer(taxWallet,val);
    return true;
  }

  function uploadNft(uint256 nftId,uint256 price) external nonReentrant isPause{
      address ownerAddress = IERA7Card(nft).ownerOf(nftId);
      address uploadAddress = _msgSender();
      require(ownerAddress == uploadAddress, "ERA7CardMarketPlace uploadNft: not owner");
      require(price > 10000, "ERA7CardMarketPlace uploadNft: price error");

      uint index = sellingNftIndexs[nftId];
      if(index == 0){
        MarketPlaceNftInfo memory newInfo = MarketPlaceNftInfo(nftId,price,ownerAddress,block.timestamp);
        nftMap[nftId] = newInfo;
        sellingNfts.push(nftId);
        sellingNftIndexs[nftId] = sellingNfts.length;
      }else{
        MarketPlaceNftInfo storage oldInfo = nftMap[nftId];
        oldInfo.price = price;
        oldInfo.upTime = block.timestamp;
      }

      emit UploadNft(ownerAddress,nftId,price);
  }

  function stopSell(uint256 nftId) external nonReentrant isPause{
    uint index = sellingNftIndexs[nftId];
    require(index > 0, "ERA7CardMarketPlace stopSell: nftId error");

    address ownerAddress = IERA7Card(nft).ownerOf(nftId);
    require(ownerAddress == _msgSender(), "ERA7CardMarketPlace stopSell: stop error");

    _removeNftFromList(nftId);

    emit StopSell(nftId);
  }

  function _removeNftFromList(uint256 nftId) private{
    uint index = sellingNftIndexs[nftId];
      if(sellingNfts.length != index){
        uint oldNftId = sellingNfts[sellingNfts.length - 1];
        sellingNfts[index - 1] = oldNftId;
        sellingNftIndexs[oldNftId] = index;
      }
      sellingNfts.pop();
      delete sellingNftIndexs[nftId];
      delete nftMap[nftId];
  }

  function getTotalNft() external view returns(uint){
    return sellingNfts.length;
  }

  function getSellList(uint start,uint end) external view returns(MarketPlaceNftInfo[] memory){
      require(start >= 0 && end >= start,"ERA7CardMarketPlace getSellList:params error");

      uint total = sellingNfts.length;
      if(total == 0){
        return new MarketPlaceNftInfo[](0);
      }
      if(start >= total){
        start = total - 1;
      }
      if(end >= total){
        end = total - 1;
      }
      uint size = end - start;
      require(size <= 100,"ERA7CardMarketPlace getSellList:size error");

      MarketPlaceNftInfo[] memory list = new MarketPlaceNftInfo[](size + 1);
      for(uint i = start; i <= end ; i++){
        list[i - start] = nftMap[sellingNfts[i]];
      }
      return list;
  }

  function buy(uint256 nftId) external nonReentrant isPause {
    MarketPlaceNftInfo memory info = nftMap[nftId];
    require(info.tokenId > 0, "ERA7CardMarketPlace buy: nftId error");

    address ownerAddress = IERA7Card(nft).ownerOf(nftId);
    require(ownerAddress == info.owner, "ERA7CardMarketPlace buy: nftId owner change");

    SafeERC20.safeTransferFrom(IERC20(coin),_msgSender(),address(this),info.price);
    IERA7Card(nft).transferFrom(info.owner,address(this),nftId);
    
    uint256 get = SafeMath.mul(SafeMath.div(info.price,100),95);
    SafeERC20.safeTransfer(IERC20(coin),info.owner,get);
    IERA7Card(nft).transferFrom(address(this),_msgSender(),nftId);

    _removeNftFromList(nftId);

    emit Buy(info.owner,_msgSender(),info.tokenId,info.price);
  }

  event UploadNft(address indexed from, uint256 nftId,uint256 price);
  event StopSell(uint256 nftId);
  event Buy(address indexed from, address indexed to, uint256 nftId,uint256 price);

  



  









}
