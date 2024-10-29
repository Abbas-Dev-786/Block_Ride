import { Navigate } from "react-router-dom";
import { toast } from "react-toastify";
import { useAccount, useReadContract } from "wagmi";
import abi from "../abi/contract.abi.json";
import { CONTRACT_ADDRESS } from "../constant";

// Example ride notifications
const notifications = [
  { id: 1, details: "Ride request from Alice for 5 PM" },
  { id: 2, details: "Ride request from Bob for 6 PM" },
];

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

  const handleRejectBtnClick = () => {};

  const handleAcceptBtnClick = () => {};

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

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-100 p-4">
      {/* Driver Info Section */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-4 w-full max-w-xl">
        <h2 className="text-xl font-semibold mb-2">Driver Details</h2>
        <p className="text-gray-700">Name: {driverData?.[0]}</p>
        <p className="text-gray-700">
          License Number: {Number(driverData?.[1])}
        </p>
      </div>

      {/* Ride Notifications Section */}
      <div className="bg-white rounded-lg shadow-md p-6 w-full max-w-xl">
        <h2 className="text-xl font-semibold mb-4">Ride Notifications</h2>
        {notifications.map((notification) => (
          <div
            key={notification.id}
            className="flex justify-between items-center mb-4"
          >
            <span className="text-gray-800">{notification.details}</span>
            <div className="flex flex-col md:flex-row items-start justify-end md:justify-between flex-wrap gap-4">
              <button
                className="bg-green-500 text-white px-3 py-1 rounded mr-2"
                onClick={handleAcceptBtnClick}
              >
                Accept
              </button>
              <button
                className="bg-red-500 text-white px-3 py-1 rounded"
                onClick={handleRejectBtnClick}
              >
                Reject
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default DriverPanel;
