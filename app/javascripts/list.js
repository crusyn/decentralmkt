window.App = {
  start: function(){
    var self = this;

    //file reader
    var reader;

    $("#product-image").change(function(event)){
      const file = event.target.files[0]
      reader = new window.FileReader()
      reader.readArrayBuffer(file)
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
    })
  }
}

function saveProduct(reader, decodedParams){
  //save image & desc to ipfs
  let imageid, descid;
  saveImageOnIpfs(reader).then(function(id){
    imageid = id;
    saveTextBlobOnIpfs(decodedParams["product-description"]).then(function(id){
      descid = id;
      saveProductToBlockchain(decodedParams, imageid, descid);
    })
  })

  //save whole product to blockchain
}

function saveProductToBlockchain(params, imageid, descid){
  //get start and end time
  oneday = 24 * 60 * 60;
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
     }
     .then(function(f) {
       console.log(f.logs[0].args._value)
       $("#msg").show();
       $("#msg").html("Your product was successfully added to your store!");
     })
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
    .then((response) -> {
      console.log(response)
      resolve(response[0].hash);
    }).catch((err) => {
      console.error(err)
      reject(err);
    })
  })
}
