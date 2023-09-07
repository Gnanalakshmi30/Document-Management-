
import sys
from docx import Document


def extract_table_content(docxPath):
    try:
        # Load the Word document
        document = Document(docxPath)
        
        # Extract all tables from the document
        tables = document.tables
        
        # Convert each table to an HTML string
        table_html = []
        for table in tables:
            # Extract the table headers
            headers = [cell.text for cell in table.rows[0].cells]
            
            # Extract the table data
            data = []
            for row in table.rows[1:]:
                data.append([cell.text for cell in row.cells])
            
            # Convert the table data to an HTML string
            rows = []
            for row in data:
                cells = []
                for cell in row:
                    cells.append(f'<td>{cell}</td>')
                rows.append(f'<tr>{" ".join(cells)}</tr>')
            
            # Convert the table headers to an HTML string
            header_row = ''.join([f'<th>{header}</th>' for header in headers])
            header_html = f'<tr>{header_row}</tr>'
            
            # Combine the header and data rows into a single HTML string
            table_html.append(f'<table>{header_html}{" ".join(rows)}</table>')
        
        # Join the table HTML strings into a single HTML string
        html = ''.join(table_html)
        
        print(html.encode('utf-8'))      
    except Exception as e:
        print(e)
        return f"An error occurred: {str(e)}"

arg1 = sys.argv[1]

# arg1 = "C:\\Users\\vaanam EMP\\OneDrive - VAANAM TECHNOLOGIES PRIVATE LIMITED\\Documents\\PhotoApp\\1000\\GeneratedReport\\ELV Test Report Format-Metal tableContent.txt"
extract_table_content(arg1)
