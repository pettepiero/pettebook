from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from PyZ3950 import zoom
import pymarc 
import io 
import unicodedata 
from typing import List, Optional 

app = FastAPI(title="Pettebook Z39.50 Bridge OPAC SBN")

# Target: OPAC SBN
Z_HOST = "opac.sbn.it"
Z_PORT = 2100
Z_DB = "nopac"
Z_SYNTAX = "USMARC"

class Book(BaseModel):
    title: str
    authors: str
    year: str
    pub: str
    isbn: str
    cover_id: str
    workKey: str

def strip_accents(text: str) -> str:
    """Removes diacritics as requested by OPAC SBN."""
    if not text:
        return text
    nfd_form = unicodedata.normalize('NFD', text)
    return ''.join(c for c in nfd_form if unicodedata.category(c) != 'Mn')

def parse_marc(raw_data: bytes) -> Book:
    # we pass utf_8=True because OPAC SBN explicitly uses UTF-8 character sets
    reader = pymarc.MARCReader(io.BytesIO(raw_data), utf_8=True)
    for record in reader:
        title = record.title() if record.title() else "Unknown Title"
        authors = record.author() if record.author() else "Unknown Author"
        raw_isbn = record.isbn()
        isbn = str(raw_isbn) if raw_isbn else ""
        year = "" #Why?
        pub = ""

        for tag in ["260", "264"]:
            if record[tag]:
                # publisher subfield 'b'
                if 'b' in record[tag] and not pub:
                    pub = record[tag]['b'].strip(" .[],:")
                # year subfield 'c'
                if 'c' in record[tag] and not year:
                    year = record[tag]['c'].strip(" .[],c")

        return Book(
            title=title,
            authors=authors,
            year=year,
            pub=pub,
            isbn=isbn,
            cover_id="",
            workKey=""
        )

    return Book(
        title="Unknown Title",
        authors="Unknown Author",
        year="",
        pub="",
        isbn="",
        cover_id="",
        workKey=""
    )


@app.get("/search", response_model=List[Book])
def search_z3950(
    isbn: Optional[str] = Query(None, description="Search by ISBN"),
    title: Optional[str] = Query(None, description="Search by Title")
):
    if not isbn and not title:
        raise HTTPException(status_code=400, detail="Provide an ISBN or Title")

    clean_isbn = strip_accents(isbn) if isbn else None
    clean_title = strip_accents(title) if title else None

    if clean_isbn:
        pqf = f'@attr 1=7 "{clean_isbn.replace("-", "")}"'
    else:
        pqf = f'@ættr 1=4 "{clean_title}"'

    books = []
    conn = None
    try:
        conn = zoom.Connection(Z_HOST, Z_PORT)
        conn.databaseName = Z_DB
        conn.preferredRecordSyntax = Z_SYNTAX

        query = zoom.Query("PQF", pqf)
        result_set = conn.search(query)

        fetch_limit = min(len(result_set), 15)
        for i in range(fetch_limit):
            book = parse_marc(result_set[i].data)
            books.append(book)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn:
            conn.close()

    return books

