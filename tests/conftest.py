import os

import pytest

from vyper import compile_code

from eth_tester import (
    EthereumTester,
)
from web3.providers.eth_tester import (
    EthereumTesterProvider,
)
from web3 import (
    Web3,
)
from web3.contract import (
    ConciseContract,
)
from vdb.vdb import (
    VyperDebugCmd
)
from vdb.eth_tester_debug_backend import (
    PyEVMDebugBackend,
    set_debug_info
)
from vdb.source_map import (
    produce_source_map
)


@pytest.fixture()
def tester():
    t = EthereumTester(backend=PyEVMDebugBackend())
    return t


def zero_gas_price_strategy(web3, transaction_params=None):
    return 0  # zero gas price makes testing simpler.


@pytest.fixture()
def w3(tester):
    w3 = Web3(EthereumTesterProvider(tester))
    w3.eth.setGasPriceStrategy(zero_gas_price_strategy)
    w3.eth.defaultAccount = w3.eth.accounts[0]
    return w3


def _get_contract(w3, source_code, *args, **kwargs):
    interface_codes = kwargs.get('interface_codes')

    if interface_codes == None:
        compiler_output = compile_code(
            source_code,
            ['bytecode', 'abi'],
        )
        source_map = produce_source_map(source_code)
    else:
        compiler_output = compile_code(
            source_code,
            ['bytecode', 'abi'],
            interface_codes=interface_codes,
        )
        source_map = produce_source_map(source_code, interface_codes=interface_codes)
    
    abi = compiler_output['abi']
    bytecode = compiler_output['bytecode']
    contract = w3.eth.contract(abi=abi, bytecode=bytecode)

    # Enable vdb.
    set_debug_info(source_code, source_map)
    import vdb
    setattr(vdb.debug_computation.DebugComputation, 'enable_debug', True)
    constructor_args = kwargs.get('constructor_args', [])
    value = kwargs.pop('value', 0)
    value_in_eth = kwargs.pop('value_in_eth', 0)
    value = value_in_eth * 10**18 if value_in_eth else value  # Handle deploying with an eth value.
    gasPrice = kwargs.pop('gasPrice', 0)
    deploy_transaction = {
        'from': w3.eth.accounts[0],
        'data': contract._encode_constructor_data(constructor_args),
        'value': value,
        'gasPrice': gasPrice,
    }
    tx = w3.eth.sendTransaction(deploy_transaction)
    tx_receipt = w3.eth.getTransactionReceipt(tx)
    if tx_receipt['status'] == 0:
        import ipdb; ipdb.set_trace()
        raise Exception('Could not deploy contract! {}'.format(tx_receipt))
    address = tx_receipt['contractAddress']
    contract = w3.eth.contract(address, abi=abi, bytecode=bytecode)
    # Filter logs.
    contract._logfilter = w3.eth.filter({
        'fromBlock': w3.eth.blockNumber - 1,
        'address': contract.address
    })
    return ConciseContract(contract)


@pytest.fixture
def get_logs(w3):
    def get_logs(tx_hash, c, event_name):
        tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
        logs = c._classic_contract.events[event_name]().processReceipt(tx_receipt)
        return logs
    return get_logs


@pytest.fixture
def get_contract(w3):
    def get_contract(source_code, *args, **kwargs):
        return _get_contract(w3, source_code, *args, **kwargs)
    return get_contract


def create_contract(w3, get_contract, path, constructor_args, interface_codes=None):
    wd = os.path.dirname(os.path.realpath(__file__))
    with open(os.path.join(wd, os.pardir, path)) as f:
        source_code = f.read()
    return get_contract(source_code, constructor_args=constructor_args, interface_codes=interface_codes)


@pytest.fixture
def SNT_token(w3, get_contract):
    return create_contract(
        w3=w3,
        get_contract=get_contract,
        path='vyper/ERC20.vy',
        constructor_args=['Status Network Token', 'SNT', 18, 3470483788]
    )


@pytest.fixture
def DappStore(w3, get_contract, SNT_token):
    wd = os.path.dirname(os.path.realpath(__file__))
    with open(os.path.join(wd, os.pardir, 'vyper/ApproveAndCallFallBack.vy')) as f:
        interface_codes = {
            'ApproveAndCallFallBackInterface': {
                'type': 'vyper',
                'code': f.read()
            }
        }
    return create_contract(
        w3=w3,
        get_contract=get_contract,
        path='vyper/DAppStore.vy',
        constructor_args=[SNT_token.address],
        interface_codes=interface_codes
    )


@pytest.fixture
def math_contract(w3, get_contract):
    return create_contract(
        w3=w3,
        get_contract=get_contract,
        path="vyper/math/math.vy",
        constructor_args=None
    )
