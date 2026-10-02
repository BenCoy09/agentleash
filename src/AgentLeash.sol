// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AgentLeash {
    using SafeERC20 for IERC20;

    error NotOwner();
    error NotAgent();
    error Paused();
    error PolicyExpired(uint64 expiry);
    error RecipientNotAllowed(address to);
    error OverPerTxLimit(uint256 amount, uint256 limit);
    error DailyLimitExceeded(uint256 wouldSpend, uint256 limit);

    event PolicySet(string policyText, uint256 perTxLimit, uint256 dailyLimit, uint64 expiry);
    event Paid(address indexed to, uint256 amount, string memo);
    event PausedSet(bool paused);
    event AgentChanged(address agent);

    address public immutable owner;
    IERC20 public immutable token;
    address public agent;

    uint256 public perTxLimit;
    uint256 public dailyLimit;
    uint64 public expiry;
    bool public paused;
    string public policyText;

    mapping(address => bool) public allowed;

    uint256 public spentToday;
    uint64 public dayStart;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address _token, address _agent) {
        owner = msg.sender;
        token = IERC20(_token);
        agent = _agent;
        dayStart = uint64(block.timestamp);
    }

    function setPolicy(
        uint256 _perTxLimit,
        uint256 _dailyLimit,
        uint64 _expiry,
        address[] calldata _allowed,
        string calldata _policyText
    ) external onlyOwner {
        perTxLimit = _perTxLimit;
        dailyLimit = _dailyLimit;
        expiry = _expiry;
        policyText = _policyText;
        for (uint256 i = 0; i < _allowed.length; i++) {
            allowed[_allowed[i]] = true;
        }
        emit PolicySet(_policyText, _perTxLimit, _dailyLimit, _expiry);
    }

    function setAllowed(address to, bool ok) external onlyOwner {
        allowed[to] = ok;
    }

    function setAgent(address _agent) external onlyOwner {
        agent = _agent;
        emit AgentChanged(_agent);
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PausedSet(_paused);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function pay(address to, uint256 amount, string calldata memo) external {
        if (msg.sender != agent) revert NotAgent();
        if (paused) revert Paused();
        if (block.timestamp > expiry) revert PolicyExpired(expiry);
        if (!allowed[to]) revert RecipientNotAllowed(to);
        if (amount > perTxLimit) revert OverPerTxLimit(amount, perTxLimit);

        if (block.timestamp >= dayStart + 1 days) {
            dayStart = uint64(block.timestamp);
            spentToday = 0;
        }
        uint256 newTotal = spentToday + amount;
        if (newTotal > dailyLimit) revert DailyLimitExceeded(newTotal, dailyLimit);

        spentToday = newTotal;
        token.safeTransfer(to, amount);
        emit Paid(to, amount, memo);
    }

    function remainingToday() external view returns (uint256) {
        if (block.timestamp >= dayStart + 1 days) return dailyLimit;
        return dailyLimit > spentToday ? dailyLimit - spentToday : 0;
    }
}
