var ConvertLib = artifacts.require("./ConvertLib.sol");
var BST = artifacts.require("./BoostoToken.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, BST);
  deployer.deploy(BST);
};
