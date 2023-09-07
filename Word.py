import sys
import win32com.client as win32
import os

def my_function(selectedFile,htmlFile):
    try:
        word = win32.gencache.EnsureDispatch('Word.Application')
        word.Visible = False
        doc = word.Documents.Open(os.path.abspath(selectedFile))
        doc.SaveAs(os.path.abspath(htmlFile), FileFormat=8)
        doc.Close()
        word.Quit()
    except Exception as e:
        return f"An error occurred: {str(e)}"   

arg1 = sys.argv[1]
arg2 = sys.argv[2]
my_function(arg1, arg2)

# import os
# import win32com.client as win32

# word_path = "C:\\Photo_app\\Documents\\ELV Test Report Format - Polymer.docx"
# output_path = "C:\\Users\\New\\Downloads\\file.html"

# word = win32.gencache.EnsureDispatch('Word.Application')
# word.Visible = False

# doc = word.Documents.Open(os.path.abspath(word_path))

# doc.SaveAs(os.path.abspath(output_path), FileFormat=8)

# doc.Close()
# word.Quit()

# import mammoth
# import sys

# def my_function(selectedFile,htmlFile):
#     try:
#         f = open(selectedFile, 'rb')
#         b = open(htmlFile, 'wb')
#         document = mammoth.convert_to_html(f)
#         b.write(b'<html><head><style>table {border-collapse: collapse; width: 100%;} th, td {border: 1px solid black; padding: 8px; text-align: left;} th {background-color: #dddddd;}</style></head><body>')
#         b.write(document.value.encode('utf8'))
#         b.write(b'</body></html>')
#         f.close()
#         b.close()
#     except Exception as e:
#         return f"An error occurred: {str(e)}"   

# arg1 = sys.argv[1]
# arg2 = sys.argv[2]
# my_function(arg1, arg2)


# import win32com.client as win32
# # Open MS Word
# word = win32.gencache.EnsureDispatch('Word.Application')

# doc = word.Documents.Open(word_path)


# # wdFormatFilteredHTML has value 10
# # saves the doc as an html
# doc.SaveAs(output_path, 10)

# doc.Close()
# # noinspection PyBroadException
# try:
#     word.ActiveDocument()
# except Exception:
#     word.Quit()


# import win32com.client
# import codecs

# word_path = "C:\\Badhmabalaji\\Project\\Report\\Docx\\ELV Test Report Format - Metal.doc"
# output_path = "C:\\Users\\VTAdministrator\\Downloads\\file.html"

# doc = win32com.client.GetObject(word_path)
# with codecs.open(output_path, "w", encoding="utf8") as f:
#     f.write("<html><body>")
#     for para in doc.Paragraphs:
#         text = para.Range.Text
#         style = para.Style.NameLocal
#         f.write('<p class="%(style)s">%(text)s</p>\n' % locals())

# doc.Close()


# from docx import Document
# from docx2html import convert

# # Open the Word document
# document = Document('example.docx')

# # Convert the document to HTML
# html = convert(document)

# # Save the HTML output to a file
# with open('output.html', 'w') as f:
#     f.write(html)


# import pypandoc

# word_path = "C:\\Badhmabalaji\\Project\\Report\\Docx\\ELV Test Report Format - Metal.doc"
# output_path = "C:\\Users\\VTAdministrator\\Downloads\\file.html"

# # Convert Word to HTML
# output = pypandoc.convert_file(word_path, 'html')

# # Save the HTML output to a file
# with open(output_path, 'w') as f:
#     f.write(output)


# from docx import Document
# from html5lib import HTMLParser, serialize

# word_path = "C:\\Users\\VTAdministrator\\Downloads\\Document1.docx"
# output_path = "C:\\Users\\VTAdministrator\\Downloads\\file.html"

# # Open the Word document
# document = Document(word_path)

# # Convert the document to HTML
# html = ''
# for paragraph in document.paragraphs:
#     html += paragraph._element.xml
# html = '<html><body>' + html + '</body></html>'
# tree = HTMLParser().parse(html)
# output = serialize(tree)

# # # Save the HTML output to a file
# # with open(output_path, 'w') as f:
# #     f.write(output)


# from docx import Document
# from bs4 import BeautifulSoup

# word_path = "C:\\Users\\VTAdministrator\\Downloads\\document.docx"
# output_path = "C:\\Users\\VTAdministrator\\Downloads\\file.html"


# # Load the Word document
# doc = Document(word_path)

# # Initialize a BeautifulSoup object
# soup = BeautifulSoup('', 'html.parser')

# # Loop through each block-level element in the document
# for block in doc.blocks:
#     # Handle paragraphs
#     if block.style.name.startswith('Heading') or block.style.name == 'Normal':
#         # Create a new HTML <p> tag and set the content
#         p_tag = soup.new_tag('p')
#         p_tag.string = block.text

#         # Add any paragraph-level formatting to the tag
#         if block.alignment == 0:
#             p_tag['style'] = 'text-align: left;'
#         elif block.alignment == 1:
#             p_tag['style'] = 'text-align: center;'
#         elif block.alignment == 2:
#             p_tag['style'] = 'text-align: right;'

#         # Add the new <p> tag to the soup object
#         soup.append(p_tag)

#     # Handle tables
#     elif block.__class__.__name__ == 'Table':
#         # Create a new HTML <table> tag
#         table_tag = soup.new_tag('table')

#         # Loop through each row in the table
#         for row in block.rows:
#             # Create a new HTML <tr> tag
#             tr_tag = soup.new_tag('tr')

#             # Loop through each cell in the row
#             for cell in row.cells:
#                 # Create a new HTML <td> tag and set the content
#                 td_tag = soup.new_tag('td')
#                 td_tag.string = cell.text

#                 # Add any cell-level formatting to the tag
#                 if cell.width:
#                     td_tag['style'] = f'width: {cell.width}px;'

#                 # Add the new <td> tag to the <tr> tag
#                 tr_tag.append(td_tag)

#             # Add the new <tr> tag to the <table> tag
#             table_tag.append(tr_tag)

#         # Add the new <table> tag to the soup object
#         soup.append(table_tag)

#     # Handle images
#     elif block.__class__.__name__ == 'InlineShape' and block.has_picture:
#         # Create a new HTML <img> tag and set the source and alt text
#         img_tag = soup.new_tag('img')
#         img_tag['src'] = f"data:image/png;base64,{block.image.blob}"
#         img_tag['alt'] = block.alt_text

#         # Add any image-level formatting to the tag
#         if block.width:
#             img_tag['style'] = f'width: {block.width}px;'

#         # Add the new <img> tag to the soup object
#         soup.append(img_tag)

# # Save the HTML to a file
# with open(output_path, 'w') as f:
#     f.write(str(soup))


# from htmldocx import HtmlToDocx
# import sys
# def my_functionn(htmlFile,docxPath):
#     try:
#         new_parser = HtmlToDocx()
#         new_parser.parse_html_file(htmlFile, docxPath)
#     except Exception as e:
#         print(e)
#         return f"An error occurred: {str(e)}"  

# arg1 = sys.argv[1]
# arg2 = sys.argv[2]
# my_functionn(arg1, arg2)