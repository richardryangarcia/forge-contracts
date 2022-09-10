// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";

contract Bet is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address payable;

    enum Status {
        Open, 
        Closed, 
        Ended
    }

    struct Pick {
        string name;
        string imageUrl;
        bool winner;
        int odds;
        uint256 totalBetAmount;
    }

    Status private status;
    Pick[2] public picks;
    uint256 public total;
    mapping(address => uint256) pickOneBetAmounts;
    mapping(address => uint256) pickTwoBetAmounts;
    mapping(address => uint256) earnings;
    uint256 public earningsTotal; 
    address payable[] public betterAddresses;
    address payable[] public betterAddressesTwo;

    constructor(string memory _pickOne, string memory _pickTwo) {
        picks[0] = Pick(_pickOne,"", false, 0, 0);
        picks[1] = Pick(_pickTwo,"", false, 0, 0);
        setStatus(Status.Open);
    }

    function closeBetting() public onlyOwner {
        setStatus(Status.Closed);
    }

    function updateOdds(int pickOneOdds, int pickTwoOdds) public onlyOwner {
        picks[0].odds = pickOneOdds;
        picks[1].odds = pickTwoOdds;
    }

    function setWinner(uint256 _winner) public onlyOwner {
        require(status == Status.Closed, "Status must be closed to set winner");
        require(_winner == 0 || _winner == 2, "Winner selection must be 0 or 1");
        setStatus(Status.Ended);
        picks[_winner].winner = true;
        handleAllocations(_winner);
        handlePayout(_winner);
    }

    function handlePayout(uint256 pick ) internal nonReentrant {
        if ( pick == 0 ){
            for (uint i = 0; i < betterAddresses.length; i++) { 
                uint percentage = picks[1].totalBetAmount / earningsTotal;
                uint finalEarnings = earnings[betterAddresses[i]] * percentage;
                (bool success,) = betterAddresses[i].call{value: finalEarnings}("");
                require(success, "failed to send eth");
            } 
        } else {
            for (uint i = 0; i < betterAddressesTwo.length; i++) { 
                uint percentage = picks[0].totalBetAmount / earningsTotal;
                uint finalEarnings = earnings[betterAddresses[i]] * percentage;
               (bool success,) =  betterAddressesTwo[i].call{value: finalEarnings}("");
               require(success, "failed to send eth");
            } 
        }
    }

    function handleOddsPayoutFavorite(int pickOdds, uint betAmount, address payable betterAddress) internal nonReentrant {
        uint payoutAmount = uint(int(betAmount) / (-1 * pickOdds / 100));
        earningsTotal += payoutAmount + betAmount;
        earnings[betterAddress] = payoutAmount;
    }

    function handleOddsPayoutUnderdog(int pickOdds, uint betAmount, address payable betterAddress) internal nonReentrant {
        uint payoutAmount = uint(int(betAmount) * (pickOdds / 100));
        earningsTotal += payoutAmount + betAmount;
        earnings[betterAddress] = payoutAmount;
    }

    function handleNoOddsPayout(uint betAmount, uint256 winnerBetsAmount, uint256 loserBetsAmount, address payable betterAddress) internal nonReentrant {
        uint percentValue = betAmount /  winnerBetsAmount;
        uint payoutAmount = loserBetsAmount * percentValue;
        earningsTotal += payoutAmount + betAmount;
        earnings[betterAddress] = payoutAmount;
    }

    function handleAllocations(uint256 pick) internal nonReentrant {
        if ( pick == 0 ){
            for (uint i = 0; i < betterAddresses.length; i++) {
                if (picks[0].odds > 0) {
                    handleOddsPayoutUnderdog(picks[0].odds, pickOneBetAmounts[betterAddresses[i]], betterAddresses[i]);
                } else if (picks[0].odds < 0) {
                    handleOddsPayoutFavorite(picks[0].odds, pickOneBetAmounts[betterAddresses[i]], betterAddresses[i]);
                } else {
                    handleNoOddsPayout(pickOneBetAmounts[betterAddresses[i]], picks[0].totalBetAmount, picks[1].totalBetAmount, betterAddresses[i]);
                }

                // payout both betamount + earnings
            }
        } else {
            for (uint i = 0; i < betterAddressesTwo.length; i++) {
                if (picks[1].odds > 0) {
                    handleOddsPayoutUnderdog(picks[1].odds, pickTwoBetAmounts[betterAddressesTwo[i]], betterAddressesTwo[i]);
                } else if (picks[0].odds < 0) {
                    handleOddsPayoutFavorite(picks[1].odds, pickTwoBetAmounts[betterAddressesTwo[i]], betterAddressesTwo[i]);
                } else {
                    handleNoOddsPayout(pickTwoBetAmounts[betterAddressesTwo[i]], picks[1].totalBetAmount, picks[0].totalBetAmount, betterAddressesTwo[i]);
                }

                // payout both betamount + earnings
            }
        }
    }

    function placeBet(uint256 _pick, uint256 _amount) external nonReentrant {
        require(status == Status.Open, "This contract is no longer taking bets");
        require(_pick == 0 || _pick == 1, "Pick selection must be 0 or 1");
        require(_amount > 0, "Bet amount must be greater than 0");
        total += _amount;
        if (_pick == 0) {
            picks[0].totalBetAmount += _amount;
            pickOneBetAmounts[msg.sender] += _amount;
            if (pickOneBetAmounts[msg.sender] == 0) { // handle new better address
                addBetterAddress(payable(msg.sender));
            }
        } else {
            picks[1].totalBetAmount += _amount; 
            pickTwoBetAmounts[msg.sender] += _amount;
            if (pickTwoBetAmounts[msg.sender] == 0) { // handle new better address
                addBetterAddressTwo(payable(msg.sender));
            }
        }
    }

    /**
     * @dev Payout accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual nonReentrant onlyOwner {
        require(status == Status.Ended, "Status must be ended to disperse balances");

        address payable payableOwner = payable(owner());
        (bool success, ) = payableOwner.call{value: 1}("");

        require(success, "failed to withdraw eth");
    }


    /** internal functions **/

    function addBetterAddress(address payable userAddress) internal {
        betterAddresses.push(userAddress);
    }

    function addBetterAddressTwo(address payable userAddress) internal {
        betterAddressesTwo.push(userAddress);
    }

    function setStatus(Status _status) internal {
        status = _status;
    }

}