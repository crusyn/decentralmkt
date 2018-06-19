amt_1 = web3.toWei(1, 'ether');
current_time = Math.round(new Date() / 1000);
web3.eth.getBalance(web3.eth.accounts[1]);
//91.90
web3.eth.getBalance(web3.eth.accounts[2]);
//100

EcommerceStore.deployed().then(function(i) {i.addProductToStore('iphone 6', 'Cell Phones & Accessories', 'imagelink', 'desclink', current_time, current_time + 200, amt_1, 0).then(function(f) {console.log(f.logs[0].args._value)})});
productId = 3;
EcommerceStore.deployed().then(function(i) {i.getProduct.call(productId).then(function(f) {console.log(f)})});
Eutil = require('ethereumjs-util');
sealedBid = '0x' + Eutil.sha3((2 * amt_1) + 'mysecretacc1').toString('hex');
EcommerceStore.deployed().then(function(i) {i.bid(productId, sealedBid, {value: 3*amt_1, from: web3.eth.accounts[1]}).then(function(f) {console.log(f)})});
sealedBid = '0x' + Eutil.sha3((3 * amt_1) + 'mysecretacc2').toString('hex');
EcommerceStore.deployed().then(function(i) {i.bid(productId, sealedBid, {value: 4*amt_1, from: web3.eth.accounts[2]}).then(function(f) {console.log(f)})});

web3.eth.getBalance(web3.eth.accounts[1]);
//88.89
web3.eth.getBalance(web3.eth.accounts[2]);
//95.99

EcommerceStore.deployed().then(function(i) {i.revealBid(productId, (2*amt_1).toString(), 'mysecretacc1', {from: web3.eth.accounts[1]}).then(function(f) {console.log(f.logs[0].args._from + " " + f.logs[0].args._highBidderBefore + " " + f.logs[0].args._highBidderAfter + " " + f.logs[0].args._highestBid + " " + f.logs[0].args._secondHighestBid + " " + f.logs[0].args._amtInBid + " " + f.logs[0].args._startPrice + " " + f.logs[0].args._refund)})});
//it seems the right amount of ETH is refunded...

//different reveal with debugging info
EcommerceStore.deployed().then(function(i) {i.revealBid(productId, (2*amt_1).toString(), 'mysecretacc1', {from: web3.eth.accounts[1]}).then(function(f) {console.log(f)})})

EcommerceStore.deployed().then(function(i) {i.revealBid(productId, (3*amt_1).toString(), 'mysecretacc2', {from: web3.eth.accounts[2]}).then(function(f) {console.log(f)})})

EcommerceStore.deployed().then(function(i) {i.highestBidderInfo.call(productId).then(function(f) {console.log(f)})})
//this doesn't return the highest bidder address no matter what
EcommerceStore.deployed().then(function(i) {i.totalBids.call(productId).then(function(f) {console.log(f)})})
 //this works
