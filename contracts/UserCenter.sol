pragma solidity ^0.4.24;

import "./library/SafeMath.sol";
import "./library/NameFilter.sol";
import "./library/MSFun.sol";

import "./MyFomoDataSet.sol";
import "./MyFomoEvents.sol";

contract CoreBank {

    MyFomoDataSet.OperationAmount public _opeAmount;                   // 运营资金信息
    mapping(address => MyFomoDataSet.UserAmount) public _userAmounts;  // 用户钱包地址 => 资金信息

}

contract UserCenter is CoreBank {
    using NameFilter for string;
    using SafeMath for uint256;

    uint256 public _uid; // 用户id 从1开始
    mapping(uint256 => MyFomoDataSet.User) public _users; // user id => user
    mapping(address => uint256) public _addrUids; // user address => user id
    mapping(bytes32 => address) public _nameAddr; // user name => user address
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
            if (_addrUids[msg.sender] == 0)   
                isNew = true;
            registCore(msg.sender, name, inviter, isNew);
        } 
    }

    function registWithAddr(address addr) 
        private
    {
        uint256 codeLength;
        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        if (_addrUids[addr] == 0) {
            registCore(addr, "", "", true);
        }
    }

    /**
     * brief: 根据用户名获取用户信息
     * 参数： name 用户名(邀请码)
     * 返回： User 成功时返回表示用户的User对象
     */
    function getUserByName(string name) 
        public 
        returns(address, bytes32, bytes32, uint256)
    {
        MyFomoDataSet.User memory usr = MyFomoDataSet.User(0, "", "", 0);
        if (checkIfNameValid(name))
             usr = _users[_addrUids[_nameAddr[name.nameFilter()]]];

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
        if (_addrUids[addr] != 0)
             usr = _users[_addrUids[addr]];

        return (usr.addr, usr.name, usr.inviterName, usr.inviteNum); 
    }

    /**
     * brief: 根据用户名获取用户资金信息
     * 参数: name 用户名称
     * 返回：UserAmount 成功时返回表示该用户所有资金信息UserAmount的对象
     */
    function getUserAmountByName(string name) public {

    }

    /**
     * brief: 根据用户钱包地址取用户资金信息
     * 参数: add[option] 用户钱包地址, 不传时默认获取用户自身的资金信息
     * 返回：UserAmount 成功时返回表示该用户所有资金信息UserAmount的对象
     */
    function getUserAmountByAddr(address addr) public {

    }

    /**
     * brief: 用户购买钥匙
     * 参数：rId 游戏轮数id
     *      keyNum 钥匙数量
     */
    function buy(uint256 rId, uint256 keyNum) isHuman() 
        public
        payable 
    {

    }

    /**
     * brief: 用户提现
     * 参数: amount 提现数量
     */
    function withdraw(uint256 amount) isHuman()
        public
        payable 
    {

    }

    /**
     * brief: 运营提现, 与用户提现区分，减少风险
     * 参数： amount 提现数量
     */
    function operateWithdraw(uint256 amount) isHuman() isOwner()
        public
        payable
    {

    }
    
    function checkIfNameValid(string nameStr)
        public
        view
        returns(bool)
    {
        bytes32 name = nameStr.nameFilter();
        if (_nameAddr[name] == 0)
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
        if (_nameAddr[name] == 0) {
            return (true);
        } else {
            return (false);
        }
    }

    function registCore(address addr, bytes32 name, bytes32 inviter, bool isNew) 
        private
    {
        uint256 uid = _addrUids[addr];
        if (isNew) {
            uid = _uid;
            if (name != "") {
                _nameAddr[name] = addr;
            }
            _addrUids[addr] = _uid;
            _users[uid] = MyFomoDataSet.User(addr, name, inviter, 0);
            _uid += 1;
        } else {
            _nameAddr[name] = addr;
            _users[uid].name = name;
            _users[uid].inviterName = inviter;
        }
        if (_nameAddr[inviter] == 0) 
            _users[uid].inviterName = "";
        else 
            _users[_addrUids[_nameAddr[inviter]]].inviteNum += 1;

        emit MyFomoEvents.onNewUser(addr, name, _nameAddr[_users[uid].inviterName], _users[uid].inviterName, isNew, now);
        
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