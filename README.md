AAVE x Balancer oracle challenge by Gitcoin

Challenge is from price feeds of chainlink of the underlying assets, to build the contracts able to understand the assets linked to a Balancer Pool token, their allocation, and give a reliable price to these tokens that will evolve accordingly to the underlying assets price fluctuations.

### AaveBalancer.sol

1). Create your own pool using,
    
     function newPool()

2). Add token asset in pool using,
    
    function bindTokenToPoolAfterApprove()

-   add atleast for two token assets.

3). Then finalize balancer pool using,
    
    function finalize()

4). Then set chainlink proxy contract.

    function setChainlinkProxyPriceProvideProxy(balancerPoolAddress)
- It checks, If the returned price of balancer pool by chainlink aggregator is less than zero then it will call to fallbackOracle which is governance by AAVE currently.

5). Get latest answer of single token asset from ChainlinkProxyPriceProvider

    function getLatestAnswerForOneAsset(address _asset)

6). Get latest answer of all pool token assetes of balancer pool from ChainlinkProxyPriceProvider

    function getLatestAnswersForMultipleAssets(address[] memory _assets)

7). Get latest answer of total supply of single token asset from ChainlinkProxyPriceProvider

    function getLatestAnswerForTotalSupplyOfOneAsset(address poolAddress, address _asset)

8). Get latest answer of total supply of all pool token assetes of balancer pool from ChainlinkProxyPriceProvider

    function setLatestAnswersForTotalSupplyOfMultipleAssets(address poolAddress, address[] memory _assets)

Other feature.  
- one can mange own balancer pool.
- one can set controller.
