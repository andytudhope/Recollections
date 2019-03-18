# Temporarily moved here, until private function calling gets more efficient.
@public
def receiveApproval(_from: address, _amount: uint256, _token: address, _data: bytes[64]):
    """
    @notice Support for "approveAndCall".  
    @param _from Who approved.
    @param _amount Amount being approved, needs to be equal `_amount` or `cost`
    @param _token Token being approved, needs to be `SNT`
    @param _data Abi encoded data with selector of `register(bytes32,address,bytes32,bytes32)`
    """

    assert _token == msg.sender, "Wrong account"
    assert _token == self.SNT, "Wrong token"

    #decode signature
    sig: bytes[4] = slice(_data, start=0, len=4)
    #decode id
    id: bytes32 = extract32(_data, 4, type=bytes32)
    #decode amount
    amount: uint256 = convert(extract32(_data, 32, type=bytes32), uint256)

    assert amount == _amount, "Wrong amount"

    if (sig == b"\x1a\x21\x4f\x43"):
        self._createDapp(_from, id, amount)
    elif (sig == b"\xac\x76\x90\x90"):
        self._downvote(_from, id, amount)
    elif (sig == b"\x2b\x3d\xf6\x90"):
        self._upvote(_from, id, amount)
    else:
        assert False, "Wrong method selector"
