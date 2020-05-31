pragma solidity ^0.5.0;

import "./interfaces/IBPool.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/ILendingPool.sol";
import "./chainlinkproxycontract/ChainlinkProxyPriceProvider.sol";
import "./interfaces/IERC20.sol";
import "./utils/SafeMath.sol";
import "github.com/aave/aave-protocol/blob/master/contracts/mocks/oracle/CLAggregators/MockAggregatorBAT.sol";
import "github.com/aave/aave-protocol/blob/master/contracts/mocks/oracle/CLAggregators/MockAggregatorDAI.sol";

interface BFactory {
    function isBPool(address b) external view returns (bool);
    function newBPool() external returns (IBPool);
}

contract AaveBalancer {
    
    using SafeMath for uint256;

    BFactory public bFactory;
    IPriceOracle public priceOracle;
    IBPool public bpool;
    IERC20 public erc20Token;
    ChainlinkProxyPriceProvider chainlinkProxyPriceProviderproxy;
    address[] sources;
    uint256[] totalValueInEthOfAsset;
    uint256 totalValueOfPool;

    constructor() public {
        
        bFactory = BFactory(0x8f7F78080219d4066A8036ccD30D588B416a40DB); // Kovan network
        
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(address(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5)); // mainnet address, for other addresses: https://docs.aave.com/developers/developing-on-aave/deployed-contract-instances
        ILendingPool priceOracleAddress = ILendingPool(provider.getPriceOracle());
        priceOracle = IPriceOracle(address(priceOracleAddress));
    }
    
    /**********************************************************************
    * Chainlink Proxy Price Provider Functions
    * 
    * This is proxy smart contract, with Chainlink Aggregator. 
    * It makes a list of assets and source of token assets and checks the price of token assets of Balancer Pool.
    * 
    * It checks, If the returned price of balancer pool by chainlink aggregator is less than zero,
    * then it will call to fallbackOracle which is governance by AAVE currently.
    **********************************************************************/
    
    function setChainlinkProxyPriceProvideProxy(address poolAddress) public {
        // Balancer pool object
        IBPool balancerPool = IBPool(poolAddress);   
        
        // balancer pool token assets
        address[] memory _assets = balancerPool.getFinalTokens();
        
        // Price feed source addresses of token assets
        delete sources;
        for(uint i=0; i <_assets.length; i++) {
            sources.push(priceOracle.getSourceOfAsset(_assets[i]));
        }
        
        // Set ChainlinkProxyPriceProvider balancer pool assets, price feed sources and fallback oracles supported by aave 
        chainlinkProxyPriceProviderproxy = new ChainlinkProxyPriceProvider(
            _assets, sources, priceOracle.getFallbackOracle()
        );
    }
    
    // Get latest answer of single token asset from ChainlinkProxyPriceProvider
    function getLatestAnswerForOneAsset(address _asset) public view returns(uint256) {
        return chainlinkProxyPriceProviderproxy.getAssetPrice(_asset);
    }
    
    // Get latest answer of all pool token assetes of balancer pool from ChainlinkProxyPriceProvider
    function getLatestAnswersForMultipleAssets(address[] memory _assets) public view returns(uint256[] memory) {
        return chainlinkProxyPriceProviderproxy.getAssetsPrices(_assets);
    }
    
    // Get latest answer of total supply of single token asset from ChainlinkProxyPriceProvider
    function getLatestAnswerForTotalSupplyOfOneAsset(address poolAddress, address _asset) public view returns(uint256) {
        IBPool balancerPool = IBPool(poolAddress);   
        uint balance = balancerPool.getBalance(_asset);
        return balance.mul(chainlinkProxyPriceProviderproxy.getAssetPrice(_asset));
    }
    
    // Get latest answer of total supply of all pool token assetes of balancer pool from ChainlinkProxyPriceProvider
    function setLatestAnswersForTotalSupplyOfMultipleAssets(address poolAddress, address[] memory _assets) public  {
        IBPool balancerPool = IBPool(poolAddress);   
        delete totalValueInEthOfAsset;
        for(uint i=0; i <_assets.length; i++) {
            uint256 balance = balancerPool.getBalance(_assets[i]);
            totalValueInEthOfAsset.push(balance.mul(chainlinkProxyPriceProviderproxy.getAssetPrice(_assets[i])));
            totalValueOfPool = totalValueOfPool + totalValueInEthOfAsset[i];
        }
    }
    
    function getLatestAnswersForTotalSupplyOfMultipleAssets() public view returns(uint256[] memory, uint256) {
        return (totalValueInEthOfAsset, totalValueOfPool);
    }
    
    /*
    * Balancer Functions
    * To create a new pool or set existing pool
    * bind token asset to pool
    * Set controller address of pool
    * Set finalized to pool
    * get finalized tokens list and number of tokens in list
    */
    function newBPool() public {
        bpool = IBPool(bFactory.newBPool());   
    }
    
    function setExistingPoolAddress(address _addr) public{
        bpool = IBPool(_addr);   
    }
    
    function bindTokenToPoolAfterApprove(address _erc20Address, address _addr, uint _balance, uint _denorem) public {
        erc20Token = IERC20(_erc20Address);
        erc20Token.approve(address(bpool), _balance);
        bpool.bind(_addr, _balance, _denorem);
    }
    
    function finalize() public {
        bpool.finalize();
    }
    
    function setController(address _addr) public {
        bpool.setController(_addr);
    }
    
    // Balancer getter Functions
    
    function getPoolADdress() public view returns(address) {
        return address(bpool);
    }
    
    function getFinalTokens() public view returns(address[] memory) {
        return bpool.getFinalTokens();
    }

    function getNumTokens() public view returns(uint) {
        return bpool.getNumTokens();
    }
    
    function getBalance(address _token) public view returns(uint) {
        return bpool.getBalance(_token);
    }
    
    function isBPool(address addr) public view returns(bool) {
        return bFactory.isBPool(addr);
    }
    
    function isFinalized() public view returns(bool) {
        return bpool.isFinalized();
    }
    
    function getController() public view returns(address) {
        return bpool.getController();
    }
}