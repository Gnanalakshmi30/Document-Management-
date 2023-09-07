import mammoth
import sys

def my_function(selectedFile,htmlFile):
    try:
        f = open(selectedFile, 'rb')
        b = open(htmlFile, 'wb')
        document = mammoth.convert_to_html(f)
        b.write(b'<html><head><style>table {border-collapse: collapse; width: 100%;} th, td {border: 1px solid black; padding: 8px; text-align: left;} th {background-color: #dddddd;}</style></head><body>')
        b.write(document.value.encode('utf8'))
        b.write(b'</body></html>')
        f.close()
        b.close()
    except Exception as e:
        return f"An error occurred: {str(e)}"   

arg1 = sys.argv[1]
arg2 = sys.argv[2]
my_function(arg1, arg2)