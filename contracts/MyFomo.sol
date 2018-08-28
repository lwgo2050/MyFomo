pragma solidity ^0.4.23;
import "./MyFomoEvents.sol";
import "./MyFomoDataSet.sol";

contract MyFomo {
     bool public activated_ = false;

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

   
   

}
