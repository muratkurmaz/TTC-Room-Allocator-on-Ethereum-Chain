// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract RoomAllocation {

    // Enum for room exchange request status 
    enum ExchangeStatus { Pending, completed }

    // Struct for storing student details
    struct Student {
        address studentID;
        bool isRegistered;
        uint256 roomID;
        uint256[] preferences;
    }

    // Struct for storing room details
    struct Room {
        uint256 RoomID;
        bool isAllocated;
        address Owner;
    }

    mapping(address => Student) internal students; // studentID => Student
    mapping(uint256 => Room) internal rooms;  // roomID => Room
    // Add auxiliary variables here if needed

    uint256 public totalRooms;
    uint256[] internal availableRooms;

    address[] internal studentList;
    mapping(address => uint256) internal studentIndex;

    event StudentRegistered(address studentID, uint256 roomID);
    event PreferencesSet(address studentID, uint256[] preferences);
    event RoomExchanged(address fromStudent, address toStudent, uint256 newRoomID);

    modifier onlyRegistered() {
        require(students[msg.sender].isRegistered, "Not registered");
        _;
    }
    modifier notRegistered() {
        require(!students[msg.sender].isRegistered, "Already registered");
        _;
    }
    modifier roomAvailable() {
        require(availableRooms.length > 0, "No rooms available");
        _;
    }

    // Constructor to initialize the contract with a given number of rooms
    constructor(uint256 _totalRooms) {
        require(_totalRooms > 0, "totalRooms must be >0");
        totalRooms = _totalRooms;
        for (uint256 i = _totalRooms; i > 0; --i) {
            registerRoom(i - 1);
        }
    }

    // Function to create a room
    function registerRoom(uint256 roomID) private {
        Room storage r = rooms[roomID];
        r.RoomID = roomID;
        r.isAllocated = false;
        r.Owner = address(0);
        availableRooms.push(roomID);
    }

    // Function to register a student and randomly assign an available room
    function registerStudent() public notRegistered roomAvailable {
        uint256 idx = availableRooms.length - 1;
        uint256 roomID = availableRooms[idx];
        availableRooms.pop();

        rooms[roomID].isAllocated = true;
        rooms[roomID].Owner = msg.sender;

        Student storage s = students[msg.sender];
        s.studentID = msg.sender;
        s.isRegistered = true;
        s.roomID = roomID;

        studentIndex[msg.sender] = studentList.length;
        studentList.push(msg.sender);

        emit StudentRegistered(msg.sender, roomID);
    }

    // Function to set room preferences for a student
    function setPreferences(uint256[] memory _preferences) public onlyRegistered {
        require(_preferences.length > 0, "Empty preference list");
        require(_preferences.length <= totalRooms, "Too many IDs");

        bool[] memory seen = new bool[](totalRooms);
        for (uint256 i = 0; i < _preferences.length; ++i) {
            uint256 id = _preferences[i];
            require(id < totalRooms, "Invalid room ID");
            require(!seen[id], "Duplicate room ID");
            seen[id] = true;
        }

        uint256[] memory full = new uint256[](totalRooms);
        uint256 k = 0;
        for (uint256 i = 0; i < _preferences.length; ++i) {
            full[k++] = _preferences[i];
        }
        for (uint256 id = 0; id < totalRooms; ++id) {
            if (!seen[id]) full[k++] = id;
        }

        delete students[msg.sender].preferences;
        for (uint256 i = 0; i < totalRooms; ++i) {
            students[msg.sender].preferences.push(full[i]);
        }

        emit PreferencesSet(msg.sender, full);
    }

    // Function to check the allocated room for a student
    // Returns the room ID
    function checkAllocation() public view onlyRegistered returns (uint256) {
        return students[msg.sender].roomID;
    }

    // Function to request a room exchange with another student
    function requestExchange(address _requestedStudent) public onlyRegistered {
        require(_requestedStudent != msg.sender, "Self exchange not allowed");
        require(students[_requestedStudent].isRegistered, "Target not registered");

        uint256 myRoom = students[msg.sender].roomID;
        uint256 otherRoom = students[_requestedStudent].roomID;

        require(_better(msg.sender, otherRoom, myRoom), "Caller not better-off");
        require(_better(_requestedStudent, myRoom, otherRoom), "Target not better-off");

        students[msg.sender].roomID = otherRoom;
        students[_requestedStudent].roomID = myRoom;

        rooms[myRoom].Owner = _requestedStudent;
        rooms[otherRoom].Owner = msg.sender;

        emit RoomExchanged(msg.sender, _requestedStudent, otherRoom);
    }

    // Function to check a room is allocated to which student
    function getStudentByRoom(uint256 _roomID) public view onlyRegistered returns (address) {
        require(_roomID < totalRooms, "Invalid room ID");
        return rooms[_roomID].Owner;
    }

    // Provides a public getter for a student's full preference array
    function getPreferences(address _student) public view onlyRegistered returns (uint256[] memory) {
        return students[_student].preferences;
    }

    // ----------------------------------- Coordination -----------------------------------

    function coordinatedExchange() public {
        require(students[msg.sender].isRegistered, "Not registered");
        uint256 n = studentList.length;
        require(n > 0, "No students");

        bool[] memory done = new bool[](n);
        bool[] memory roomTaken = new bool[](totalRooms);
        uint256[] memory topRoom = new uint256[](n);
        uint256[] memory pointsTo = new uint256[](n);
        uint256[] memory visitTag = new uint256[](n);
        uint256 tagCounter = 1;

        while (true) {
            bool anyLeft = false;
            for (uint256 i = 0; i < n; ++i) {
                if (!done[i]) { anyLeft = true; break; }
            }
            if (!anyLeft) break;

            for (uint256 i = 0; i < n; ++i) {
                if (done[i]) continue;
                address stuAddr = studentList[i];
                uint256[] storage pref = students[stuAddr].preferences;
                require(pref.length > 0, "Student has no preferences");

                uint256 choice = pref[0];
                for (uint256 j = 0; j < pref.length; ++j) {
                    if (!roomTaken[pref[j]]) { choice = pref[j]; break; }
                }
                topRoom[i] = choice;

                address owner = rooms[choice].Owner;
                pointsTo[i] = (owner == address(0)) ? i : studentIndex[owner];
            }

            bool progress = false;
            for (uint256 i = 0; i < n; ++i) {
                if (done[i] || visitTag[i] >= tagCounter) continue;
                uint256 cur = i;
                tagCounter++;
                while (visitTag[cur] < tagCounter) {
                    visitTag[cur] = tagCounter;
                    cur = pointsTo[cur];
                }
                if (done[cur]) continue;

                progress = true;
                uint256 start = cur;
                do {
                    address stuAddr = studentList[cur];
                    uint256 newRoom = topRoom[cur];
                    uint256 oldRoom = students[stuAddr].roomID;

                    if (oldRoom != newRoom) {
                        address prevOwner = rooms[newRoom].Owner;
                        students[stuAddr].roomID = newRoom;
                        rooms[newRoom].Owner = stuAddr;
                        rooms[oldRoom].Owner = address(0);
                        emit RoomExchanged(prevOwner, stuAddr, newRoom);
                    }
                    roomTaken[newRoom] = true;
                    done[cur] = true;
                    cur = pointsTo[cur];
                } while (cur != start);
            }
            // exit loop if no cycles found instead of requiring progress
            if (!progress) {
                break;
            }
        }
    }

    // Returns true if 'candidate' room is strictly preferred over 'current' room for student
    function _better(address stu, uint256 candidate, uint256 current) internal view returns (bool) {
        return _rank(stu, candidate) < _rank(stu, current);
    }

    // Returns the index (rank) of the room in student's preference list; 0 is top
    function _rank(address stu, uint256 roomID) internal view returns (uint256) {
        uint256[] storage pref = students[stu].preferences;
        for (uint256 i = 0; i < pref.length; ++i) {
            if (pref[i] == roomID) return i;
        }
        return type(uint256).max;
    }
}

