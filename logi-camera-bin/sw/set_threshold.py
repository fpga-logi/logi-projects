import logi

THRESHOLD = 0x7F
logi.logiWrite(0x1004, (THRESHOLD, THRESHOLD))
