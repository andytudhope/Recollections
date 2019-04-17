from decimal import ROUND_DOWN, ROUND_FLOOR, Decimal, getcontext

from eth_tester.exceptions import TransactionFailed
import hypothesis
import pytest

from vyper.utils import SizeLimits

getcontext().prec = 168
DECIMAL_PLACES = 10
# 0000999999 is because the upper limit 9999999999999.9999999999
# The accuracy here is to the 4-th digit after the point
RESULT_MAX_OFFSET = Decimal(0.0000999999)
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
        min_value=Decimal(0), max_value=Decimal(999999.9999999999), places=DECIMAL_PLACES
    ),
    exp=hypothesis.strategies.decimals(
        min_value=Decimal(0), max_value=Decimal(1), places=DECIMAL_PLACES
    ),
)
@hypothesis.settings(deadline=8000)
def test_power(math_contract, num, exp):

    vyper_power = math_contract.bonding_power(num, exp)
    actual_power = decimal_power(num, exp)

    assert actual_power == vyper_power



@hypothesis.given(
    num=hypothesis.strategies.decimals(
        min_value=Decimal(999999.9999999999), max_value=Decimal(9999999999999.9999999999), places=DECIMAL_PLACES
    ),
    exp=hypothesis.strategies.decimals(
        min_value=Decimal(0), max_value=Decimal(1), places=DECIMAL_PLACES
    ),
)
@hypothesis.settings(deadline=8000)
def test_big_num_power(math_contract, num, exp):

    vyper_power = math_contract.bonding_power(num, exp)
    actual_power = decimal_power(num, exp)

    assert actual_power - RESULT_MAX_OFFSET < vyper_power < actual_power + RESULT_MAX_OFFSET

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
