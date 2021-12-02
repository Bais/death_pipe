require daslib/media


var y = 0
def debug_out_start()
    y = 10

def debug_out(text)
    text_out(50, y, text, 0xff00ffff)
    y += 20
