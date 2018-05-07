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
 /// @notice productId -> address of store
 mapping (uint => address) productIdInStore;

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

 struct Bid {
   address bidder;
   unit productId;
   unit value;  //Amount sent by the bidder
   bool revealed; /*strange variable, not sure what it is for, flag for if
   has concluded?*/
 }

 function EcommerceStore() public {
  productIndex = 0;
 }

 /// @notice this is a public function that let's a user bid on a product
 /// @dev
 /// @param _productId of the product the user want to bit on
 /// @param _bid encrypted string of the bid amount hased with a secret
 /// @return returns true if the bid is successfully placed
 function bid(unit _productId, bytes32 _bid) payable public returns (bool){
   Product storage product = stores[]
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

//we don't return the private parts of the struct it seems
   function getProduct(uint _productId) view public returns (uint, string, string,
     string, string, uint, uint, uint, ProductStatus, ProductCondition){
       Product memory product = stores[productIdInStore[_productId]][_productId];
       return(product.id, product.name, product.category, product.imageLink,
         product.descLink, product.auctionStartTime, product.auctionEndTime,
         product.startPrice, product.status, product.condition);
     }
}
