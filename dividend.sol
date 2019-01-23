pragma solidity ^0.4.25;
import "./safeMath.sol";


contract ChainAPI {
    
  function getLastestSnapshotHeight() public returns(uint256);
  
  function getUserAssetByHeight(uint256 assetId, uint256 heigth, address userAccount) public returns(uint256);
  
  function getAssetAmountByHeight(uint256 assetId, uint256 heigth) public returns(uint256);
}

contract Dividend {
  using SafeMath for uint256;
  
  uint256 assetId = 1;
  mapping(address => uint256) userAssetInfo;   // asset of bonus, such as fbtc
  mapping(address => uint256) lastCaculteBonusHeight;   // last height of caculating bonus
  mapping(uint256 => uint256[]) bonusHistory;  // bonus infos of every height, maybe there are several bonus per height
  BonusInfo[] bonusInfoList;                   // all bonus info list
  ChainAPI chainAPI;                           // emulate chain API
  address owner;                               // the owner of create this contract, it should be gateway
  
  struct BonusInfo {
    uint256 height;
    uint256 tokenNum;
    uint256 assetTotalNum;
  }
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }
  
  // Project owner should do the following steps before call this function:
  // 1: issue an asset which name is such as fbtc
  // 2: add asset amount of fbtc, the number should be equal as the payment of this function
  // 3: when call this function, owner should transfer fbtc to this contract, 
  //    when user get fbtc, the contract will transfer fbtc to user.
  // 4: the parameter newTokenNum should be equal with owner's payment for this contract. 
  function addBonus(uint256 newTokenNum) public payable onlyOwner() {
    require(newTokenNum == msg.value, "newTokenNum should be equal with your payment to this contract!");
    
    uint256 snapshotHeight = chainAPI.getLastestSnapshotHeight();
    uint256 assetAmount = chainAPI.getAssetAmountByHeight(assetId, snapshotHeight);
    
    BonusInfo memory bonusInfo = BonusInfo({height:snapshotHeight, tokenNum:newTokenNum, assetTotalNum:assetAmount});
    bonusInfoList.push(bonusInfo);
    
    bonusHistory[snapshotHeight].push(bonusInfoList.length - 1);
  }
  
  function caculateBonus(address userAddr) public onlyOwner() {
    uint256 lastCaculteHeight = lastCaculteBonusHeight[msg.sender];
    uint256 snapshotHeight = chainAPI.getLastestSnapshotHeight();
    uint256 userAllBonus = 0;
    for (uint256 height = lastCaculteHeight; height <= snapshotHeight; height++) {
      uint256[] memory bonusList = bonusHistory[height];
      if (bonusList.length == 0) {
        continue;
      }
      uint256 userAssetAmount = chainAPI.getUserAssetByHeight(assetId, height, userAddr);
      uint256 assetAmount = chainAPI.getAssetAmountByHeight(assetId, snapshotHeight);
      uint256 bonusOfOneHeight = 0;
      for (uint256 i = 0; i < bonusList.length; i++) {
        bonusOfOneHeight += bonusInfoList[bonusList[i]].tokenNum.mul(userAssetAmount).div(assetAmount);
      }
      userAllBonus == bonusOfOneHeight;
    }
    lastCaculteBonusHeight[userAddr] = snapshotHeight + 1;
    userAssetInfo[userAddr] += userAllBonus;
  }
    
}