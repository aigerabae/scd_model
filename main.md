Running Saenko's code:

0. Opening the server and installing conda env with dependencies
```
ssh prom@10.1.131.183
# password - prom
conda create -n scd -c conda-forge r-base r-readxl r-glmnet r-caret r-dplyr r-openxlsx r-proc r-doparallel r-foreach r-parallelly
conda activate scd
conda install -c conda-forge r-gee r-expm r-energy r-mass
Rscript -e 'install.packages("VariableScreening", repos="https://cloud.r-project.org")'
```

1. Checking if all pre-requisites are installed:
```
Rscript -e 'p <- c("readxl","VariableScreening","glmnet","caret","dplyr","openxlsx","pROC","doParallel","foreach","parallelly"); print(p[!sapply(p, requireNamespace, quietly=TRUE)])'
```

2. Make a patched test copy, keeping his originals untouched:
```
cd /data/ds1825p_I/Projects/SD_001_038_miseq_novaseq_hg19_control_116/vcf/testing_r_code
cp -r SCD_All SCD_2rep && cd SCD_2rep
B=$PWD
for f in Analysis*/*.txt; do
  sed -i 's/\r$//' "$f"                      # Windows line endings
  sed -i "s#D:/A/Data/SCD_All#$B#g" "$f"     # paths
done
sed -i 's/^n_repeats <- 100 /n_repeats <- 2   /' Analysis*/R_Module1_*.txt
sed -i 's/_100x5_/_2x5_/g' Analysis*/R_Module2_*.txt
grep -n "^n_repeats" Analysis*/R_Module1_*.txt   # should show 2 for all three
```

3. Join each analysis into one script and run all three in the background:
```
for a in Analysis1 Analysis2 Analysis3; do
  cat $a/R_Module1_*.txt $a/R_Module2_*.txt $a/R_Module3_*.txt $a/R_Module4_*.txt $a/R_Module5_*.txt > run_$a.R
done
nohup bash -c 'for a in Analysis1 Analysis2 Analysis3; do MC_CORES=16 Rscript run_$a.R > log_$a.txt 2>&1; done' &
```
