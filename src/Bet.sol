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

    Status private status;

    struct Pick {
        string name;
        // string imageUrl;
        bool winner;
        uint256 odds;
        uint256 totalBetAmount;
        uint256 totalBetterCount;
        // address payable[] betterAddresses;
    }

    Pick[2] picks;
    Counters.Counter private pickOneBetCount;
    Counters.Counter private pickTwoBetCount;
    mapping(address => uint256) pickOneBetAmounts;
    mapping(address => uint256) pickTwoBetAmounts;

    constructor(string memory _pickOne, string memory _pickTwo) {
        picks[0] = Pick(_pickOne, false, 0, 0, pickOneBetCount.current());
        picks[1] = Pick(_pickTwo, false, 0, 0, pickTwoBetCount.current());
        setStatus(Status.Open);
    }

    function setStatus(Status _status) public onlyOwner {
        status = _status;
    }

    function updateOdds(uint256 pickOneOdds, uint256 pickTwoOdds) public onlyOwner {
        picks[0].odds = pickOneOdds;
        picks[1].odds = pickTwoOdds;
    }

    function setWinner(uint256 _winner) public onlyOwner {
        require(status == Status.Closed, "Status must be closed to set winner");
        require(_winner == 1 || _winner == 2, "Winner selection must be 1 or 2");
        if (_winner == 1) {
            // calculate earnings and pay out
        } else {

        }
    }

    function handlePayout() internal {

    }

    function placeBet(uint256 _pick, uint256 _amount) external {
        require(status == Status.Open, "This contract is no longer taking bets");
        require(_pick == 1 || _pick == 2, "Pick selection must be 1 or 2");
        require(_amount > 0, "Bet amount must be greater than 0");
        if (_pick == 1) {
            picks[0].totalBetAmount += _amount;
            if (pickOneBetAmounts[msg.sender] == 0) { // handle new better address
                pickOneBetCount.increment();
                picks[0].totalBetterCount = pickOneBetCount.current();
            }
            pickOneBetAmounts[msg.sender] += _amount;
        } else {
            picks[1].totalBetAmount += _amount;
            if (pickTwoBetAmounts[msg.sender] == 0) { // handle new better address
                pickTwoBetCount.increment();
                picks[1].totalBetterCount = pickTwoBetCount.current();
            }
            pickTwoBetAmounts[msg.sender] += _amount;
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


}