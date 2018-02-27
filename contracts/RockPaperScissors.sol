pragma solidity ^0.4.19;

import "./BettingEngine.sol";

contract RockPaperScissors is BettingEngine {

  // ----------------------------------------------------
  // Internal state of the contract

  // Data type of what move the player has declared
  enum Move { NOTHING, ROCK, PAPER, SCISSORS }

  // Players' declared secret moves
  mapping (address => bytes32) secretPlayerMove;
  uint8 playersDeclaredSecretMove = 0;

  // Players' actual moves
  mapping (address => Move) playerMove;
  uint8 playersDeclaredActualMove = 0;

  // the time the first number was revealed
  uint revelationTime = 0;
  uint constant timeoutToDeclareDefaultWin = 30 minutes;

  // Data type for game state
  enum GamePhase { NO_GAME, SECRET, REVEAL }

  // State of the game
  GamePhase currentGamePhase = GamePhase.NO_GAME;

  // ----------------------------------------------------
  // Modifiers

  // check whether the caller is participating in the game
  modifier isPlayer() 
  {
    require (playerMode[msg.sender] == PlayerMode.AntePlaced);
    _;
  }

  modifier inGamePhase(GamePhase _gamePhase)
  {
    require (currentGamePhase == _gamePhase);
    _;
  }

  // ----------------------------------------------------
  // Contract events

  event StartingDeclareSecretPhase();
  event StartingRevealPhase();
  event WinnerDeclared(address winner);
  event DrawDeclared();

  // ----------------------------------------------------
  // Public API to access contract

  // Start playing the game (has to be done after the players
  // register and pay the ante).
  function startPlaying() public
    isPlayer
    gameNotInProgress
  {
    startGame();
    if (gameStarted) 
    {
        StartingDeclareSecretPhase();
        currentGamePhase = GamePhase.SECRET;
    }
  }

  // Player declares his secret move.
  // If the game has moved the reveal phase, returns true and send appropriate event.
  // Otherwise return false.
  function declareSecretMove(bytes32 _secretMove) public 
    isPlayer
    inGamePhase(GamePhase.SECRET)
    returns (bool)
  {
    // keep count of how many sent their secret number
    if (secretPlayerMove[msg.sender] == "") 
    { 
      playersDeclaredSecretMove++; 
    }
    
    // remember the secret
    secretPlayerMove[msg.sender] = _secretMove;

    // decide whether or not to move to the reveal phase
    if (playersDeclaredSecretMove==2) 
    { 
        currentGamePhase = GamePhase.REVEAL; 
        StartingRevealPhase();
        return true;
    }
    return false;
  }

  // Player reveals his actual move.
  function revealActualMove(uint256 _actualMove) public
    isPlayer
    inGamePhase(GamePhase.REVEAL)
  {
    // The player has not yet revealed his value
    require (playerMove[msg.sender] == Move.NOTHING);

    // if the number does not match the secret, automatically lose
    if (keccak256(_actualMove) != secretPlayerMove[msg.sender]) 
    {
      declareWinner(otherPlayer(msg.sender));
      return;
    }

    // remember the move
    playersDeclaredActualMove++;
    playerMove[msg.sender] = numberToMove(_actualMove);

    // If both players revealed end the game, otherwise remember 
    // the time the first player revealed his/her number.
    if (playersDeclaredActualMove==2) 
    {
      decideGameResult();
    } else {
      revelationTime = now;
    }
  }

  // Player who revealed first gets tired of waiting and calls
  // for a default win by timeout.
  function declareDefaultWin() public
    isPlayer
    inGamePhase(GamePhase.REVEAL)
  {
    require (
      (playersDeclaredActualMove == 1) &&
      (playerMove[msg.sender] != Move.NOTHING) &&
      (now - revelationTime > timeoutToDeclareDefaultWin)
    );

    declareWinner(msg.sender);
  }

  // ----------------------------------------------------
  // Private functions to handle winning and draws
  
  // Logic to signal end of game and prepare to start 
  // playing again
  function endOfGame() private
  {
    // reset variables in this contract
    currentGamePhase = GamePhase.NO_GAME;

    revelationTime = 0;

    playersDeclaredActualMove = 0;
    playerMove[registeredPlayers[0]] = Move.NOTHING;
    playerMove[registeredPlayers[1]] = Move.NOTHING;

    playersDeclaredSecretMove = 0;
    secretPlayerMove[registeredPlayers[0]] = "";
    secretPlayerMove[registeredPlayers[1]] = "";

    // tell betting engine that the game is over
    finishGame();
  }

  // Identify winner
  function declareWinner(address _player) private
  {
    giveWinnings(_player, 100-housePercentage);
    endOfGame();
    WinnerDeclared(_player);
  }

  // Declare the game is a draw
  function declareDraw() private
  {
    giveWinnings(registeredPlayers[0], (100-housePercentage)/2);
    giveWinnings(registeredPlayers[1], (100-housePercentage)/2);
    endOfGame();
    DrawDeclared();
  }

  // After both players have won, decide who has won (or whether it
  // it is a draw).
  function decideGameResult() private 
  {
    // get the moves
    uint p1 = uint(playerMove[registeredPlayers[0]]); // note player 1 is the first added player
    uint p2 = uint(playerMove[registeredPlayers[1]]);

    // decide the result
    uint result = (p1 + 3 - p2 ) % 3;  // 0 tie, 1 p1 wins, 2 p2 wins

    // act accordingly
    if (result==0)
    {
      declareDraw();
    } else {
      declareWinner(registeredPlayers[result-1]);
    }
  }

  // ----------------------------------------------------
  // Helper functions
  //
  // Compute the other player's address
  function otherPlayer(address _player) view private returns (address)
  {
    return ((_player == registeredPlayers[0])?registeredPlayers[1]:registeredPlayers[0]);
  }

  // How to decode a number as an actual move
  function numberToMove(uint256 _number) pure public returns (Move)
  {
    // n % 3 --> 0: ROCK, 1: PAPER, 2: SCISSORS
    return (Move(1 + _number % 3));
  }


}
