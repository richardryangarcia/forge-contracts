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
        bool winner;
        string name;
        int odds;
        uint256 totalBet;
        Counters.Counter betters;
    }

    Pick[2] picks;

    constructor() {
        setStatus(Status.Open);
    }

    function setStatus(Status _status) public onlyOwner {
        status = _status;
    }

    // create matchup

    function createMatchup() public onlyOwner {

    }

    function setWinner(uint256 _winner) public onlyOwner {
        require(status == Status.Closed, "Status must be closed to set winner");
        require(_winner == 1 || _winner == 2, "Winner selection must be 1 or 2");
        if (_winner == 1) {

        } else {

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