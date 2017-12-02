import csv

with open('./cuf/genes.fpkm_tracking') as inp:
    reader = csv.DictReader(inp, delimiter='\t')
    with open('./cuf/genes.tsv', 'w') as out:
        writer = csv.DictWriter(out, reader.fieldnames, delimiter='\t')
        writer.writeheader()
        for row in reader:
            for field in ['FPKM', 'FPKM_conf_lo', 'FPKM_conf_hi']:
                row[field] = row[field].replace('.', ',')
            writer.writerow(row)
