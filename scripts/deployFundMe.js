const { ethers } = require("hardhat");

async function main() {
    // 创建合约工厂
    const fundMeFactory = await ethers.getContractFactory("FundMe")
    console.log(`contract deploying`);
    const fundMe = await fundMeFactory.deploy(10);
    // 等待所有节点部署完成，并写入链中
    await fundMe.waitForDeployment();
    console.log(`contract has been deployed successfully, contract address is ${fundMe.target}`);

    // verify fundMe(只有部署在测试完上才需要验证合约，部署在本地不需要验证)
    await fundMe.deploymentTransaction.wait(5);
    console.log("waiting for 5 confirmations");
    await verifyFundMe(fundMe.target, [10])
}

/**
 * 验证FundMe合约
 */
async function verifyFundMe(address, args) {
    // 通过调用代码的方式验证合约（区别于命令行方式）
    await hre.run("verify:verify", {
        address: address,
        constructorArguments: args,
    });
}

// 执行main函数
main().then().catch(err => {
    console.error(err)
    // 进程异常退出
    process.exit(1)
})