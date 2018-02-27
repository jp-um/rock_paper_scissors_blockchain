pragma solidity ^0.4.19;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/RockPaperScissors.sol";

contract TestRockPaperScissors {
    RockPaperScissors rps = RockPaperScissors(DeployedAddresses.RockPaperScissors());

    address p1Address = 0x01;
    address p2Address = 0x02;

    // Testing the adopt() function
    function testAddPlayer() public {
        rps.addPlayer(p1Address);
        rps.addPlayer(p2Address);
    }


    function testTakeTurn() public {
        rps.takeTurn(p1Address, RockPaperScissors.Turn.ROCK);
    }

    function testGameResults() public {
        rps.takeTurn(p1Address, RockPaperScissors.Turn.ROCK);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.SCISSORS);
        Assert.equal(rps.gameResult(), 1, "p1 rock p2 scissors p1 wins");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.PAPER);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.ROCK);
        Assert.equal(rps.gameResult(), 1, "p1 paper p2 rock p1 wins");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.SCISSORS);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.PAPER);
        Assert.equal(rps.gameResult(), 1, "p1 scissors p2 paper p1 wins");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.ROCK);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.ROCK);
        Assert.equal(rps.gameResult(), 0, "p1 rock p2 rock draw");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.PAPER);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.PAPER);
        Assert.equal(rps.gameResult(), 0, "p1 paper p2 rock draw");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.SCISSORS);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.SCISSORS);
        Assert.equal(rps.gameResult(), 0, "p1 scissors p2 paper draw");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.SCISSORS);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.ROCK);
        Assert.equal(rps.gameResult(), 2, "p1 scissors p2 rock p2 wins");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.ROCK);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.PAPER);
        Assert.equal(rps.gameResult(), 2, "p1 paper p2 rock p2 wins");

        rps.takeTurn(p1Address, RockPaperScissors.Turn.PAPER);
        rps.takeTurn(p2Address, RockPaperScissors.Turn.SCISSORS);
        Assert.equal(rps.gameResult(), 2, "p1 paper p2 scissors p2 wins");
    }


}