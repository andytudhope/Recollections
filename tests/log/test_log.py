from decimal import Decimal


def test_log(w3, LOG):
    assert LOG.log(7) == Decimal('0.84509804')
    assert LOG.ln(7) == Decimal('1.945910149')
