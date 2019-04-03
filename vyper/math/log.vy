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


@public
@constant
def number_power_ten(num: decimal) -> decimal:

    result: decimal = num

    for i in range(3):
        result *= result

    return result * num * num


@public
@constant
def log(x: decimal) -> decimal:
    result: decimal = 0.0
    nextDigit: decimal = 0.0

    num: decimal = x
    digitPadding: decimal = 11.0

    # 11 is the precision fraction
    for i in range(11):
        nextDigit = self.get_number_length(num) - 1.0
        result += nextDigit * self.TEN_POWERS_TABLE[digitPadding]

        num = self.number_power_ten(num / self.TEN_POWERS_TABLE[nextDigit])
        digitPadding -= 1.0

    # Divided by precision
    return result / self.TEN_POWERS_TABLE[11]


@public
@constant
def ln(x: decimal) -> decimal:
    e: decimal = 0.4342944819
    return self.log(x) / e
