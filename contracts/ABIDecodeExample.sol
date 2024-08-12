// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract ABIDecodeExample {
    event DataDecoded(uint a, string b);

    //编码数据
    function encodeData(
        uint a,
        string memory b
    ) public pure returns (bytes memory) {
        return abi.encode(a, b);
    }

    //解码数据
    function decodeData(bytes memory data) public {
        (uint a, string memory b) = abi.decode(data, (uint, string));
        emit DataDecoded(a, b);
    }

    //编码带有函数选择器的数据
    function encodeWithSelector(
        address recipient,
        uint256 amount
    ) public pure returns (bytes memory) {
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        return abi.encodeWithSelector(selector, recipient, amount);
    }

    //解码带有函数选择器的数据
    function decodeWithSelector(
        bytes memory data
    ) public pure returns (bytes4, address, uint256) {
        return abi.decode(data, (bytes4, address, uint256));
    }

    //编码带有函数签名的数据
    function encodeWithSignature(
        address recipient,
        uint256 amount
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                recipient,
                amount
            );
    }

    //解码带有函数签名的数据
    function decodeWithSignature(
        bytes memory data
    ) public pure returns (bytes4, address, uint256) {
        return abi.decode(data, (bytes4, address, uint256));
    }
}
