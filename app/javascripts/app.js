// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
// need to use the built ABI?
import ecommerce_store_artifacts from '../../build/contracts/EcommerceStore.json'

var EcommerceStore = contract(ecommerce_store_artifacts);
//get references to ipfs and ethUtils
const ipfsAPI = require('ipfs-api');
const ethUtil = require('ethereumjs-util');

//init IPFS
const ipfs = ipfsAPI({host: 'localhost', port: '5001', protocol: 'http'});

window.App = {
  start: function(){
    var self = this;

    //this is where you have to init web3
    EcommerceStore.setProvider(web3.currentProvider);
    renderStore();

    //file reader
    var reader;

    $("#product-image").change(function(event){
      const file = event.target.files[0];
      reader = new window.FileReader();
      reader.readAsArrayBuffer(file);
    });

    $("#add-item-to-store").submit(function(event){
      const req = $("#add-item-to-store").serialize();
      let params = JSON.parse('{"' + req.replace(/"/g, '\\"').replace(/&/g, '","').replace(/=/g,'":"') + '"}');
      let decodedParams = {}
      Object.keys(params).forEach(function(v) {
       decodedParams[v] = decodeURIComponent(decodeURI(params[v]));
      });
      saveProduct(reader, decodedParams);
      event.preventDefault();
    });
  },
};

function saveProduct(reader, decodedParams){
  //save image & desc to ipfs
  let imageid, descid;
  saveImageOnIpfs(reader).then(function(id){
    console.log("images added")
    imageid = id;
    saveTextBlobOnIpfs(decodedParams["product-description"]).then(function(id){
      console.log("desc added")
      descid = id;
      saveProductToBlockchain(decodedParams, imageid, descid);
    })
  })

  //save whole product to blockchain
}

function saveProductToBlockchain(params, imageid, descid){
  //get start and end time
  let oneday = 24 * 60 * 60;
  console.log(params);
  let auctionStartTime = Date.parse(params["product-auction-start"]) / 1000;
  let auctionEndTime = auctionStartTime + parseInt(params["product-auction-end"]) * oneday;

  EcommerceStore.deployed()
  .then(function(i) {
    i.addProductToStore(
     params["product-name"],
     params["product-category"],
     imageid,
     descid,
     auctionStartTime,
     auctionEndTime,
     web3.toWei(params["product-price"], 'ether'),
     parseInt(params["product-condition"]),
     {
       from: web3.eth.accounts[0], gas: 440000
     })
     .then(function(f) {
       console.log(f.logs[0].args._value)
       $("#msg").show();
       $("#msg").html("Your product was successfully added to your store!");
     });
 });
}

function saveImageOnIpfs(reader){
  return new Promise(function(resolve, reject){
    const buffer = Buffer.from(reader.result);
    ipfs.add(buffer)
    .then((response) => {
      console.log(response)
      resolve(response[0].hash);
    }).catch((err) => {
      console.error(err)
      reject(err);
    })
  })
}

function saveTextBlobOnIpfs(blob){
  return new Promise(function(resolve, reject){
    const descBuffer = Buffer.from(blob, 'utf-8');
    ipfs.add(descBuffer)
    .then((response) => {
      console.log(response)
      resolve(response[0].hash);
    }).catch((err) => {
      console.error(err)
      reject(err);
    })
  })
}

function renderStore(){
  EcommerceStore.deployed().then(function(i){
    i.getProduct.call(6).then(function(p){
      //jquery https://jquery.com/
      $("#product-list").append(buildProduct(p));
    });
    i.getProduct.call(7).then(function(p){
      $("#product-list").append(buildProduct(p));
    });
  });
}

function buildProduct(product){
  let node = $("<div/>");
  node.addClass("col-sm-3 text-center col-margin-bottom-1");
  //paint the image product = getProduct return
  node.append("<img src='http://ipfs.io/ipfs/" + product[3] + "' width='150px' />");
  //name
  node.append("<div>" + product[1] + "</div>");
  //category
  node.append("<div>" + product[2] + "</div>");
  //starttime
  node.append("<div>" + product[5] + "</div>");
  //endtime
  node.append("<div>" + product[6] + "</div>");
  //start price
  node.append("<div>Ether" + product[7] + "</div>");
  return node;
}


window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545"));
  }

  App.start();
});
