# RAPORT
mkdir raporty_przed_czyszczeniem
~/Programy/FastQC/fastqc -t 8 -o ./raporty_przed_czyszczeniem ./dane/A1.fastq.gz ./dane/A2.fastq.gz ./dane/B1.fastq.gz ./dane/B2.fastq.gz ./dane/C1.fastq.gz ./dane/C2.fastq.gz ./dane/input1.fastq.gz ./dane/input2.fastq.gz
# CZYSZCZENIE
mkdir oczyszczone
for f in A B C input
do
    java -jar ~/Programy/Trimmomatic-0.36/trimmomatic-0.36.jar PE -threads 8 -phred33 ./dane/$f1.fastq.gz ./dane/$f2.fastq.gz -baseout ./oczyszczone/$f.fastq.gz TRAILING:15 LEADING:15
done
# RAPORT
mkdir raporty_po_czyszczeniu
~/Programy/FastQC/fastqc -t 8 -o ./raporty_po_czyszczeniu ./oczyszczone/A_1P.fastq.gz ./oczyszczone/A_2P.fastq.gz ./oczyszczone/B_1P.fastq.gz ./oczyszczone/B_2P.fastq.gz ./oczyszczone/C_1P.fastq.gz ./oczyszczone/C_2P.fastq.gz ./oczyszczone/input_1P.fastq.gz ./oczyszczone/input_2P.fastq.gz

# BOWTIE
wget ftp://igenome:G3nom3s4u@ussd-ftp.illumina.com/Schizosaccharomyces_pombe/Ensembl/EF2/Schizosaccharomyces_pombe_Ensembl_EF2.tar.gz
mkdir wyniki
for f in A B C input
do
    ~/Programy/bowtie/bowtie2 -x ./EF2/Sequence/Bowtie2Index/genome -p 6 -1 ./oczyszczone/$f_1P.fastq.gz -2 ./oczyszczone/$f_2P.fastq.gz -S wyniki/$f.sma 2> wyniki/$f.log
done
# SAMTOOLS
mkdir bam
for f in A B C input
do
    samtools view -@ 8 -S -b wyniki/$f.sam -o bam/$f.bam
    samtools sort -@ 8 bam/$f.bam bam/$f_s
    rm bam/$f.bam
    mv bam/$f_s.bam bam/$f.bam
    samtools index bam/$f.bam
done

# MACS
for f in A B
do
    macs2 callpeak -t ./bam/$f.bam -c ./bam/input.bam -f BAM -n $f -g 12462637 --outdir ./peaks
done

# TopHat
PATH=$PATH:~/Programy/bowtie
~/Programy/tophat-2.1.1.Linux_x86_64/tophat2 -p 8 ./EF2/Sequence/Bowtie2Index/genome ./oczyszczone/C_1P.fastq.gz ./oczyszczone/C_2P.fastq.gz 
samtools sort -@ 8 tophat_out/accepted_hits.bam tophat_out/accepted_hits_s
rm tophat_out/accepted_hits.bam
mv tophat_out/accepted_hits_s.bam tophat_out/accepted_hits.bam
samtools index tophat_out/accepted_hits.bam

# CUFFLINK
mkdir cuf
~/Programy/cufflinks-2.2.1.Linux_x86_64/cufflinks -p 8 -o ./cuf/ -g ./EF2/Annotation/Genes/genes.gtf ./tophat_out/accepted_hits.bam

# To jest chyba totalnie zbędne...
mkdir cufq
~/Programy/cufflinks-2.2.1.Linux_x86_64/cuffquant -p 8 -o ./cufq/ ./cuf/transcripts.gtf ./tophat_out/accepted_hits.bam
mkdir cufn
# nie jestem co do tego przekonany bo 2 razy daje ten sam plik do normalizacji, ale może dzięki temu ogarnie tło
~/Programy/cufflinks-2.2.1.Linux_x86_64/cuffnorm  -o ./cufn/ ./cuf/transcripts.gtf ./cufq/abundances.cxb ./cufq/abundances.cxb 
# Koniec zbędności

python ./konwersja_csv.py

# BedTools (Chip-seq)
mkdir piki_analiza
~/Programy/bedtools2/bin/closestBed -a ./peaks/A_summits.bed -b ./EF2/Annotation/Genes/genes.bed > ./piki_analiza/A_geny.csv
~/Programy/bedtools2/bin/closestBed -a ./peaks/B_summits.bed -b ./EF2/Annotation/Genes/genes.bed > ./piki_analiza/B_geny.csv
