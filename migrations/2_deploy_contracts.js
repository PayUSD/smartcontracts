var PayUSD = artifacts.require("./PayUSD.sol");

module.exports = function(deployer) {
  deployer.deploy(PayUSD);
};