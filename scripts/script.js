const hre = require('hardhat')
const { ethers } = require('ethers')

async function main() {
  const accounts = await hre.ethers.getSigners()
  const signer = accounts[0]

  const MockNFT = await hre.ethers.getContractFactory('MockNFT')
  const mockNFT = await MockNFT.deploy(
    100,
    'Mock NFT',
    'MNFT',
    'https://metadata.server.com/?id=',
  )
  await mockNFT.deployed()
  console.log(`MockNFT address: ${mockNFT.address}`)

  const mintTx0 = await mockNFT.mint(signer.address)
  await mintTx0.wait()

  const mintTx1 = await mockNFT.mint(signer.address)
  await mintTx1.wait()

  const nftId0 = 0
  const nftId1 = 1

  const DutchAuction = await hre.ethers.getContractFactory('DutchAuction')
  const dutchAuction = await DutchAuction.deploy(
    mockNFT.address,
    nftId0,
    ethers.utils.parseEther('0.1'),
    1,
  )
  await dutchAuction.deployed()
  console.log(`DutchAuction address: ${dutchAuction.address}`)

  const dutchApproveTx = await mockNFT.approve(dutchAuction.address, nftId0)
  await dutchApproveTx.wait()

  const EnglishAuction = await hre.ethers.getContractFactory('EnglishAuction')
  const englishAuction = await EnglishAuction.deploy(
    mockNFT.address,
    nftId1,
    ethers.utils.parseEther('0.1'),
  )
  await englishAuction.deployed()
  console.log(`EnglishAuction address: ${englishAuction.address}`)

  const englishApproveTx = await mockNFT.approve(englishAuction.address, nftId1)
  await englishApproveTx.wait()

  const englishStartTx = await englishAuction.startAuction()
  await englishStartTx.wait()

  const MockToken = await hre.ethers.getContractFactory('MockToken')
  const mockToken = await MockToken.deploy('MockToken', 'MOCK')
  await mockToken.deployed()
  console.log(`MockToken address: ${mockToken.address}`)

  const mintTokensTx = await mockToken.mint(
    signer.address,
    ethers.utils.parseEther('1000'),
  )
  await mintTokensTx.wait()

  const CrowdFund = await hre.ethers.getContractFactory('CrowdFund')
  const crowdFund = await CrowdFund.deploy(mockToken.address)
  await crowdFund.deployed()
  console.log(`CrowdFund address: ${crowdFund.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
