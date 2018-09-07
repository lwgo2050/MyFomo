pragma solidity ^0.4.24;

contract MyFomoEvents {
     // 冲刺阶段，主游戏暂停，冲刺游戏启动
    event onMainPauseSubStart(
        uint256 mainRound, // 主游戏轮数
        uint256 mainRoundStartTime, // 主游戏开始时间
        uint256 mainRoundEndTime, // 主游戏结束时间
        uint256 mainRoundKey, // 主游戏钥匙数
        uint256 mainRoundeth, // 主游戏eth总购买量
        uint256 mainRoundPot, // 主游戏的总奖池，可用于分配的
        uint256 subRound, // 冲刺游戏的轮数
        uint256 subRoundStartTime, // 冲刺游戏开始时间
        uint256 subRoundEndTime, // 冲刺结束时间
        uint256 subRoundKey, // 冲刺阶段钥匙数
        uint256 subRoundeth, // 冲刺阶段的eth
        uint256 subRoundPot // 冲刺阶段奖池
    );

  // 冲刺结束，主游戏重新启动
    event onMainRestartSubStop(
        uint256 mainRound, // 主游戏轮数
        uint256 mainRoundStartTime, // 主游戏开始时间
        uint256 mainRoundEndTime, // 主游戏结束时间
        uint256 mainRoundKey, // 主游戏钥匙数
        uint256 mainRoundeth, // 主游戏eth总购买量
        uint256 mainRoundPot, // 主游戏的总奖池，可用于分配的
        uint256 subRound, // 冲刺游戏的轮数
        uint256 subRoundStartTime, // 冲刺游戏开始时间
        uint256 subRoundEndTime, // 冲刺结束时间
        uint256 subRoundKey, // 冲刺阶段钥匙数
        uint256 subRoundeth, // 冲刺阶段的eth
        uint256 subRoundPot // 冲刺阶段奖池
    );

    // 游戏启动
    event onGameActive(uint256 timestamp);

    //-----------------------------------------------
    event onNewUser (
        address indexed uaddr,          // 用户地址
        bytes32 indexed uname,          // 用户名称
        address indexed inviterAddr,    // 邀请人的地址
        bytes32 inviterName,            // 邀请人的名称
        bool isNewPlayer,               // 是否新用户（可能在注册前直接通过address购买过key）
        uint256 timeStamp               // 时间戳
    );

    event onUserBuy (
        address indexed uaddr,          // 用户地址
        address indexed uname,          // 用户名称
        address indexed inviterAddr,    // 邀请人地址
        address inviterName,            // 邀请人名称
        uint256 roundId,                // 游戏轮数id
        uint256 keyNum,                 // 购买的钥匙数量 
        uint256 payed,                  // 支付的eth数量
        uint256 total,                  // 奖池总量
        uint256 dividend,               // 分红总量
        uint256 winerBonus,             // 最终赢家可获得奖金
        uint256 winerkeys,             // 奖池的key数量
        uint256 timeStamp               // 时间戳
    );

    // fired whenever theres a withdraw
    event onWithdraw
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

     // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot
    );

    event onMainAndSubStop
    (
        address subWinnerAddr,
        bytes32 subWinnerName,
        uint256 subBonus,
        address winnerAddr,
        bytes32 winderName,
        uint256 newPot

    );

}