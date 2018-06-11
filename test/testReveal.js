amt_1 = web3.toWei(1, 'ether');
current_time = Math.round(new Date() / 1000);
EcommerceStore.deployed().then(function(i) {i.addProductToStore('iphone 6', 'Cell Phones & Accessories', 'imagelink', 'desclink', current_time, current_time + 200, amt_1, 0).then(function(f) {console.log(f)})});
EcommerceStore.deployed().then(function(i) {i.getProduct.call(1).then(function(f) {console.log(f)})})
Eutil = require('ethereumjs-util');
sealedBid = '0x' + Eutil.sha3((2 * amt_1) + 'mysecretacc1').toString('hex');
EcommerceStore.deployed().then(function(i) {i.bid(1, sealedBid, {value: 3*amt_1, from: web3.eth.accounts[1]}).then(function(f) {console.log(f)})});
sealedBid = '0x' + Eutil.sha3((3 * amt_1) + 'mysecretacc2').toString('hex');
EcommerceStore.deployed().then(function(i) {i.bid(1, sealedBid, {value: 4*amt_1, from: web3.eth.accounts[2]}).then(function(f) {console.log(f)})});

web3.eth.getBalance(web3.eth.accounts[1])
web3.eth.getBalance(web3.eth.accounts[2])

EcommerceStore.deployed().then(function(i) {i.revealBid(1, (2*amt_1).toString(), 'mysecretacc1', {from: web3.eth.accounts[1]}).then(function(f) {console.log(f)})})
EcommerceStore.deployed().then(function(i) {i.revealBid(1, (3*amt_1).toString(), 'mysecretacc2', {from: web3.eth.accounts[2]}).then(function(f) {console.log(f)})})

EcommerceStore.deployed().then(function(i) {i.highestBidderInfo.call(1).then(function(f) {console.log(f)})})
EcommerceStore.deployed().then(function(i) {i.totalBids.call(1).then(function(f) {console.log(f)})})
