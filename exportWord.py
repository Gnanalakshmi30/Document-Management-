import win32com.client as win32
import sys
def my_functionn(htmlFile,docxPath):
    try:
        word = win32.gencache.EnsureDispatch('Word.Application')
        doc = word.Documents.Open(htmlFile)
        doc.SaveAs(docxPath, FileFormat=16)
        doc.Close()
        word.Quit()
    except Exception as e:
        print(e)
        return f"An error occurred: {str(e)}"  

arg1 = sys.argv[1]
arg2 = sys.argv[2]
my_functionn(arg1, arg2)

# import mammoth
# import sys

# def convert_to_docx(html_file, docx_path):
#     try:
#         with open(html_file, "rb") as html_file_data:
#             result = mammoth.convert_to_document(html_file_data, output_format="docx")
#         with open(docx_path, "wb") as docx_file:
#             docx_file.write(result.value)
#     except Exception as e:
#         print(e)
#         return f"An error occurred: {str(e)}"

# arg1 = sys.argv[1]
# arg2 = sys.argv[2]
# convert_to_docx(arg1, arg2)