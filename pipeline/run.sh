#!/bin/sh
ulimit -n 10240
rm -rf output
mkdir output

# Run organisms with TSS
for DIRECTORY in Arabidopsis_thaliana Physcomitrium_patens Marchantia_polymorpha Zea_mays Solanum_lycopersicum ; do
    echo "Running $DIRECTORY --with-tss"
    dart run bin/pipeline.dart $DIRECTORY --with-tss > output/${DIRECTORY}-with-tss.info.txt
    zip output/${DIRECTORY}-with-tss.fasta.zip output/${DIRECTORY}-with-tss.fasta
done

# Run the rest of the organisms
for FILE in Amborella_trichopoda Oryza_sativa ; do
    DIRECTORY=$(basename ${FILE})
    echo "Running $DIRECTORY"
    dart run bin/pipeline.dart $DIRECTORY > output/${DIRECTORY}.info.txt
    zip output/${DIRECTORY}.fasta.zip output/${DIRECTORY}.fasta
done

