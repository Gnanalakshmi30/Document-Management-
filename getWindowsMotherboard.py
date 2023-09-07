import wmi

def get_motherboard_serial_number():
    c = wmi.WMI()
    motherboard = c.Win32_BaseBoard()[0]
    serial_number = motherboard.SerialNumber
    return serial_number

# Example usage
serial_number = get_motherboard_serial_number()
print(serial_number)