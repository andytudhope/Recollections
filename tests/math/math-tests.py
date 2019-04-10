from decimal import ROUND_DOWN, ROUND_FLOOR, Decimal, getcontext

from eth_tester.exceptions import TransactionFailed
import hypothesis
import pytest

from vyper.utils import SizeLimits

getcontext().prec = 168
DECIMAL_PLACES = 10
RESULT_MAX_OFFSET = Decimal(0.0000000099)
DECIMAL_RANGE = [Decimal("0." + "0" * d + "2") for d in range(0, DECIMAL_PLACES)]


def decimal_truncate(val, decimal_places=DECIMAL_PLACES, rounding=ROUND_DOWN):
    q = "0"
    if decimal_places != 0:
        q += "." + "0" * decimal_places

    return val.quantize(Decimal(q), rounding=rounding)


def decimal_power(num, exp):
    return decimal_truncate(Decimal.exp(Decimal.ln(num) * exp))


def decimal_log(num):
    return decimal_truncate(Decimal.log10(num))


def decimal_ln(num):
    return decimal_truncate(Decimal.ln(num))

@hypothesis.given(
    num=hypothesis.strategies.decimals(
        min_value=Decimal(0.1), max_value=Decimal(0.1), places=DECIMAL_PLACES
    ),
    exp=hypothesis.strategies.decimals(
        min_value=Decimal(0.1), max_value=Decimal(0.1), places=DECIMAL_PLACES
    ),
)
@hypothesis.settings(deadline=8000)
def test_power(math_contract, num, exp):

    vyper_power = math_contract.power(num, exp)
    actual_power = decimal_power(num, exp)

    print(vyper_power)
    print(actual_power)

    assert actual_power - RESULT_MAX_OFFSET < vyper_power < actual_power + RESULT_MAX_OFFSET

@hypothesis.given(
    num=hypothesis.strategies.decimals(
        min_value=Decimal(0.1),
        max_value=Decimal(SizeLimits.MAXNUM),
        places=DECIMAL_PLACES,
    )
)
@hypothesis.settings(deadline=5000)
def test_log(math_contract, num):
    vyper_log = math_contract.log(num)
    actual_log = decimal_log(num)

    assert vyper_log == actual_log


@hypothesis.given(
    value=hypothesis.strategies.decimals(
        min_value=Decimal(0.1),
        max_value=Decimal(SizeLimits.MAXNUM),
        places=DECIMAL_PLACES,
    )
)
@hypothesis.settings(deadline=5000)
def test_ln(math_contract, num):
    vyper_ln = math_contract.ln(num)
    actual_ln = decimal_ln(num)

    assert vyper_ln == actual_ln
