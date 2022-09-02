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
        uint256 odds;
        uint256 totalBetAmount;
    }

    Status private status;
    Pick[2] public picks;
    uint256 public total;
    Counters.Counter public pickOneBetCount;
    Counters.Counter public pickTwoBetCount;
    mapping(address => uint256) pickOneBetAmounts;
    mapping(address => uint256) pickTwoBetAmounts;
    mapping(address => uint256) earnings;
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

    function updateOdds(uint256 pickOneOdds, uint256 pickTwoOdds) public onlyOwner {
        picks[0].odds = pickOneOdds;
        picks[1].odds = pickTwoOdds;
    }

    function setWinner(uint256 _winner) public onlyOwner {
        require(status == Status.Closed, "Status must be closed to set winner");
        require(_winner == 0 || _winner == 2, "Winner selection must be 0 or 1");
        setStatus(Status.Ended);
        picks[_winner].winner = true;
        handlePayout(_winner);
    }

    function handlePayout(uint256 pick) internal nonReentrant {
        if ( pick == 0 ){
            for (uint i = 0; i < betterAddresses.length; i++) {
                uint256 percentValue = pickOneBetAmounts[betterAddresses[i]] /  picks[0].totalBetAmount; //percentage deposited
                earnings[betterAddresses[i]] = picks[1].totalBetAmount * percentValue; // amount earned

                // payout both betamount + earnings
            }
        } else {
            for (uint i = 0; i < betterAddressesTwo.length; i++) {
                uint256 percentValue = pickTwoBetAmounts[betterAddressesTwo[i]] /  picks[1].totalBetAmount;
                earnings[betterAddressesTwo[i]] = picks[0].totalBetAmount * percentValue;

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
                pickOneBetCount.increment();
                addBetterAddress(payable(msg.sender));
            }
        } else {
            picks[1].totalBetAmount += _amount; 
            pickTwoBetAmounts[msg.sender] += _amount;
            if (pickTwoBetAmounts[msg.sender] == 0) { // handle new better address
                pickTwoBetCount.increment();
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

        // uint256 payment = _deposits[payee];

        // _deposits[payee] = 0;

        // payee.sendValue(payment);

        // emit Withdrawn(payee, payment);
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