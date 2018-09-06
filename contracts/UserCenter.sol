pragma solidity ^0.4.24;

import "./library/SafeMath.sol";
import "./library/NameFilter.sol";
import "./library/MSFun.sol";

import "./MyFomoDataSet.sol";
import "./MyFomoEvents.sol";

contract CoreBank is MyFomoEvents {
    MyFomoDataSet.OperationAmount public _opeAmount;                   // 运营资金信息
    mapping(address => MyFomoDataSet.UserAmount) public userAmounts_;  // 用户钱包地址 => 资金信息
}

contract UserCenter is CoreBank {
    using NameFilter for string;
    using SafeMath for uint256;

    uint256 public _uid; // 用户id 从1开始
    mapping(uint256 => MyFomoDataSet.User) public users_; // user id => user
    mapping(address => uint256) public addrUids_; // user address => user id
    mapping(bytes32 => address) public nameAddr_; // user name => user address
    mapping(address => uint256) public _admins; // admin users

    constructor()
        public
    {
        _uid = 1;
    }

    /**
     * brief: 注册用户名（邀请码）
     * 参数：*name 用户自主输入的字符串，不超过32个字符并且会做唯一性检查
     */
    function registWithName(string nameStr, string inviterStr) 
        public
        payable
        isHuman()
    {
        if (checkIfNameValid(nameStr)) {
            bytes32 name = nameStr.nameFilter();
            bytes32 inviter = inviterStr.nameFilter();
            bool isNew = false;
            if (addrUids_[msg.sender] == 0)   
                isNew = true;
            registCore(msg.sender, name, inviter, isNew);
        } 
    }

    function registWithAddr(address addr) 
        public
    {
        uint256 codeLength;
        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        if (addrUids_[addr] == 0) {
            registCore(addr, "", "", true);
        }
    }

    /**
     * brief: 根据用户名获取用户信息
     * 参数： name 用户名(邀请码)
     * 返回： User 成功时返回表示用户的User对象
     * address addr;           // 用户钱包地址
     * bytes32 name;           // 用户名(邀请码)
     * bytes32 inviterName;    // 邀请人名称
     * uint256 inviteNum;      // 该用户邀请的人数
     */
    function getUserByName(string name) 
        public 
        returns(address, bytes32, bytes32, uint256)
    {
        MyFomoDataSet.User memory usr = MyFomoDataSet.User(0, "", "", 0);
        if (checkIfNameValid(name))
             usr = users_[addrUids_[nameAddr_[name.nameFilter()]]];

        return (usr.addr, usr.name, usr.inviterName, usr.inviteNum); 
    }

    /**
     * brief: 根据用户钱包地址获取用户信息
     * 参数： addr[option] 用户钱包地址, 不传时默认获取用户自身的信息
     * 返回： User 成功时返回表示用户的User对象
    */
    function getUserByAddr(address addr) 
        public 
        returns(address, bytes32, bytes32, uint256)
    {
        MyFomoDataSet.User memory usr = MyFomoDataSet.User(0, "", "", 0);
        if (addrUids_[addr] != 0)
             usr = users_[addrUids_[addr]];

        return (usr.addr, usr.name, usr.inviterName, usr.inviteNum); 
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
    function getUserAmountByName(string name) 
        public 
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        MyFomoDataSet.UserAmount memory amt = MyFomoDataSet.UserAmount(0,0,0,0,0,0,0,0,0);
        if (userExist(name))
            amt = userAmounts_[nameAddr_[name.nameFilter()]];
        
        return (
            amt.totalKeys, amt.totalBet, amt.lastKeys, 
            amt.lastBet, amt.totalBalance, amt.withdrawAble,
            amt.withdraw, amt.totalProfit, amt.inviteProfit
        );
    }

    /**
     * brief: 根据用户钱包地址取用户资金信息
     * 参数: add[option] 用户钱包地址, 不传时默认获取用户自身的资金信息
     * 返回：UserAmount 成功时返回表示该用户所有资金信息UserAmount的对象
     */
    function getUserAmountByAddr(address addr)
        public 
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        MyFomoDataSet.UserAmount memory amt = MyFomoDataSet.UserAmount(0,0,0,0,0,0,0,0,0);
        if (addrUids_[addr] != 0)
            amt = userAmounts_[addr];
        
        return (
            amt.totalKeys, amt.totalBet, amt.lastKeys, 
            amt.lastBet, amt.totalBalance, amt.withdrawAble,
            amt.withdraw, amt.totalProfit, amt.inviteProfit
        );
    }
    
    function checkIfNameValid(string nameStr)
        public
        view
        returns(bool)
    {
        bytes32 name = nameStr.nameFilter();
        if (nameAddr_[name] == 0)
            return (true);
        else 
            return (false);
    }

    function userExist(string nameStr) 
        public
        view
        returns(bool)
    {
        bytes32 name = nameStr.nameFilter();
        if (nameAddr_[name] == 0) {
            return (true);
        } else {
            return (false);
        }
    }

    function registCore(address addr, bytes32 name, bytes32 inviter, bool isNew) 
        private
    {
        uint256 uid = addrUids_[addr];
        if (isNew) {
            uid = _uid;
            if (name != "") {
                nameAddr_[name] = addr;
            }
            addrUids_[addr] = _uid;
            users_[uid] = MyFomoDataSet.User(addr, name, inviter, 0);
            _uid += 1;
        } else {
            nameAddr_[name] = addr;
            users_[uid].name = name;
            users_[uid].inviterName = inviter;
        }
        if (nameAddr_[inviter] == 0) 
            users_[uid].inviterName = "";
        else 
            users_[addrUids_[nameAddr_[inviter]]].inviteNum += 1;

        emit onNewUser(addr, name, nameAddr_[users_[uid].inviterName], users_[uid].inviterName, isNew, now);
        
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isOwner() {
        address addr = msg.sender;
        require(_admins[addr] != 0, "sorry, owners only");
        _;
    }
        
}