App = {
  web3Provider: null,
  contracts: {},
  account: null,


  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    // Is there an injected web3 instance?
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
    } else {
      // If no injected web3 instance is detected, fall back to Ganache
        console.log("we should see this!!");
      App.web3Provider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
    }
    web3 = new Web3(App.web3Provider);
    web3.eth.defaultAccount = web3.eth.accounts[0]; // required somewhat ...
    return App.initContract();
  },

  initContract: function() {
    $.getJSON('RockPaperScissors.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var RockPaperScissorsArtifact = data;
      App.contracts.RPS = TruffleContract(RockPaperScissorsArtifact);

      // Set the provider for our contract
      App.contracts.RPS.setProvider(App.web3Provider);
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.btn-play', App.handlePlay);
    $(document).on('click', '#start', App.startGame);
    $(document).on('click', '#deposit', App.deposit);
  },

  startGame: function() {
    console.log("The game is starting ...");

    App.contracts.RPS.deployed().then(function(instance) {
        rpsInstance = instance;
        console.log("al madonni 4");
        // Execute adopt as a transaction by sending account
        console.log(instance);
        rpsInstance.registerPlayer().then(function(result) {
            console.log(result);
        }).catch( function(err) {
            console.log(err);
        });
    }).catch(function (err) {
        console.log(err.message);
    });
  },

  deposit: function() {
    console.log("test");
    App.contracts.RPS.deployed().then(function(rpsInstance) {
      console.log("al madonni 5");
      // Execute adopt as a transaction by sending account
      rpsInstance.placeAnte({value: web3.toWei(0.02)}).then(function(result) {
        console.log(result);
      }).catch( function(err) {
        console.log(err);
      });
    }).catch(function (err) {
      console.log(err.message);
    });
  },


  handlePlay: function(event) {
    console.log("fox il-liba ma...");
    /*
    selection = $(this).text();
    int i = -1;
    if (selection== "Rock") {
      ;
    } else if (selection == "Paper") {

    } else if (selection == "Scissors") {

    } else {
      throw("unhandled option");
    }*/

  },

  markAdopted: function(adopters, account) {
    /*
    var adoptionInstance;

    App.contracts.Adoption.deployed().then(function(instance) {
      adoptionInstance = instance;
      return adoptionInstance.getAdopters.call();
    }).then(function(adopters) {
      for (i = 0; i < adopters.length; i++) {
        if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
          $('.panel-pet').eq(i).find('button').text('Success').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });*/



      /*web3.eth.getAccounts(function(error, accounts) {

          if (error) {
              console.log(error);
          }

          var account = accounts[0];
          console.log(account);

          App.contracts.RPS.deployed().then(function(instance) {
              rpsInstance = instance;
              // Execute adopt as a transaction by sending account

              return rpsInstance.registerPlayer({from: account, value: 0.05});
          }).catch(function (err) {
              console.log(err.message);
          });

      });*/
  },

  handleAdopt: function(event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id'));
    var adoptionInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed().then(function(instance) {
        adoptionInstance = instance;

        // Execute adopt as a transaction by sending account
        return adoptionInstance.adopt(petId, {from: account});
      }).then(function(result) {
        return App.markAdopted();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  }

};

// loader ...
$(function() {
  $(window).load(function() {
    App.init();
  });
});
