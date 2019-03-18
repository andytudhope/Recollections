

def test_erc20_deploy(w3, SNT_token):
    a0 = w3.eth.accounts[0]
    assert SNT_token.name() == "Status Network Token"
    assert SNT_token.symbol() == "SNT"
    assert SNT_token.decimals() == 18
    assert SNT_token.total_supply() ==  3470483788*10**18


def test_dappstore_deploy(w3, SNT_token, DappStore):
    assert DappStore.SNT() == SNT_token.address
