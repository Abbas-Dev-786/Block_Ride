// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol" as ReentrancyGuard;
import "@openzeppelin/contracts/access/Ownable.sol" as Ownable;

/// @title RideSharingEscrow
/// @notice Manages ride bookings and payments for a ride-sharing application
/// @dev Implements escrow functionality for ride payments
contract RideSharingEscrow is ReentrancyGuard, Ownable {
    /// @notice Enum representing the possible states of a ride
    enum RideStatus {
        Created,
        Accepted,
        Completed,
        Cancelled
    }

    /// @notice Struct containing all relevenat information for a driver
    struct Driver {
        string name;
        uint256 licenseNumber;
        uint256[] tripIds;
    }

    struct Transaction {
        uint256 transactionId;
        uint256 tripId;
        uint256 amount;
        uint256 timestamp;
    }

    /// @notice Struct containing all relevant information for a ride
    struct Ride {
        uint256 tripId;
        uint256 transactionId;
        int256[] source;
        int256[] destination;
        address payable rider;
        address payable driver;
        uint256 fare;
        RideStatus status;
        uint256 createdAt;
    }

    /// @notice Mapping to store all rides
    mapping(uint256 => Ride) private rides;
    mapping(address => uint256[]) private trips;
    mapping(address => Driver) public drivers;

    /// @notice Counter for generating unique ride IDs
    uint256 private nextRideId;
    uint256 public transactionCounter;

    /// @notice Platform fee percentage (in basis points, e.g., 250 = 2.5%)
    uint256 public platformFeeRate;

    /// @notice Address to receive platform fees
    address payable public feeRecipient;

    /// @notice Time limit for ride acceptance (in seconds)
    uint256 public constant RIDE_ACCEPTANCE_TIMEOUT = 15 minutes;

    /// @notice Events for various ride actions
    event RideCreated(
        uint256 indexed rideId,
        address indexed rider,
        uint256 fare
    );
    event RideAccepted(uint256 indexed rideId, address indexed driver);
    event RideCompleted(uint256 indexed rideId);
    event RideCancelled(uint256 indexed rideId);
    event PlatformFeeUpdated(uint256 newFeeRate);
    event FeeRecipientUpdated(address newFeeRecipient);
    event TransactionRecorded(
        uint256 indexed transactionId,
        uint256 indexed tripId,
        uint256 amount
    );

    /// @notice Custom errors for better gas efficiency and clarity
    error UnauthorizedAction();
    error InvalidRideState();
    error InvalidFare();
    error RideExpired();
    error TransferFailed();
    error EmptyCoordinates();
    error LengthShouldBeTwoCoordinates();
    error InvalidLatitude(int256 latitude);
    error InvalidLongitude(int256 longitude);

    /// @notice Constructor to set initial platform fee and recipient
    /// @param initialFeeRate Initial platform fee rate in basis points
    /// @param initialFeeRecipient Address to receive platform fees
    constructor(
        uint256 initialFeeRate,
        address payable initialFeeRecipient
    ) Ownable(msg.sender) {
        require(initialFeeRate <= 1000, "Fee rate must be <= 10%");
        require(initialFeeRecipient != address(0), "Invalid fee recipient");
        platformFeeRate = initialFeeRate;
        feeRecipient = initialFeeRecipient;
    }

    /// @notice Modifier to validate coordinate arrays
    modifier validateCoordinates(
        int256[] calldata _sourceCoordinates,
        int256[] calldata _destinationCoordinates
    ) {
        // Check for empty arrays
        if (
            _sourceCoordinates.length == 0 ||
            _destinationCoordinates.length == 0
        ) {
            revert EmptyCoordinates();
        }

        // Check for length == 2
        if (
            _sourceCoordinates.length != 2 ||
            _destinationCoordinates.length != 2
        ) {
            revert LengthShouldBeTwoCoordinates();
        }

        for (uint256 i = 0; i < _sourceCoordinates.length; i += 2) {
            // Validate source coordinates
            if (
                _sourceCoordinates[i] < -90000000 ||
                _sourceCoordinates[i] > 90000000
            ) {
                revert InvalidLatitude(_sourceCoordinates[i]);
            }
            if (
                _sourceCoordinates[i + 1] < -180000000 ||
                _sourceCoordinates[i + 1] > 180000000
            ) {
                revert InvalidLongitude(_sourceCoordinates[i + 1]);
            }

            // Validate destination coordinates
            if (
                _destinationCoordinates[i] < -90000000 ||
                _destinationCoordinates[i] > 90000000
            ) {
                revert InvalidLatitude(_destinationCoordinates[i]);
            }
            if (
                _destinationCoordinates[i + 1] < -180000000 ||
                _destinationCoordinates[i + 1] > 180000000
            ) {
                revert InvalidLongitude(_destinationCoordinates[i + 1]);
            }
        }
        _;
    }

    /// @notice Creates a new ride
    /// @dev Rider must send the fare amount as msg.value
    function createRide(
        int256[] calldata _source,
        int256[] calldata _destination
    ) external payable nonReentrant validateCoordinates(_source, _destination) {
        if (msg.value == 0) revert InvalidFare();

        uint256 rideId = nextRideId++;
        rides[rideId] = Ride({
            tripId: rideId,
            rider: payable(msg.sender),
            driver: payable(address(0)),
            fare: msg.value,
            status: RideStatus.Created,
            createdAt: block.timestamp,
            source: _source,
            destination: _destination,
            transactionId: 0
        });

        trips[msg.sender].push(rideId);

        emit RideCreated(rideId, msg.sender, msg.value);
    }

    /// @notice Allows a driver to accept a ride
    /// @param _rideId The ID of the ride to accept
    function acceptRide(uint256 _rideId) external nonReentrant {
        Ride storage ride = rides[_rideId];
        if (ride.status != RideStatus.Created) revert InvalidRideState();
        if (ride.rider == msg.sender) revert UnauthorizedAction();
        if (block.timestamp > ride.createdAt + RIDE_ACCEPTANCE_TIMEOUT)
            revert RideExpired();

        ride.driver = payable(msg.sender);
        ride.status = RideStatus.Accepted;

        emit RideAccepted(_rideId, msg.sender);
    }

    /// @notice Marks a ride as completed and transfers payment
    /// @param _rideId The ID of the ride to complete
    function completeRide(uint256 _rideId) external nonReentrant {
        Ride storage ride = rides[_rideId];
        if (msg.sender != ride.driver) revert UnauthorizedAction();
        if (ride.status != RideStatus.Accepted) revert InvalidRideState();

        uint256 platformFee = (ride.fare * platformFeeRate) / 10000;
        uint256 driverPayment = ride.fare - platformFee;

        if (!feeRecipient.send(platformFee)) revert TransferFailed();
        if (!ride.driver.send(driverPayment)) revert TransferFailed();

        transactionCounter++;
        ride.status = RideStatus.Completed;
        ride.transactionId = transactionCounter;

        emit RideCompleted(_rideId);
    }

    /// @notice Allows the rider to cancel a ride
    /// @param _rideId The ID of the ride to cancel
    function cancelRide(uint256 _rideId) external nonReentrant {
        Ride storage ride = rides[_rideId];
        if (msg.sender != ride.rider) revert UnauthorizedAction();
        if (
            ride.status != RideStatus.Created &&
            ride.status != RideStatus.Accepted
        ) revert InvalidRideState();

        ride.status = RideStatus.Cancelled;
        if (!ride.rider.send(ride.fare)) revert TransferFailed();

        emit RideCancelled(_rideId);
    }

    /// @notice Retrieves the current status of a ride
    /// @param _rideId The ID of the ride to check
    /// @return The current status of the ride
    function getRideStatus(uint256 _rideId) external view returns (RideStatus) {
        return rides[_rideId].status;
    }

    /// @notice Updates the platform fee rate
    /// @param _newFeeRate New fee rate in basis points
    function updatePlatformFee(uint256 _newFeeRate) external onlyOwner {
        require(_newFeeRate <= 1000, "Fee rate must be <= 10%");
        platformFeeRate = _newFeeRate;
        emit PlatformFeeUpdated(_newFeeRate);
    }

    /// @notice Updates the fee recipient address
    /// @param _newFeeRecipient New address to receive platform fees
    function updateFeeRecipient(
        address payable _newFeeRecipient
    ) external onlyOwner {
        require(_newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newFeeRecipient;
        emit FeeRecipientUpdated(_newFeeRecipient);
    }

    function registerDriver(
        string memory _name,
        uint256 _licenseNumber
    ) public {
        require(
            drivers[msg.sender].licenseNumber == 0,
            "Driver already registered"
        );
        drivers[msg.sender] = Driver(_name, _licenseNumber, new uint256[](0));
    }

    function getMyTrips() public view returns (Ride[] memory) {
        uint256[] storage userRideIds = trips[msg.sender];
        Ride[] memory userRides = new Ride[](userRideIds.length);

        for (uint256 i = 0; i < userRideIds.length; i++) {
            userRides[i] = rides[userRideIds[i]];
        }

        return userRides;
    }
}
