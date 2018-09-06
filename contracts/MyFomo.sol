pragma solidity ^0.4.23;
import "./MyFomoDataSet.sol";

import "./library/SafeMath.sol";
import "./library/UintCompressor.sol";
import "./library/NameFilter.sol";
import "./library/UintCompressor.sol";
import "./library/KeysCalcLong.sol";

import "./UserCenter.sol";

contract MyFomo is UserCenter {
    using SafeMath for *;
    using NameFilter for string;
    using KeysCalcLong for uint256;

    bool public activated_ = false;
    bool isMainRoundStop = true;
    bool isSubRoundStart = false;

    uint256 constant private rndInit_ = 1 hours;                // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be
    uint256 constant private subRndDesc_ = 1 seconds;       
    uint256 constant private subRndMax_ = 300 seconds;       

    // 每一个钥匙购买者eth在整个奖池中的分配规则
    uint256 constant private main_round_pot_ration = 43;           // 43%进入总奖池
    uint256 constant private main_round_dividend_ration = 43;       // 43%用于分配给钥匙持有者
    uint256 constant private main_round_inviter_ration = 10;        // 10用来分配给推荐人,如果没有推荐人则分配给团队开发者
    uint256 constant private main_round_developer_ration = 3;       // 3%用来分配给
    uint256 constant private main_round_fee_ration = 1;             // 1% 手续费

    // 每一个钥匙购买者eth在整个奖池中的分配规则
    uint256 constant private sub_round_pot_ration = 56;           // 56%进入总奖池
    // uint256 constant private sub_round_dividend_ration = 23;       // 43%用于分配给钥匙持有者
    uint256 constant private sub_round_subpot_ration = 40;        // 40用来分配给推荐人,如果没有推荐人则分配给团队开发者
    uint256 constant private sub_round_developer_ration = 3;       // 3%用来分配给
    uint256 constant private sub_round_fee_ration = 1;             // 1% 手续费

    mapping (uint256 => MyFomoDataSet.Round) public main_round_;   // (rID => data) round data，主游戏每轮游戏的信息
    mapping (uint256 => MyFomoDataSet.Round) public sub_round_;   // (rID => data) round data 冲刺阶段每轮游戏的信息

    // (pID => rID => data) player round data by player id & round id
    // 主游戏每轮玩家的当前轮玩家信息，是用address还是palyername待定
    mapping (address => mapping (uint256 => MyFomoDataSet.PlayerAmount)) public mainPlayerRounds_;
    // 冲刺阶段，每轮玩家的信息
    mapping (address => mapping (uint256 => MyFomoDataSet.PlayerAmount)) public subPlayerRounds_;

    uint256 public main_round_id_;    // round id number / total rounds that have happened
    uint256 public sub_round_id_;    // round id number / total rounds that have happened

    /**
     * @dev 判断游戏是否激活 
     * 
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

    function buy(uint256 rId, uint256 keyNum) 
        public
        payable
        isHuman()
        isActivated()
        isWithinLimits(msg.value)
    {
        buyCore();
    }

    function withdraw(uint256 amount) 
        public
        payable
        isHuman()
        isActivated()
    {
        // 获取主游戏的轮数
        uint256 _rID = main_round_id_;  // 主游戏的ID
        
        // 获取当前时间
        uint256 _now = now;
        
        // 玩家地址
        address _player = msg.sender;
        
        // setup temp var for player eth
        uint256 _eth;
        
        // 检查当前游戏是否已经结束
        if (_now > main_round_[_rID].end && main_round_[_rID].ended == false && main_round_[_rID].plyr != 0)
        {
            // 该轮游戏已经结束，终止游戏
            // 设置返回event数据
            MyFomoDataSet.EventReturns memory _eventData_;
            
            main_round_[_rID].ended = true;
            _eventData_ = endMainRound(_eventData_);
            
            // 获取可提现的金额
            _eth = withdrawEarnings(_player); // TODO to be implements
            
            // 提现
            if (_eth > 0)
                _player.transfer(_eth);    
            
            emit onWithdrawAndDistribute
            (
                msg.sender, 
                users_[addrUids_[_player]].name, 
                _eth, 
                _eventData_.winnerAddr, 
                _eventData_.winnerName, 
                _eventData_.amountWon, 
                _eventData_.newPot
            );
            
        // in any other situation
        } else {
            // get their earnings
            _eth = withdrawEarnings(_player);
            
            // gib moni
            if (_eth > 0)
                _player.transfer(_eth);
            
            // fire withdraw event
            emit onWithdraw( msg.sender, users_[addrUids_[_player]].name, _eth, _now);
        }
        
    }

    /**
     * brief: 根据用户名获取用户资金信息
     * 参数: name 用户名称
     * 返回：UserAmount 成功时返回表示该用户所有资金信息UserAmount的对象
     * uint256 totalKeys;          // 购买钥匙总量
     * uint256 totalBet;           // 总投注量eth
     * uint256 lastKeys;           // 最后一次购买钥匙数量
     * uint256 lastBet;            // 最后一次投注量
     * uint256 totalBalance;       // 总余额(eth)
     * uint256 withdrawAble;       // 可提现总量(eth)
     * uint256 withdraw;           // 已提现数量(eth)
     * uint256 totalProfit;        // 获益总量 （不算成本)
     * uint256 inviteProfit;       // 邀请获益(eth)
     */
    function getUserRndAmountByName(string name) 
        public
        view
        returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    { 
        checkStopSubRnd();
        MyFomoDataSet.UserAmount memory amt = MyFomoDataSet.UserAmount(0,0,0,0,0,0,0,0,0);
        if (userExist(name))
            amt = userAmounts_[nameAddr_[name.nameFilter()]];
        
    }

    function getUserRndAmountByAddr(address addr)
        public
        view
        returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    { 
        checkStopSubRnd();
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
               // setup local rID
        uint256 _rID = main_round_id_;
        
        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > main_round_[_rID].strt && (_now <= main_round_[_rID].end || (_now > main_round_[_rID].end && main_round_[_rID].plyr == 0)))
            return ( (main_round_[_rID].keys.add(1000000000000000000)).ethRec(1000000000000000000) );
        else // rounds over.  need price for new round
            return ( 75000000000000 ); // 这个初始价格和钥匙的增长机制 需要产品来定义
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
        // setup local rID
        uint256 _rID = main_round_id_;
        
        // grab time
        uint256 _now = now;
        
        if (_now < main_round_[_rID].end)
            return( (main_round_[_rID].end).sub(_now));
        else
            return(0);
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
        returns(uint256, uint256, uint256, uint256, uint256,uint256, uint256)
    {
         // setup local rID
        uint256 _rID = main_round_id_;
        
        return
        (
            _rID,                                //1
            main_round_[_rID].strt,              //2
            main_round_[_rID].end,               //3
            main_round_[_rID].keys,              //4
            main_round_[_rID].eth,               //5
            main_round_[_rID].pot,               //6
            main_round_[_rID].dividend           //7
        );
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
        checkStopSubRnd();
        return sub_round_[sub_round_id_].end.sub(sub_round_[sub_round_id_].strt);
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
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
                 // setup local rID
        uint256 _rID = sub_round_id_;
        
        return
        (
            _rID,                               //1
            sub_round_[_rID].strt,              //2
            sub_round_[_rID].end,               //3
            sub_round_[_rID].keys,              //4
            sub_round_[_rID].eth,               //5
            sub_round_[_rID].pot,               //6
            sub_round_[_rID].dividend           //7
        );
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
          // 设置当前轮
        uint256 _rID = main_round_id_;
        
        // 获取当前时间
        uint256 _now = now;

        // 判断当前游戏是否在激活状态
        // 如果主游戏已经激活的场景
        // TODO::因涉及到冲刺游戏，通过时间判断主游戏是否结束可能不太靠谱，冲刺游戏中时，主游戏的时间是暂停的，但是now一直在变化
        if (_now > main_round_[_rID].strt && (_now <= main_round_[_rID].end || (_now > main_round_[_rID].end && main_round_[_rID].plyr == 0))) 
        {
            // 如果冲刺阶段的游戏没有开启，则买主轮游戏
            if (!isSubRoundStart) {
                buyMainRound(_rID,msg.value);
            } else {
                uint256 _keys = 0;
                buySubRound(sub_round_id_, _keys);
            }
        
        // 主游戏未激活的场景
        } else {
            
        }
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
    function buyMainRound(uint256 _rID, uint256 _eth) 
        private 
    {
        address _player = msg.sender; // 玩家地址

        uint256 _keys = 0; // 计算玩家的eth能够买入的keys TODO 根据当前钥匙的价格 换算用户可以买入的钥匙数量
        if (_keys >=1) {
            main_round_[_rID].plyr = _player; // 设置本轮的最新买入者
            updateTimer(_keys, _rID);
        }
        // uint256 _eth = msg.value; // 玩家投入的eth
                                  // 是否要根据eth 换算成keys

        // 1.更新玩家本轮游戏的投入信息
        mainPlayerRounds_[_player][_rID].totalKeys = _keys.add(mainPlayerRounds_[_player][_rID].totalKeys); // 用户本轮总买入keys
        mainPlayerRounds_[_player][_rID].totalBet = _eth.add(mainPlayerRounds_[_player][_rID].totalBet); // 用户本轮总花费eth
        
        // 更新本局的资金池总投入信息
        main_round_[_rID].keys = _keys.add(main_round_[_rID].keys);
        main_round_[_rID].eth = _eth.add(main_round_[_rID].eth);

        // 计算本次对之前购买用户的一个分成-分成计算
        // 43%进入总奖池 
        main_round_[_rID].pot = (_eth.mul(main_round_pot_ration)/100).add(main_round_[_rID].pot);

        // 43% 进行分红
        uint256 _dividend = _eth.mul(main_round_dividend_ration)/100; // 进入分红奖池的比例
        main_round_[_rID].dividend = main_round_[_rID].dividend.add(_dividend);
        // uint256 _dividend_per_key = _dividend.div(main_round_[_rID].keys); // 计算每个key的股息
        mainPlayerRounds_[_player][_rID].mask = mainPlayerRounds_[_player][_rID].mask.add(main_round_[_rID].mask.mul(_keys)); // 用户每次买入后计算应当扣除的部分
        // 10% 推荐人, 跟新推荐人资金信息
        bytes32 _inviter_name = users_[addrUids_[_player]].inviterName;
        uint256 _profit = _eth.mul(main_round_inviter_ration)/100;
        if (_inviter_name != "") {
            address _inviter = nameAddr_[_inviter_name];
            users_[addrUids_[_inviter]].inviteNum = users_[addrUids_[_inviter]].inviteNum.add(1);
            userAmounts_[_inviter].inviteProfit = userAmounts_[_inviter].inviteProfit.add(_profit); // 邀请奖励
            userAmounts_[_inviter].withdrawAble = userAmounts_[_inviter].withdrawAble.add(_profit); // 可提现
            userAmounts_[_inviter].totalBalance = userAmounts_[_inviter].totalBalance.add(_profit); // 总余额
        } else {
            _opeAmount.devFund = _opeAmount.devFund.add(_profit); // 没有推荐人则进入开发基金
        }
        // 3% 团队开发资金
        _opeAmount.devFund = _opeAmount.devFund.add(_eth.mul(sub_round_developer_ration)/100);
        // 1% 手续费
        _opeAmount.fees = _opeAmount.fees.add(_eth.mul(sub_round_fee_ration)/100);

        // 更新个人资金信息（UserAmount）
        userAmounts_[_player].totalKeys = userAmounts_[_player].totalKeys.add(_keys); // 总令牌
        userAmounts_[_player].totalBet = userAmounts_[_player].totalBet.add(_eth);    // 总投入eth
        userAmounts_[_player].lastKeys = _keys;      // 最新一次购买的令牌
        userAmounts_[_player].lastBet = _eth;         // 最新一次投入eth量
    }

    function buySubRound(uint256 _rID, uint256 _keys)
        private 
    {
        address _player = msg.sender; // 玩家地址
        uint256 _eth = msg.value; // 玩家投入的eth
        uint256 _now = now;
                                  // 是否要根据eth 换算成keys
        // 冲刺游戏处理游戏中
        if (_now > sub_round_[_rID].strt && (_now <= sub_round_[_rID].end)) 
        {
            // 1.更新玩家本轮游戏的投入信息
            subPlayerRounds_[_player][_rID].totalKeys = _keys.add(subPlayerRounds_[_player][_rID].totalKeys); // 用户本轮总买入keys
            subPlayerRounds_[_player][_rID].totalBet = _eth.add(subPlayerRounds_[_player][_rID].totalBet); // 用户本轮总花费eth
            
            // 更新本局的资金池总投入信息
            sub_round_[_rID].keys = _keys.add(sub_round_[_rID].keys);
            sub_round_[_rID].eth = _eth.add(sub_round_[_rID].eth);

            // 注册用户
            registWithAddr(_player);

            // 计算本次对之前购买用户的一个分成-分成计算
            // 56%进入总奖池 
            uint _mrID = main_round_id_;
            main_round_[_mrID].pot = (_eth.mul(sub_round_pot_ration)/100).add(main_round_[_mrID].pot);
            // 40% 冲刺奖池
            sub_round_[_rID].pot = (_eth.mul(sub_round_subpot_ration)/100).add(sub_round_[_rID].pot);
            // 3% 团队开发资金
            _opeAmount.devFund = _opeAmount.devFund.add(_eth.mul(sub_round_developer_ration)/100);
            // 1% 手续费
            _opeAmount.fees = _opeAmount.fees.add(_eth.mul(sub_round_fee_ration)/100);

            // 更新个人资金信息（UserAmount）
            userAmounts_[_player].totalKeys = userAmounts_[_player].totalKeys.add(_keys); // 总令牌
            userAmounts_[_player].totalBet = userAmounts_[_player].totalBet.add(_eth);    // 总投入eth
            userAmounts_[_player].lastKeys = _keys;      // 最新一次购买的令牌
            userAmounts_[_player].lastBet = _eth;         // 最新一次投入eth量
            // 更新最后玩家
            sub_round_[_rID].plyr = _player;

            // 更新奖池的时间信息
            updateSubTimer(_keys, _rID);

            // 更新钥匙价格
        } 
        // sub_round已经结束，但没有结束
        else 
            buyEndSub(_rID, _player, _eth);
    }

    function buyEndSub(uint256 _rID, address _player, uint256 _eth) 
        private
    {
        endSub(_rID);
        // 买入失败、由于手续费限制，将买入的金额计入主游戏
        mainPlayerRounds_[_player][main_round_id_].withdrawAble = mainPlayerRounds_[_player][main_round_id_].withdrawAble.add(_eth);
    }

    function endSub(uint256 _rID) 
        private
    {
        isSubRoundStart = false;
        address _winer = sub_round_[_rID].plyr;
        uint256 _win_eth = mainPlayerRounds_[_winer][main_round_id_].withdrawAble.add(sub_round_[_rID].pot);
        mainPlayerRounds_[_winer][main_round_id_].withdrawAble = _win_eth;
        sub_round_[_rID].ended = true;
        sub_round_[_rID].strt = sub_round_[_rID].end;
        mainRestore(_rID, sub_round_[_rID].subTime, sub_round_[_rID].keys);
    }

    // 检查如果冲刺游戏时间结束，但仍标记为未结束时，结束冲刺游戏。
    function checkStopSubRnd() 
        private 
    {
        if (isSubRoundStart) 
        {
            uint256 _rID = sub_round_id_;
            uint256 _now = now;
            if (_now > sub_round_[_rID].strt && (_now <= sub_round_[_rID].end)) 
                _now = _now;
            else
                endSub(_rID);
        }
    }

    // 冲刺游戏结束，主游戏恢复
    function mainRestore(uint256 _sub_rID, uint256 _subTime, uint256 _seconds)
        private 
    {
        // TODO::
        uint256 _rID = main_round_id_;
        // 结束时间推后冲刺游戏的游戏时间
        main_round_[_rID].end = main_round_[_rID].end.add(_subTime);
        // 减去冲刺游戏中缩短的时间
        main_round_[_rID].end = main_round_[_rID].end.sub(_seconds);
        // 直接结束主游戏
        if (main_round_[_rID].end.sub(main_round_[_rID].strt) <= 0) {
            MyFomoDataSet.EventReturns memory _eventData_;
            _eventData_ = endMainRound(_eventData_);
            // TODO::
            emit onMainAndSubTop(
                mainRound, mainRoundStartTime, mainRoundEndTime, mainRoundKey,
                mainRoundeth, mainRoundPot, subRound, subRoundStartTime, 
                subRoundEndTime, subRoundKey, subRoundeth, subRoundPot
            );
        }
        else
            emit onMainRestartSubStop(
                _rID, main_round_[_rID].strt, main_round_[_rID].end, main_round_[_rID].keys,
                main_round_[_rID].eth, main_round_[_rID].pot, _sub_rID, 
                sub_round_[_sub_rID].strt, sub_round_[_sub_rID].strt, sub_round_[_sub_rID].keys,
                sub_round_[_sub_rID].eth, sub_round_[_sub_rID].pot
            );
    }

    /**
     * @dev updates round timer based on number of whole keys bought.
     */
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
        // grab time
        uint256 _now = now;
        
        // calculate time based on number of keys bought
        uint256 _newTime;
        if (_now > main_round_[_rID].end && main_round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)).add(main_round_[_rID].end);
        
        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            main_round_[_rID].end = _newTime;
        else
            main_round_[_rID].end = main_round_[_rID].strt.add(_now);
            // main_round_[_rID].end = main_round_.add(_now); ??
    }

    // 更新冲刺游戏时间
    function updateSubTimer(uint256 _keys, uint256 _rID)
        private
    {
        // calculate time based on number of keys bought
        uint256 _newTime = sub_round_[_rID].strt.add((((_keys) / (1000000000000000000)).mul(subRndDesc_)));
        uint256 _now = now;
        sub_round_[_rID].subTime = sub_round_[_rID].subTime.add(_now.sub(sub_round_[_rID].strt));
        // compare to max and set new end time
        if (_newTime.add(subRndMax_) >= sub_round_[_rID].end) 
            endSub(_rID);
        else
            sub_round_[_rID].strt = _newTime;
    }

     /**
     * @dev 结束一轮主游戏，分配奖金给最终玩家
     */
    function endMainRound(MyFomoDataSet.EventReturns memory _eventData_)
        private
        returns (MyFomoDataSet.EventReturns)
    {
        // 设置主游戏的ID
        uint256 _rID = main_round_id_;
        main_round_[_rID].ended = true;
        
        // 获取当前轮最后一位买入用户
        // TODO: by Leon， 每次买入都需要更新plyr
        address _winAddress = main_round_[_rID].plyr;
        bytes32 _winName = users_[addrUids_[_winAddress]].name;
        
        // 获取可以分给最终用户的奖池金额
        uint256 _pot = main_round_[_rID].pot;
        
        //计算游戏奖池分配 
        // 2%团队开发资金 48%最终赢家 20%下一轮游戏，30%钥匙持有者（这个时本轮的持有者呢 还是最终的持有者）
        uint256 _win = (_pot.mul(48)) / 100; // 最终赢家
        uint256 _dev = (_pot.mul(2)) / 100; // 团队开发基金
        uint256 _nexPot = (_pot.mul(20)/100); /// 下一轮游戏
        uint256 _keyPlr = (_pot.mul(30)/100); /// 钥匙持有分红
        
        // 用户每个key新增股息
        uint256 _ppt = _keyPlr / (main_round_[_rID].keys);
        
        // 设置最终赢家增加金额
        userAmounts_[_winAddress].totalBalance = userAmounts_[_winAddress].totalBalance.add(_win); // 增加总余额
        userAmounts_[_winAddress].withdrawAble = userAmounts_[_winAddress].withdrawAble.add(_win); // 增加可提现总量

        // 团队开发基金
        _opeAmount.devFund = _opeAmount.devFund.add(_dev);
        
        // 分配给key的持有者
        main_round_[_rID].mask = _ppt.add(main_round_[_rID].mask);
        
        // prepare event data;
        _eventData_.winnerAddr = _winAddress;
        _eventData_.winnerName = _winName;
        _eventData_.amountWon = _win;
        _eventData_.newPot = _nexPot;
        
        // start next round
        main_round_id_++;
        _rID++;
        main_round_[_rID].strt = now;
        main_round_[_rID].end = now.add(rndInit_);
        main_round_[_rID].pot = _nexPot;
        
        return(_eventData_);
    }


    function withdrawEarnings(address _pID)
        private
        returns(uint256)
    {
        
        // // from vaults 
        // uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        // if (_earnings > 0)
        // {
        //     plyr_[_pID].win = 0;
        //     plyr_[_pID].gen = 0;
        //     plyr_[_pID].aff = 0;
        // }

        // return(_earnings);
    }

    //==============================================================================
//    (~ _  _    _._|_    .
//    _)(/_(_|_|| | | \/  .
//====================/=========================================================
    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs 
     * have time to set things up on the web end                           
     **/
    function activate()
        public
    {
        // only team just can activate 
        require(
            msg.sender == 0x18E90Fc6F70344f53EBd4f6070bf6Aa23e2D748C ||
            msg.sender == 0x8b4DA1827932D71759687f925D17F81Fc94e3A9D ||
            msg.sender == 0x8e0d985f3Ec1857BEc39B76aAabDEa6B31B67d53 ||
            msg.sender == 0x7ac74Fcc1a71b106F12c55ee8F802C9F672Ce40C ||
			msg.sender == 0xF39e044e1AB204460e06E87c6dca2c6319fC69E3,
            "only team just can activate"
        );
        
        // can only be ran once
        require(activated_ == false, "myfomo already activated");
        
        // activate the contract 
        activated_ = true;
        
        // lets start first round
        main_round_id_ = 1;
        main_round_[1].strt = now + rndInit_;
        main_round_[1].end = now + rndInit_ + rndMax_;
    }

}
