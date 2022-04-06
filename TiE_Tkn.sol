// SPDX-License-Identifier: MIT
//made with love by InvaderTeam <3 :V: 34
pragma solidity ^0.8.13;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event BurnFrom(address indexed minter, uint256 value);
    event Mint(address indexed minter, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b > a) return (false, 0); return (true, a - b); }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b == 0) return (false, 0); return (true, a / b); }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { if (b == 0) return (false, 0); return (true, a % b); }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "SafeMath: subtraction overflow"); return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) return 0; uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: division by zero"); return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: modulo by zero"); return a % b; }
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) { uint256 c = add(a,m); uint256 d = sub(c,1); return mul(div(d,m),m); }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender; } 
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

//contract Role {} //instead? need to understand how exploitable it will be
contract Ownable is Context {
    address private _owner;
    
    event OwnershipRelocated(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        emit OwnershipRelocated(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier ownerRestricted { require(_owner == _msgSender()); _; }

    function renounceOwnership() external ownerRestricted {
        emit OwnershipRelocated(_owner, address(0));
        _owner = address(0);
    }

    function RelocateOwnership(address newOwner) external ownerRestricted {
        require(newOwner != address(0), "Ownable_Danger: new owner is the zero address"); 
        _owner = newOwner;
        emit OwnershipRelocated(_owner, newOwner);
    }
}  

contract Lists is Ownable {
    mapping(address => bool) private _freezer;
    function Unfreeze(address user) public ownerRestricted {
        require(_freezer[user], "user not blacklisted");
        _freezer[user] = false;
    }
    function Freeze(address user) public ownerRestricted {
        require(!_freezer[user], "user already blacklisted");
        _freezer[user] = true;
    }
    function Freezed(address user) internal view returns (bool) {
        return _freezer[user];
    }
}

contract Tie is IERC20, Lists {
    using SafeMath for uint256;    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    string constant private _name = "TieToken 35";
    string constant private _symbol = "TIE35";
    uint256 private  _supply = 50000 * (10 ** 6);
    uint8 constant private _decimals = 6;
    bool private _reentrant_stat = false;

    modifier noReentrancy { require(!_reentrant_stat, "ReentrancyGuard: hijack detected"); _reentrant_stat = true; _; _reentrant_stat = false; }
    
    constructor() {
        _balances[owner()] = _supply;
//        emit Transfer(address(this), owner(), _supply); //we can delete this, seemed nice for debug purposes
    }

    function name() external pure returns(string memory) { return _name; }
    function symbol() external pure returns(string memory) { return _symbol; }
    function decimals() external pure returns(uint8) { return _decimals; }
    function totalSupply() external view override returns(uint256) { return _supply.div(10 ** _decimals); }       
    function balanceOf(address wallet) external view override returns(uint256) { return _balances[wallet]; }
    function subSupply(uint256 amount) private { _supply = _supply.sub(amount); }
    function addSupply(uint256 amount) private { _supply = _supply.add(amount); }

    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        require(_balances[from] >= amount, "Insufficient funds.");
        require(from != address(0), "ERC20: approve from the zero address");
        require(!Freezed(to), "Recipient is blacklisted");
        require(to != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "Empty transactions consume gas as well you moron");
    }
    function afterTokenTransfer(address to, uint256 amount) internal virtual { 
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private noReentrancy {
        beforeTokenTransfer(from, to, amount);
        _balances[from] -= amount;
        _balances[to] += amount;      
        emit Transfer(from, to, amount);
        afterTokenTransfer(to, amount);
    }

    function transfer(address to, uint256 amount) public override returns(bool) {
       _transfer(_msgSender(), to, amount);
       return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {
        beforeTokenTransfer(from, to, amount);
        _transfer(from, to, amount);
        _approve(from, _msgSender(), _allowances[from][_msgSender()]-amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        beforeTokenTransfer(_msgSender(), spender, amount);
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner) external view override returns (uint256) {
        return _allowances[owner][_msgSender()];
    }
    function all_allowance(address owner, address spender) external view ownerRestricted returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]-subValue);
        return true;
    }

    function mint(address account, uint256 amount) external ownerRestricted {       
        _balances[account] += amount;
        addSupply(amount);
        emit Mint(account, amount);
    }

    function burnFrom(address account, uint256 amount) external ownerRestricted {
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount; 
        subSupply(amount);
        emit BurnFrom(account, amount);
    }
    function burn(uint256 amount) external {
        require(_balances[_msgSender()] >= amount, "ERC20: burn amount exceeds balance");
        _balances[_msgSender()] -= amount; 
        subSupply(amount);
        emit Burn(_msgSender(), amount);
    }
}


contract Stake is Tie {
    using SafeMath for uint256;
    uint256 public totalStakes = 0;
    uint256 private stakingFee = 1;
    uint256 private unstakingFee = 3;
    uint256 private totalFeed = 0;
    uint256 private stakingRewardRatio = 1; //0.1%/hour

    struct USER{
        uint256 stakedTokens;
        uint256 creationTime;
        uint256 lastClaim;
        uint256 totalEarned;
    }

    mapping(address => USER) internal stakers;

    event Staked(address staker, uint256 tokens, uint256 stakingFee);
    event Unstaked(address staker, uint256 tokens, uint256 unstakingFee);

    event ClaimedReward(address staker, uint256 reward);

    /*constructor() { //pretty useless now, maybe will find a use later idk
    }*/

    function claimRewardStake(address user) external returns(uint256){
    }

    function currentRewardStake(address user) public view returns(uint256){
        //gotta check and calc the time, maybe add a limiter to let people stake more than that
        //than calc the percentage of tokens they have on the total tokens in the pool in totalStakes var
        //so we can multiply that value for stakingRewardRatio, need to understand if set reward per hour or day
        //when this will be done we will testing how it behaves, if good than adapt to claimRewardStake
        if(stakers[user].stakedTokens > 0){
            uint256 timeStaked = (block.timestamp - stakers[user].creationTime) / 3600;

            uint256 StakedOnTotal = stakers[user].stakedTokens / totalStakes;

            return ((timeStaked * StakedOnTotal) * stakingRewardRatio) / 10; //wtf am I doing .-.
        }
        else{
            return 0;
        }
    }

    function stake(uint256 tokens) external noReentrancy {
        require(transferFrom(_msgSender(), address(this), tokens), "Tokens cannot be transfered from your account");
        uint256 _stackingFee = onePercent(tokens) * stakingFee;
        totalFeed += _stackingFee;
        uint256 feeDeductedTokens = tokens - _stackingFee;
        stakers[_msgSender()].totalEarned += currentRewardStake(_msgSender()); //this will be needed to add the tokens made with the staked tokens so far
        stakers[_msgSender()].stakedTokens += feeDeductedTokens;
        stakers[_msgSender()].creationTime = block.timestamp;
        totalStakes += feeDeductedTokens;
        emit Staked(_msgSender(), feeDeductedTokens, _stackingFee);
    }
    
    function withdrawStake(uint256 tokens) external noReentrancy {
        require(stakers[_msgSender()].stakedTokens >= tokens && tokens > 0, "Invalid token amount to withdraw");
        uint256 _unstakingFee = onePercent(tokens) * unstakingFee;
        totalFeed += _unstakingFee;
        uint256 feeDeductedTokens = tokens - _unstakingFee;
        require(transfer(_msgSender(), feeDeductedTokens), "Error in the un-stacking process, tokens not transferred");
        totalStakes -= feeDeductedTokens;
        emit Unstaked(_msgSender(), feeDeductedTokens, _unstakingFee);
    }

    function onePercent(uint tokens) private pure returns (uint256){
        uint256 rounded = tokens.ceil(100);  //from 0.7- need to try without and see if it works
        return rounded.div(100);
    }
    
    function stakeOf(address staker) external view returns (uint256){
        return stakers[staker].stakedTokens;
    }

}
