import csv
import re
from copy import copy

BASE_DIR = '/home/behoston/Dokumenty/TSG2/zaliczeniowy_1/EF2/Annotation/Genes/'
TYPES = {
    'CDS': [],
    'exon': [],
    'start_codon': [],
    'stop_codon': [],
    'transcript': [],
    'UTR': [],
}


def get_gene_id(row):
    return re.match(r'.*gene_id\s+"(.*?)";', row['additional_data']).group(1)


with open(BASE_DIR + 'genes.gtf') as f:
    gtf_fields = ['chromosome', 'source', 'type', 'start', 'stop', '_', 'strand', 'score', 'additional_data']
    reader = csv.DictReader(f, gtf_fields, delimiter='\t')
    for row in reader:
        row['gene_id'] = get_gene_id(row)
        TYPES[row['type']].append(row)


def row_to_bed(row):
    return (
        f'{row["chromosome"]}\t'
        f'{row["start"]}\t'
        f'{row["stop"]}\t'
        f'{row["gene_id"]}\t'
        f'{row["score"]}\t'
        f'{row["strand"]}\n'
    )


for type_name, rows in TYPES.items():
    with open(f'{BASE_DIR}{type_name}.bed', 'w') as f:
        for row in rows:
            f.write(row_to_bed(row))


def start_to_promoter(row):
    promoter = copy(row)
    start = int(row['start'])
    promoter['stop'] = max(start - 1, 0)
    promoter['start'] = max(start - 500, 0)
    return promoter


with open(f'{BASE_DIR}promoter.bed', 'w') as f:
    for row in TYPES['start_codon']:
        promoter = start_to_promoter(row)
        f.write(row_to_bed(promoter))
