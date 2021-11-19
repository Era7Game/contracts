// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERA7Card {
    struct ERA7CardEntity {
        uint256 tokenId;
        uint id;
        uint ct;
    }
    function balanceOf(address account) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from,address to,uint256 tokenId) external;
    function awardCard(address player,uint cardId) external returns (uint256);
    function getAllCards() external view returns(ERA7CardEntity[] memory);
}