pragma solidity ^0.4.13;

/// @title Decentral Market
/// @author @crusyn by way of Mahesh Zastrin
contract EcommerceStore {
 enum ProductStatus { Open, Sold, Unsold }
 enum ProductCondition { New, Used }

 uint public productIndex;
 /// @notice This is the mapping used to keep track of which products are
 /// in which merchant's store - address of store -> id of Product -> Product Struct
 mapping (address => mapping(uint => Product)) stores;
 /// @notice productId -> address of store.  This contians a listing of
 /// products and which store contain them, this doesn't link you to the actual
 /// product struct.  Each product only lives in 1 store (maybe)
 mapping (uint => address) productIdInStore;

 struct Bid {
   address bidder;
   uint productId;
   uint value;  //Amount of ETH sent by the bidder in the bid call
   bool revealed;  //strange variable, not sure what it is for, flag for if
//has concluded?  Nvm, used when the bid is revealed.
 }

 struct Product {
  uint id;
  string name;
  string category;
  string imageLink;
  string descLink;
  uint auctionStartTime;
  uint auctionEndTime;
  uint startPrice;
  //these are set by system
  address highestBidder;
  uint highestBid;
  uint secondHighestBid;
  uint totalBids;
  ProductStatus status;
  //until here
  ProductCondition condition;

  /*The key is the address of the bidder and value is the mapping of the
  hashed bid string to the bid struct.*/
  mapping (address => mapping (bytes32 => Bid)) bids;
}



 function EcommerceStore() public {
  productIndex = 0;
 }

 /// @notice this is a public function that let's a user bid on a product.
 /// To place a bid we need to tell the contract what we’re bidding on,
 /// send some ETH that is greater than the bid amount (if we want the bid
 /// to be valid) and encrypt our actual bid (with a secret string).
 /// @dev
 /// @param _productId of the product the user want to bit on
 /// @param _bid encrypted string of the bid amount hased with a secret
 /// @return returns true if the bid is successfully placed
 function bid(uint _productId, bytes32 _bid) payable public returns (bool){
   // Need to query the stores mapping to get the pointer to the product struct
   // Not sure why, but in this case it seems we are persiting this to the chain
   Product storage product = stores[productIdInStore[_productId]][_productId];

   //Doing some checks, checking contract state, using require
   //now = current block's timestamp
   require (now >= product.auctionStartTime); //the auction must have started
   require (now <= product.auctionEndTime); //the auction must not have ended

   require (msg.value > product.startPrice); //this is kind of a strange
   //constaint, why?  Wouldn't this just be a failed bid at the end?


   //need to add to the Bids struct by bidder and bid hash
   //(the same sender can bid twice)
   product.bids[msg.sender][_bid] = Bid(msg.sender, _productId, msg.value, false);


   product.totalBids += 1; //Increment bid count

   //if all is well say so
   return true;
 }

 function revealBid(uint _productId, string _amountBid, string _secret) public returns (bool){
   //hwell, let's see the hash would have been....
   bytes32 sealedBid = sha3(_amountBid, _secret);

   //ok, let's get this product struct, don't ask me why we record it to the
   //blockchain
   Product storage currentProduct = stores[productIdInStore[_productId]][_productId];

   //let's make sure the auction has ended...
   require (now > currentProduct.auctionEndTime);

   //Liar.  My fan fucking lied to me.  No corresponding hash found: This means
   //the user is trying to reveal something which wasn't even bid.
   //In that case, just throw an exception using a require

   //We'll do this by looking up the bid
   Bid memory bidInfo = currentProduct.bids[msg.sender][sealedBid];
   //is there a bidder?  presumably this would be 0 if there was no bidder, I
   //wonder why we wouldn't check to make sure the bidder is not = sender ???
   require(bidInfo.bidder> 0);
   //let's make sure the bid wasn't yet revealed, we can't reveal twice
   require(bidInfo.revealed == false);

   //OK.  we have a valid bid.  no time to see if we are the top bidder or if
   //we should issue a refund.
   uint refund;

   uint amountInBid = stringToUint(_amountBid);

   uint amountSendToContract = bidInfo.value;

   //Bid amount < sent amount: The user for example bid $10 but only sent $5.
   //Since it is invalid, we will just refund this amount to the user.
   if(amountSendToContract < amountInBid){
     refund = amountSendToContract;
   }
   //Bid amount >= sent amount: It's a valid bid. We will now check to see
   // if we should record this bid.
   else {
     //First reveal: If this is the first valid bid reveal, we record this
     // as the highest bid and also record who bid this value. We also set
     // the second highest bid to the product starting price (If no one else
     // reveals, this user just pays the start price. Remember the winner
     // always pays the second highest price?)

     //check if this is the first reveal by seeing if highestBidder is zero
     if(currentProduct.highestBidder == 0){
       currentProduct.highestBidder == msg.sender;
       currentProduct.highestBid == amountInBid;
       currentProduct.secondHighestBid == currentProduct.startPrice;

       //refund anything not used by the bid
       refund = amountSendToContract - amountInBid;
     }

     //Higher Bid: If the user reveals and their bid is higher than the current
     //highest revealed bid, we record this bidder and their bid as highest
     // and set the second highest bid value to old bid amount

     else if (amountInBid > currentProduct.highestBid){
       currentProduct.secondHighestBid == currentProduct.highestBid;
       //refund the previous bidder his bid
       currentProduct.highestBidder.transfer(currentProduct.highestBid);

       currentProduct.highestBidder == msg.sender;
       currentProduct.highestBid == amountInBid;
       refund = amountSendToContract - amountInBid;
     }

     //Lower Bid: If the bid is lower than highest bid, it's a losing bid.
     //But we will also check if this is lower than the second highest bid.
     //If yes, we just refund the item because they lost otherwise set this
     //amount to second highest bid.
     else if (amountInBid <= currentProduct.highestBid){
        if(amountInBid > currentProduct.secondHighestBid){
          currentProduct.secondHighestBid = amountInBid;
        }

        refund = amountSendToContract;
     }
   }

   //Mark as revealed, not sure what for yet... let's see
   currentProduct.bids[msg.sender][sealedBid].revealed = true;

   if(refund > 0){
     msg.sender.transfer(refund);
   }
 }

 function addProductToStore(string _name, string _category, string _imageLink,
   string _descLink, uint _auctionStartTime, uint _auctionEndTime,
   uint _startPrice, ProductCondition _condition){
     /*require is control flow, asset is for debugging/preventing structurally
     incorrect stuff*/
     require(_auctionStartTime < _auctionEndTime);
     productIndex += 1;

     /*We have used a keyword called memory to store the product
     in both the functions. The reason we use that keyword is to tell the
     EVM that this object is only used as a temporary variable. It will be
     cleared from memory as soon as that function completes execution.
     You can read more about memory and storage here
     */
     Product memory product = Product(productIndex, _name, _category, _imageLink,
        _descLink, _auctionStartTime, _auctionEndTime, _startPrice, 0, 0, 0, 0,
        ProductStatus.Open, ProductCondition(_condition));

    //add product to store
    stores[msg.sender][productIndex] = product;
    //map the product back to store
    productIdInStore[productIndex] = msg.sender;
   }


   /// @notice this is a public function that allows people to view a Product
   /// @dev
   /// @param _productId id of the product you want the details of
   /// @return returns id, name, category, imageLink, descLink, auctionStartTime,
   /// auctionEndTime, startPrice, condition
   function getProduct(uint _productId) view public returns (uint, string, string,
     string, string, uint, uint, uint, ProductStatus, ProductCondition){
       Product memory product = stores[productIdInStore[_productId]][_productId];
       return(product.id, product.name, product.category, product.imageLink,
         product.descLink, product.auctionStartTime, product.auctionEndTime,
         product.startPrice, product.status, product.condition);
     }

    //Apparently the stringToUint function is not something that comes with
    //Ethereum...
    /// @notice this is a private function turns strings to ints
    /// @dev this function uses the fact that ints are in order in the character
    /// set to derive the value
    /// @param _str a string that you want to convert to an int
    /// @return returns the unit version of the string
    function stringToUint(string _str) pure private returns (uint){
      //pure means this function doesn't write or read from the blockchain
      bytes memory b = bytes(_str);
      uint result = 0;
      for (uint i = 0; i < b.length; i++) {
        if (b[i] >= 48 && b[i] <= 57) {
          result = result * 10 + (uint(b[i]) - 48);
        }
      }
      return result;
    }

    function highestBidderInfo(uint _productId) view public returns (address, uint, uint) {
      Product memory product = stores[productIdInStore[_productId]][_productId];
      return (product.highestBidder, product.highestBid, product.secondHighestBid);
    }

    function totalBids(uint _productId) view public returns (uint) {
      Product memory product = stores[productIdInStore[_productId]][_productId];
      return product.totalBids;
    }

}
