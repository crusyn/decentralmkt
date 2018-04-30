pragma solidity ^0.4.13;

contract EcommerceStore {
 enum ProductStatus { Open, Sold, Unsold }
 enum ProductCondition { New, Used }

 uint public productIndex;
 mapping (address => mapping(uint => Product)) stores;
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
 }

 function EcommerceStore() public {
  productIndex = 0;
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