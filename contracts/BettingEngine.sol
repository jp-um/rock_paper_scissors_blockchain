pragma solidity ^0.4.19;


contract BettingEngine 
{
  uint8 constant MIN_PLAYER_COUNT = 2;
  uint8 constant MAX_PLAYER_COUNT = 2;

  // the percentage of the funds the house keeps
  uint8 housePercentage = 5;

  // address of the house
  address houseAddress = 0x000000; 

  // value of ante to be placed to participate in game
  uint betValue = 0.01 ether;

  // Players can be unknown, registered but no bet placed, or bet placed
  enum PlayerMode {Unknown, Registered, AntePlaced}

  // how many players have registered and placed ante
  uint8 registeredPlayerCount = 0;
  uint8 paidPlayerCount = 0;

  // has game started?
  bool gameStarted = false;

  // the players who registered
  address[MAX_PLAYER_COUNT] registeredPlayers;

  // gives the mode of a player (identified by address) 
  mapping (address => PlayerMode) playerMode; 

  // the percentage of the money already taken out
  uint8 percentageTaken = housePercentage;

  // money placed in the current game by the players
  uint initialGameMoney;
  uint remainingGameMoney;

  // internal bank accounts
  mapping (address => uint) anteBalances;
  mapping (address => uint) bankBalances; 

  // Constructor gives the house ownership to the caller
  function BettingEngine() public
  {
    houseAddress = msg.sender;
  }

  // check enough money was sent
  modifier costs(uint _value) 
  {
    require (msg.value >= _value);
    _;
  }

  // check player mode
  modifier playerModeIs(address _player, PlayerMode _playerMode) 
  {
    if (playerMode[_player] == _playerMode) {
      _;
    }
  }


  // check whether all players placed an ante
  modifier allPlayersPlacedAnte()  
  {
    if (
      // enough players
      (registeredPlayerCount >= MIN_PLAYER_COUNT) && 
      // all players paid
      (paidPlayerCount == registeredPlayerCount)
    ) {
      _;
    }
  }

  // ensure that a game is in progress
  modifier gameInProgress() 
  {
    if (gameStarted) {
      _;
    }
  }

  // ensure no game is in progress
  modifier gameNotInProgress() 
  {
    if (!gameStarted) {
      _;
    }
  }

  // Events to keep track what is going on in the contract
  event PlayerRegistered(address player);
  event PlayerPaidAnte(address player);
  event PlayerWithdrewAnte(address player);
  event AllowGameToStart();
  event IdentifyPlayerWinnings(address player, uint256 amount);
  event PlayerWithdrawsMoney(address player, uint256 amount);
  event RestartingRegistrationPhase();

  // to check - todo  
  // what happens to extra players when a game start occurs
  function isGameReadyToStart() view public returns (bool) {
    return gameStarted;
  }

  function getRegisteredPlayers() view public returns (address[MAX_PLAYER_COUNT])
  {
    return registeredPlayers;
  }

  function getRegisteredPlayersWithPaidAnte() view public returns (address[MAX_PLAYER_COUNT])
  {
    address[MAX_PLAYER_COUNT] memory result;
    uint pos = 0;
    
    for (uint i=0; i<registeredPlayerCount; i++) {
      if (playerMode[registeredPlayers[i]] == PlayerMode.AntePlaced) { 
        result[pos] = registeredPlayers[i];
        pos++;
      }
    }

    return result;
  }

  // register a new player
  function registerPlayer() public 
    gameNotInProgress
    playerModeIs(msg.sender, PlayerMode.Unknown) 
  {
    if (registeredPlayerCount < MAX_PLAYER_COUNT) 
    {
      registeredPlayers[registeredPlayerCount]=msg.sender;
      registeredPlayerCount++; 

      playerMode[msg.sender] = PlayerMode.Registered;

      // Create the relevant event
      PlayerRegistered(msg.sender);
    }
  }

  // player places ante
  function placeAnte() public payable 
    gameNotInProgress
    playerModeIs(msg.sender, PlayerMode.Registered) 
    costs(betValue)
  {
    playerMode[msg.sender] = PlayerMode.AntePlaced;
    anteBalances[msg.sender] = msg.value;

    // Store the money placed on the current game
    initialGameMoney += msg.value;
    remainingGameMoney += msg.value;

    // Create the relevant event
    PlayerPaidAnte(msg.sender);
  }

  // player withdraws ante
  function withdrawAnte() public
    gameNotInProgress
    playerModeIs(msg.sender, PlayerMode.AntePlaced)
  {
    uint amount = anteBalances[msg.sender];

    anteBalances[msg.sender] = 0;
    initialGameMoney -= amount;
    remainingGameMoney -= amount;

    msg.sender.transfer(amount);

    // Create the relevant event
    PlayerWithdrewAnte(msg.sender);
  }

  // declare winner of what percentage of the original ante
  function giveWinnings(address _winner, uint8 _percentage) internal 
    gameInProgress
  {
    require(_percentage + percentageTaken <= 100);

    percentageTaken += _percentage;

    // give percentage to house 
    uint amountToPayOut = max(remainingGameMoney, initialGameMoney * _percentage / 100);
    remainingGameMoney -= amountToPayOut;
    bankBalances[_winner] += amountToPayOut;

    // Create the relevant event
    IdentifyPlayerWinnings(_winner, amountToPayOut);
  }

  // start game
  function startGame() internal 
    gameNotInProgress
    allPlayersPlacedAnte
  {
    gameStarted = true;

    // give percentage to house 
    uint amountToPayOut = max(remainingGameMoney, initialGameMoney * housePercentage / 100);
    remainingGameMoney -= amountToPayOut;
    bankBalances[houseAddress] += amountToPayOut;

    // Create the relevant event
    AllowGameToStart();
  }

  // end of game
  function finishGame() internal
    gameInProgress
  {
    // return any remaining funds to the house
    bankBalances[houseAddress] += remainingGameMoney;

    // reset values
    gameStarted = false;

    betValue = 0.01 ether;
    registeredPlayerCount = 0;
    paidPlayerCount = 0;

    for (uint i=0; i<registeredPlayerCount; i++) {
      playerMode[registeredPlayers[i]] = PlayerMode.Unknown;
      anteBalances[registeredPlayers[i]] = 0;
    }

    remainingGameMoney = 0;
    initialGameMoney = 0;
    percentageTaken = housePercentage;

    // Create the relevant event
    RestartingRegistrationPhase();
  }

  // allows everyone to withdraw their funds
  function withdraw() public
  {
      uint amount = bankBalances[msg.sender];

      require (amount > 0);
      bankBalances[msg.sender] = 0;      

      msg.sender.transfer(amount);

      // Create the relevant event
      PlayerWithdrawsMoney(msg.sender, amount);
  }

  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }

}