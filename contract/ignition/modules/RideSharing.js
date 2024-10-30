const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("RideSharingModule", (m) => {
  const initialFeeRate = m.getParameter("initialFeeRate", 250); //2.5%
  const initialFeeRecipient = m.getParameter(
    "initialFeeRecipient",
    "0x1B925bf5a948c1604aE7fD8e25b428a2a6FaabAB"
  );

  const rideSharing = m.contract(
    "RideSharing",
    [initialFeeRate, initialFeeRecipient],
    {}
  );

  return { rideSharing };
});
