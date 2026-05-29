const hre = require("hardhat");

async function main() {
  const totalRooms = process.env.TOTAL_ROOMS || 5;

  const RoomAllocation = await hre.ethers.getContractFactory("RoomAllocation");
  const contract = await RoomAllocation.deploy(totalRooms);

  await contract.waitForDeployment();

  console.log(`RoomAllocation deployed to: ${await contract.getAddress()}`);
  console.log(`Total rooms: ${totalRooms}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
