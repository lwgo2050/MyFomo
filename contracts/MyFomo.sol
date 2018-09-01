pragma solidity ^0.4.23;
import "./MyFomoEvents.sol";
import "./MyFomoDataSet.sol";

import "./library/SafeMath.sol";
import "./library/UintCompressor.sol";
import "./library/NameFilter.sol";
import "./library/UintCompressor.sol";
import "./library/KeysCalcLong.sol";

contract MyFomo {
    using SafeMath for *;
    using NameFilter for string;
    using KeysCalcLong for uint256;

     bool public activated_ = false;
     bool isMainRoundStop = true;

    uint256 constant private rndInit_ = 1 hours;                // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be

    mapping (uint256 => MyFomoDataSet.Round) public main_round_;   // (rID => data) round data，主游戏每轮游戏的信息
    mapping (uint256 => MyFomoDataSet.Round) public sub_round_;   // (rID => data) round data 冲刺阶段每轮游戏的信息

    // (pID => rID => data) player round data by player id & round id
    // 主游戏每轮玩家的当前轮玩家信息，是用address还是palyername待定
    mapping (uint256 => mapping (uint256 => MyFomoDataSet.PlayerAmount)) public mainPlayerRounds_;
    // 冲刺阶段，每轮玩家的信息
    mapping (uint256 => mapping (uint256 => MyFomoDataSet.PlayerAmount)) public subPlayerRounds_;

    uint256 public main_round_id_;    // round id number / total rounds that have happened
    uint256 public sub_round_id_;    // round id number / total rounds that have happened


    /**
     * @dev used to make sure no one can interact with contract until it has 
     * been activated. 
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
    
    /**
     * @dev prevents contracts from interacting with fomo3d 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }

    function buy(uint256 rId, uint256 keyNum) isHuman() 
        public
        payable
    {
        
    }

    function withdraw(uint256 amount) isHuman()
        public
        payable
    {
        
    }
    
    function registWithName(string name) isHuman()
        public
        payable
    {
        
    }

    function getUserByName(string name) 
        public
        view
        returns(address,bytes32,bytes32,uint256)
    {
    }

    function getUserByAddr(address addr)
        public
        view
        returns(address,bytes32,bytes32,uint256)
    {

    }

    function getUserAmountByName(string name) 
        public
        view
        returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    { 

    }

    function getUserAmountByAddr(address addr)
        public
        view
        returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    { 
    }


    //----------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------
    /**
     * @dev 获取当前一个钥匙的购买价格
     * 
     * @return 获取当前钥匙的购买价格 (用最小单位wei)
     */
    function getBuyPrice() 
         public  
         view 
         returns(uint256) 
    { 
        return 0;
    }

    /**
     * @dev 获取主游戏当前轮的剩余时间-这个可以客户端调用者来做
     * 
     * @return 主游戏当前轮的剩余时间-秒数
     */
    function getMainRoundTimeLeft()
        public
        view
        returns(uint256)
    {
    }

      
    /**
     * @dev 返回当前主游戏的详细信息
     * 
     * @return 主游戏当前轮数
     * @return 主游戏当前轮的开始时间
     * @return 主游戏当前轮的结束时间
     * @return 主游戏当前轮的钥匙总数
     * @return 主游戏当前轮总投入eth总量
     * @return 主游戏当前轮可以用来奖励给最终用户的eth金额
     * @return 当前游戏已经分红的eth金额
     */
    function getCurrentMainRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
    }

    /**
     * @dev 获取冲刺游戏当前轮的剩余时间-这个可以客户端调用者来做
     * 
     * @return 冲刺游戏当前轮的剩余时间-秒数
     */
    function getSubRoundTimeLeft()
        public
        view
        returns(uint256)
    {
        emit MyFomoEvent.onNewUser();
    }
    
    /**
     * @dev 返回冲刺游戏的详细信息
     * 
     * @return 冲刺游戏当前轮数
     * @return 冲刺游戏当前轮的开始时间
     * @return 冲刺游戏当前轮的结束时间
     * @return 冲刺游戏当前轮的钥匙总数
     * @return 冲刺游戏当前轮总投入eth总量
     * @return 冲刺游戏当前轮可以用来奖励给最终用户的eth金额
     * @return 冲刺前游戏当前轮已经分红的eth金额
     */
    function getCurrentSubRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
    }


    /**
     *   购买的核心逻辑
     *   1.主流程购买-资金的分配逻辑
     *   2.冲刺阶段流程购买-资金的分配逻辑
     *
    
    
     */
    function buyCore()
        private 
        {
        }

    function buyMainRound() {

    }

    function buySubRound() {

    }

    //==============================================================================
    //     _ _  _ _   | _  _ . _  .
    //    (_(_)| (/_  |(_)(_||(_  . (this + tools + calcs + modules = our softwares engine)
    //=====================_|=======================================================
    /**
     * @dev logic runs whenever a buy order is executed.  determines how to handle 
     * incoming eth depending on if we are in an active round or not
     * 
     *  任何一个主流程游戏的购买都会走到这个逻辑，这个是主流程游戏的核心逻辑，主要包括一下几个方面
     *  1.玩家购买钥匙以及资金统计
     *  2.当前轮游戏最近池收益
     *  3.当前轮游戏的奖池变动
     *
     */
    function buyCore(uint256 _pID, uint256 _affID, uint256 _team, F3Ddatasets.EventReturns memory _eventData_)
        private
    {
        // 设置当前轮
        uint256 _rID = rID_;
        
        // 获取当前时间
        uint256 _now = now;
        
        // 判断当前游戏是否在激活状态
        // 如果主游戏已经激活的场景
        if (_now > main_round_[_rID].strt && (_now <= main_round_[_rID].end || (_now > main_round_[_rID].end && main_round_[_rID].plyr == 0))) 
        {
            // call core 
            core(_rID, _pID, msg.value, _affID, _team, _eventData_);
        
        // 主游戏未激活的场景
        } else {
            // check to see if end round needs to be ran
            if (_now > round_[_rID].end && round_[_rID].ended == false) 
            {
                // end the round (distributes pot) & start new round
			    round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);
                
                // build event data
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;
                
                // fire buy and distribute event 
                emit F3Devents.onBuyAndDistribute
                (
                    msg.sender, 
                    plyr_[_pID].name, 
                    msg.value, 
                    _eventData_.compressedData, 
                    _eventData_.compressedIDs, 
                    _eventData_.winnerAddr, 
                    _eventData_.winnerName, 
                    _eventData_.amountWon, 
                    _eventData_.newPot, 
                    _eventData_.P3DAmount, 
                    _eventData_.genAmount
                );
            }
            
            // put eth in players vault 
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }
  

   
   

}
