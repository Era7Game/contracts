// Nft 预售合约
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./comm/Helper.sol";
import "./IERA7Card.sol";

contract ERA7CardPreSale is Helper {

  address public coin;
  address public nft;

  struct PreSaleNftInfo{
    uint cardId;
    uint price;
    uint count;
  }

  uint[] public sellingNfts;
  mapping(uint => uint) public sellingNftIndexs;
  mapping(uint => PreSaleNftInfo) public sellingInfos;

  constructor() {}

  function initAddress(address coin_,address nft_) external onlyHelper {
    require((coin_ != address(0) && nft_ != address(0)), "ERA7CardPreSale initAddress: address error");

    coin = coin_;
    nft = nft_;
  }

  function withdraw(address taxWallet) external onlyHelper returns(bool){
    require(taxWallet != address(0), "ERA7CardPreSale withdraw: taxWallet error");

    uint256 val = IERC20(coin).balanceOf(address(this));
    require(val > 0, "ERA7CardPreSale withdraw: val error");
    
    IERC20(coin).transfer(taxWallet,val);
    return true;
  }

  function uploadNft(uint cardId,uint256 price,uint count) external onlyHelper{
      require(cardId > 0 && price > 0 && count > 0, "ERA7CardPreSale uploadNft: params error");

      uint index = sellingNftIndexs[cardId];
      if(index == 0){
        PreSaleNftInfo memory newInfo = PreSaleNftInfo(cardId,price,count);
        sellingInfos[cardId] = newInfo;
        sellingNfts.push(cardId);
        sellingNftIndexs[cardId] = sellingNfts.length;
      }else{
        PreSaleNftInfo storage oldInfo = sellingInfos[cardId];
        oldInfo.price = price;
        oldInfo.count = count;
      }
  }

  function stopSell(uint cardId) external onlyHelper{
      PreSaleNftInfo storage info = sellingInfos[cardId];
      require(info.cardId > 0, "ERA7CardPreSale stopSell: cardId error");

      uint index = sellingNftIndexs[cardId];
      if(sellingNfts.length != index){
        uint oldCardId = sellingNfts[sellingNfts.length - 1];
        sellingNfts[index - 1] = oldCardId;
        sellingNftIndexs[oldCardId] = index;
      }
      sellingNfts.pop();
      delete sellingNftIndexs[cardId];
      delete sellingInfos[cardId];
  }

  function getSellList() external view returns(PreSaleNftInfo[] memory){
      uint len = sellingNfts.length;
      PreSaleNftInfo[] memory list = new PreSaleNftInfo[](len);
      for(uint i = 0; i < len ;i++){
        list[i] = sellingInfos[sellingNfts[i]];
      }
      return list;
  }

  function buy(uint cardId) external nonReentrant returns(uint256){
      PreSaleNftInfo storage info = sellingInfos[cardId];
      require(info.cardId > 0, "ERA7CardPreSale buy: cardId error");

      uint count = info.count;
      require(count > 0, "ERA7CardPreSale buy: count error");
      info.count--;
      
      address buyAddress = _msgSender();
      SafeERC20.safeTransferFrom(IERC20(coin),buyAddress,address(this),info.price);

      uint256 tokenId = IERA7Card(nft).awardCard(buyAddress,cardId);

      emit Buy(_msgSender(),cardId,info.price);

      return tokenId;
  }

  event Buy(address indexed to, uint256 cardId,uint256 price);



  









}
