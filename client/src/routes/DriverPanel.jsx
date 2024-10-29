import { Navigate } from "react-router-dom";
import { toast } from "react-toastify";
import { useAccount, useReadContract } from "wagmi";
import abi from "../abi/contract.abi.json";
import { CONTRACT_ADDRESS } from "../constant";

const DriverPanel = () => {
  const { isConnected, address } = useAccount();
  const {
    data: driverData,
    error,
    isLoading,
    isError,
  } = useReadContract({
    abi,
    address: CONTRACT_ADDRESS,
    functionName: "drivers",
    args: [address],
  });

  if (!isConnected) {
    toast.error("You are not login");
    return <Navigate to={"/"} />;
  }

  if (isLoading) {
    return (
      <div className="w-full h-screen flex items-center justify-center">
        <h2 className="text-center">Loading...</h2>
      </div>
    );
  }

  if (!driverData || !driverData.length || !driverData?.[0]) {
    toast.error("You are not a driver. Please register");
    return <Navigate to={"/driver-register"} />;
  }

  if (isError) {
    toast.error(error.shortMessage);
    return (
      <div className="w-full h-screen flex items-center justify-center">
        <h2 className="text-center text-red-500 font-semibold">
          Error:- {error.shortMessage}
        </h2>
      </div>
    );
  }

  return <div></div>;
};

export default DriverPanel;
