#!/usr/bin/python
# Runs in Python3
# requires PDFMiner https://github.com/pdfminer/pdfminer.six
# The resulting hash will probably need some minor fixing.

import sys
import re
import argparse
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdftypes import resolve1


# For example: python utilities/field_parser.py assets/form_template.pdf 
# 
# Credit: https://stackoverflow.com/a/42929351/10641955
#
parser = argparse.ArgumentParser("field_parser")
parser.add_argument("file", help="The path to the PDF file that you want to parse", type=str)
args = parser.parse_args()

fp = open(args.file, 'rb')

parser = PDFParser(fp)
doc = PDFDocument(parser)
font_regex = re.compile('\/\D+(\d+)')

def convert(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s1 = s1.replace(' ', '_')
    s1 = s1.replace('__', '_')
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

fields = resolve1(resolve1(doc.catalog['AcroForm'])['Fields'])
for i in fields:
    field = resolve1(i)
    if field.get('Rect') == None:
      continue
    name, position = field.get('T'), field.get('Rect')
    name = convert(name.decode('UTF-8'))
    width = int(round(position[2] - position[0]))
    height = int(round(position[3] - position[1]))
    x = int(round(position[0]))
    font_size = None
    font_size = int(font_regex.match(field.get('DA').decode('UTF-8')).group(1))
    if height < 1:
      height = height * -1
    y = int(round(position[1]) + height)
    if font_size > 0 and font_size != 10:
      print(':{0} => {{ :x => {1}, :y => {2}, :w => {3}, :h => {4}, :font_size => {5} }}, '.format(name, x, y, width, height, font_size))
    else:
      print(':{0} => {{ :x => {1}, :y => {2}, :w => {3}, :h => {4} }}, '.format(name, x, y, width, height))
