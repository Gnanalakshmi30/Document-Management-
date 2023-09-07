import uuid

def get_physical_mac_address():
    try:
        return ':'.join(['{:02x}'.format((uuid.getnode() >> ele) & 0xff)
                        for ele in range(0, 8 * 6, 8)][::-1])
    except Exception as e:
        print("Error:", e)
        return None

if __name__ == "__main__":
    physical_mac_address = get_physical_mac_address()
    
    if physical_mac_address:
        print(physical_mac_address)
    else:
        print("Unable to retrieve physical MAC address.")




