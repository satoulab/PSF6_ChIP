#!/bin/bash

####################################################
#                                                  # 
#    180715 ChIP-seq-SE_bwa_hg19.sh                #  
#                                                  #
#    180912 add picard step                        #
#                                                  #
####################################################

# Start timer
begin=$(date +%s)

# Step 1: Filter to keep only primary alignments
echo "[1/7] Filtering to keep only primary mapped reads..."
samtools view -bh -F 256 -o hg19_uniq.bam hg19.bam

# Step 2: Sort the BAM file
echo "[2/7] Sorting BAM file..."
samtools sort hg19_uniq.bam -o hg19_uniq_sort.bam

# Step 3: Remove PCR duplicates using Picard
echo "[3/7] Removing PCR duplicates..."
picard MarkDuplicates \
    INPUT=hg19_uniq_sort.bam \
    OUTPUT=hg19_uniq_sort_duprmv.bam \
    METRICS_FILE=marked_dup_metrics.txt \
    REMOVE_DUPLICATES=true \
    ASSUME_SORTED=true \
    MAX_RECORDS_IN_RAM=null

# Step 4: Index the deduplicated BAM
echo "[4/7] Indexing deduplicated BAM..."
samtools index hg19_uniq_sort_duprmv.bam

# Step 5: Convert BAM to SAM, removing unmapped reads
echo "[5/7] Filtering unmapped reads and converting BAM to SAM..."
samtools view -F 0x4 -h hg19_uniq_sort_duprmv.bam > hg19_map_sort_duprmv.sam

# Step 6: Count mapped reads
echo "[6/7] Counting mapped reads..."
mapped_reads=$(awk '$1!~/^@/ {print}' hg19_map_sort_duprmv.sam | wc -l)
echo "Mapped reads: $mapped_reads"

# Step 7: MACS2 Peak Calling
echo "[7/7] Running MACS2 peak calling with default parameters..."
macs2 callpeak \
  -t hg19_uniq_sort_duprmv.bam \
  -c INPUT_CONTROL.bam \
  -f BAM \
  -g hs \
  -n sample_macs2_default \
  --outdir macs2_output \
  -q 0.05

echo "MACS2 peak calling complete. Peaks saved in 'macs2_output/' directory."

# Cleanup intermediate files
echo "Cleaning up intermediate files..."
rm hg19.bam
rm hg19.sam
rm hg19_uniq.bam
rm hg19_uniq_sort.bam


# Summary and timing
end=$(date +%s)
duration=$(($end - $begin))
echo "Task completed on: $(date)"
echo "Total runtime: $(($duration / 3600)) hours $(($duration % 3600 / 60)) minutes $(($duration % 60)) seconds"
echo "Congratulations! Data processing complete!"
