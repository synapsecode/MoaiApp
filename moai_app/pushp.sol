// PUSH Comm Contract Interface
interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

 function sendNotification()   {
    IPUSHCommInterface(0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7).sendNotification(
    0x48AEA5ed7E51a61Fe8db543E2faB74743a4c9e04, //AccountDelegate
    //  Broadcast => address(this) else specify address
    0xA560aFC4537fc8BF99A6D81381c9E576222a77cD, 
    bytes(
        string(
            abi.encodePacked(
                "0", //MinimalIdentity
                "+", // segregator
                "3", // 1: Broadcast; 3: Targeted
                "+", // segregator
                "Test Notification", // this is notification title
                "+", // segregator
                "Hello World!" // notification body
            )
        )
    )
);
 }



 