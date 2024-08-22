// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 卖家：出售 NFT 的一方，可以挂单 list、撤单 revoke、修改价格 update。
// 买家：购买 NFT 的一方，可以购买 purchase。
// 订单：卖家发布的 NFT 链上订单，一个系列的同一 tokenId 最多存在一个订单，其中包含挂单价格 price 和持有人 owner 信息。当一个订单交易完成或被撤单后，其中信息清零。

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTSwap is IERC721Receiver {
    //挂单
    event List(
        address seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    //购买
    event Purchase(
        address indexed buyer,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 price
    );
    //撤单
    event Revoke(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId
    );
    //修改价格
    event Updata(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice
    );

    //定义order结构体
    struct Order {
        address owner;
        uint256 price;
    }
    //NFT Order映射
    mapping(address => mapping(uint256 => Order)) public nftList;

    //回退函数
    fallback() external payable {}

    // 挂单: 卖家上架NFT，合约地址为_nftAddr，tokenId为_tokenId，价格_price为以太坊（单位是wei）
    function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
        IERC721 _nft = IERC721(_nftAddr); //声明IERC721接口合约变量
        require(_nft.getApproved(_tokenId) == address(this), "Need Approval"); //合约得到授权
        require(_price > 0); //价格大于0

        Order storage _order = nftList[_nftAddr][_tokenId]; //设置nf持有人和价格
        _order.owner = msg.sender;
        _order.price = _price;
        //将NFT转账到合约
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        //释放List事件
        emit List(msg.sender, _nftAddr, _tokenId, _price);
    }

    //撤单 revoke()：卖家撤回挂单，并释放 Revoke 事件。参数为 NFT 合约地址 _nftAddr，NFT 对应的 _tokenId。成功后，NFT 会从 NFTSwap 合约转回卖家
    function revoke(address _nftAddr, uint256 _tokenId) public {
        Order storage _order = nftList[_nftAddr][_tokenId]; //取得Order
        require(_order.owner == msg.sender, "Not Owner"); //必须由持有人发起
        //声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order"); //NFT在合约中

        //将NFT转给卖家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete nftList[_nftAddr][_tokenId]; //删除order

        //释放Revoke事件
        emit Revoke(msg.sender, _nftAddr, _tokenId);
    }

    //调整价格：卖家调整挂单价格
    function update(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _newPrice
    ) public {
        //NFT价格大于0
        require(_newPrice > 0, "Invalid Price");
        //取得Order
        Order storage _order = nftList[_nftAddr][_tokenId];
        //必须由持有人发起
        require(_order.owner == msg.sender, "Not Owner");
        //声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        //NFT在合约中
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        //调整NFT价格
        _order.price = _newPrice;

        //释放Update事件
        emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
    }

    //购买: 买家购买NFT，合约为_nftAddr，tokenId为_tokenId，调用函数时要附带ETH
    function Purchase(address _nftAddr, uint256 _tokenId) public payable {
        //取得Order
        Order storage _order = nftList[_nftAddr][_tokenId];
        //NFT价格大于0
        require(_order.price > 0, "Increase price");
        //购买价格大于标价
        require(msg.value >= order.price, "Increase price");
        //声明IERC721接口合约变量
        IERC721 _nft = IERC721(_nftAddr);
        //NFT在合约中
        require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");

        //将NFT转给买家
        _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        //将ETH转给卖家，多余ETH给买家退款
        payable(_order.owner).transfer(_order.price);
        payable(msg.sender).transfer(msg.value - _order.price);

        //删除order
        delete nftList[_nftAddr][_tokenId];

        //释放Purchase事件
        emit Purchase(msg.sender,_nftAddr,_tokenId,_order.price)
    }

    // 实现{IERC721Receiver}的onERC721Received，能够接收ERC721代币
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external override returns(bytes4){
      return IERC721Receiver.onERC721Received.selector
    }
}
