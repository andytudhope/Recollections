TEN_POWERS_TABLE: public(map(decimal, decimal))


@public
def __init__():
    self.TEN_POWERS_TABLE[0.0] = 1.0
    self.TEN_POWERS_TABLE[1.0] = 10.0
    self.TEN_POWERS_TABLE[2.0] = 100.0
    self.TEN_POWERS_TABLE[3.0] = 1000.0
    self.TEN_POWERS_TABLE[4.0] = 10000.0
    self.TEN_POWERS_TABLE[5.0] = 100000.0
    self.TEN_POWERS_TABLE[6.0] = 1000000.0
    self.TEN_POWERS_TABLE[7.0] = 10000000.0
    self.TEN_POWERS_TABLE[8.0] = 100000000.0
    self.TEN_POWERS_TABLE[9.0] = 1000000000.0
    self.TEN_POWERS_TABLE[10.0] = 10000000000.0
    self.TEN_POWERS_TABLE[11.0] = 100000000000.0


@private
@constant
def get_number_length(num: decimal) -> decimal:

    numberLength: int128 = 0
    uintNumber: uint256 = convert(num, uint256)

    for i in range(256):
        if uintNumber < 1:
            break

        uintNumber /= 10
        numberLength += 1

    return convert(numberLength, decimal)


@private
@constant
def number_power_ten(num: decimal) -> decimal:

    result: decimal = num

    for i in range(3):
        result *= result

    return result * num * num


@public
@constant
def log(x: decimal) -> decimal:

    assert x > 0.0

    result: decimal = 0.0
    nextDigit: decimal = 0.0

    num: decimal = max(1.0 / x, x)
    digitPadding: decimal = 11.0

    # 11 is the precision fraction
    for i in range(11):
        nextDigit = self.get_number_length(num) - 1.0
        result += nextDigit * self.TEN_POWERS_TABLE[digitPadding]

        num = self.number_power_ten(num / self.TEN_POWERS_TABLE[nextDigit])
        digitPadding -= 1.0

    # Divided by precision
    if x < 1.0:
        return -(result / self.TEN_POWERS_TABLE[11])

    return result / self.TEN_POWERS_TABLE[11]


@public
@constant
def ln(x: decimal) -> decimal:
    e: decimal = 0.4342944819
    return self.log(x) / e


TEN_LOG: constant(decimal) = 2.3025850929
LONG_ONE: constant(decimal) = 10000000000.0


@private
@constant
def exponent_by_squaring(x: decimal, y: decimal) -> decimal:

    if y == 0.0:
        return 1.0
    if y == 1.0:
        return x

    result: decimal = x * x
    exponent: int128 = convert(max(-y, y), int128)

    if y % 2.0 != 0.0:
        result *= x
        exponent -= 1

    for i in range(1, 256):
        if i >= exponent / 2:
            break

        result *= x * x

    if y < 0.0:
        return 1.0 / result

    return result


@private
@constant
def exponent_by_log(x: decimal, y: decimal) -> decimal:

    if x == 1.0:
        return 1.0

    exponent: decimal = self.log(x) * y * TEN_LOG

    temp: decimal = 1.0
    result: decimal = 1.0
    counter: decimal = 1.0

    for i in range(256):
        temp = temp * exponent / counter
        counter += 1.0

        if result == result + temp:
            break

        result += temp

    return (result * (1.0 + exponent - self.ln(result)) / 100.0) * 100.0


@public
@constant
def power(x: decimal, y: decimal) -> decimal:
    if (y * LONG_ONE) % LONG_ONE == 0.0:
        return self.exponent_by_squaring(x, y)
    else:
        return self.exponent_by_log(x, y)
