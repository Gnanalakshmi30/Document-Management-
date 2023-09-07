import docxpy
import sys
def my_functionn(docxPath):
    try:
       file = docxPath
       text = docxpy.process(file)
       print(text.encode('utf-8'))
    except Exception as e:
        print(e)
        return f"An error occurred: {str(e)}"  

arg1 = sys.argv[1]

my_functionn(arg1)