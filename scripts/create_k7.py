total_bytes = 0


def write_data_bloc(k7, filename, where):
    global total_bytes
    with open(filename, "rb") as f:
        data = f.read()

    nb_bytes = len(data)
    bytes_high = int(nb_bytes / 256)
    bytes_low = nb_bytes % 256

    header = [5, 0, where, bytes_low, bytes_high, 0xff]
    k7.write(bytes(header))
    total_bytes += 6

    for i in range(bytes_high):
        k7.write(bytes([0]))
        k7.write(data[i*256:i*256+256])
        total_bytes += 257

    k7.write(bytes([bytes_low]))
    k7.write(data[bytes_high*256:])
    total_bytes += bytes_low + 1


def write_end_block(k7):
    global total_bytes
    header = [5, 0, 0x4c, 0, 0xc0, 0xfd]
    k7.write(bytes(header))
    total_bytes += 6


with open("build/dontwake_k7.k7", "wb") as k7:
    write_data_bloc(k7, "build/splash.bin", 0xc0)
    write_data_bloc(k7, "build/dontwake.bin", 0x70)
    write_data_bloc(k7, "build/start.bin", 0x4c)    
    write_end_block(k7)

    print(total_bytes)
