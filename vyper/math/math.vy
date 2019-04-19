# In order to precisely calculate ln we are using Arithmetic–geometric mean approach
# The formula:
#   ln(x) = pi / 2 * M(1, 4/s) - m * ln(2) where M denotes the arithmetic-geometric mean of 1 and 4/s, and s = x * 2^m
# ...
# We have chosen m = 19 => 2^19 = 524288 and 19 * ln(2) = 1316979643063896087892741


@public
@constant
def big_ln(x: decimal) -> decimal:

    pi: decimal = 31415926535897932384626433832795028.0
    a: decimal = 100000000000000000000.0
    # Here we are using (max(1.0 / x, x) because:
    # if x < 1 => ln(0.1) = -ln(1/0.1) = -ln(10)
    g: decimal = 400000000000000000000.0 / (max(1.0 / x, x) * 524288.0)

    for i in range(9):
        temp: decimal = a
        a = (a + g) / 2.0
        g = sqrt(temp * g)

    result: decimal = (
        (pi / (2.0 * g)) * 1000000000.0 - 1316979643063896087892741.0
    ) / 1000000000000000.0 * 10000000000.0

    if x < 1.0:
        return -result

    return result


# For common usage, because big_ln() returns a high accurate result in form of:
#       big_ln(1234567891.1234567891) = 20933986860072063853
#       ln(1234567891.1234567891) = 20.93398686
@public
@constant
def ln(x: decimal) -> decimal:

    lnResult: decimal = self.big_ln(x)
    return lnResult / 1000000000000000000.0


# Only works for 0 < y < 1 (Bonding mathematics)
@private
@constant
def power_by_exponent(x: decimal, y: decimal) -> decimal:

    exponent: decimal = self.big_ln(x) * y / 10000000000.0

    temp: decimal = 100000000.0
    result: decimal = 100000000.0
    counter: decimal = 100000000.0

    for i in range(256):
        temp = (temp * exponent) / counter
        counter += 100000000.0

        if result == result + temp:
            break

        result += temp

    return result / 100000000.0


@public
@constant
def bonding_power(x: decimal, y: decimal) -> decimal:

    assert x <= 9999999999999.9999999999

    assert y >= 0.0
    assert y <= 1.0

    if x == 0.0:
        return 0.0
    if y == 0.0:
        return 1.0
    if y == 1.0:
        return x

    return self.power_by_exponent(x, y)
