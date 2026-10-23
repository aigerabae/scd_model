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

2. Make a patched test copy, keeping his originals untouched (2 repeats):
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

3. Join each analysis into one script and run all three in the background (2 repeats):
```
for a in Analysis1 Analysis2 Analysis3; do
  cat $a/R_Module1_*.txt $a/R_Module2_*.txt $a/R_Module3_*.txt $a/R_Module4_*.txt $a/R_Module5_*.txt > run_$a.R
done
nohup bash -c 'for a in Analysis1 Analysis2 Analysis3; do MC_CORES=16 Rscript run_$a.R > log_$a.txt 2>&1; done' &
```

4. checking test run results (took about 12 minutes):
```
cd /data/ds1825p_I/Projects/SD_001_038_miseq_novaseq_hg19_control_116/vcf/testing_r_code/SCD_2rep
grep -n -iE "error|halted|killed" log_Analysis*.txt
grep -n "Time difference" log_Analysis*.txt
ls Analysis*/ | grep -E "2x5|Model_"
Rscript -e 'x <- as.data.frame(readxl::read_excel("Analysis1/Model_Analysis1.xlsx", sheet="Model_parameters", col_names=FALSE)); k <- c("Stringency","LambdaRule","FinalAlpha","FinalNumberOfPredictors","FinalTrainingAUC","FinalTrainingMCC"); for (i in which(x[[1]] %in% k)) cat(x[i,1], "=", x[i,2], "\n")'
``` 
All files write as expected and results are largely consistent.  
Stringency = VeryLow   
LambdaRule = lambda.min   
FinalAlpha = 0.3   
FinalNumberOfPredictors = 15   
FinalTrainingAUC = 0.91035816035816   
FinalTrainingMCC = 0.782089198204617   

5. 100 repeats (should take 1-2 hours):
```
cd /data/ds1825p_I/Projects/SD_001_038_miseq_novaseq_hg19_control_116/vcf/testing_r_code
cp -r SCD_All SCD_100rep && cd SCD_100rep
B=$PWD
for f in Analysis*/*.txt; do sed -i 's/\r$//' "$f"; sed -i "s#D:/A/Data/SCD_All#$B#g" "$f"; done
for a in Analysis1 Analysis2 Analysis3; do
  cat $a/R_Module1_*.txt $a/R_Module2_*.txt $a/R_Module3_*.txt $a/R_Module4_*.txt $a/R_Module5_*.txt > run_$a.R
done
nohup bash -c 'for a in Analysis1 Analysis2 Analysis3; do MC_CORES=16 Rscript run_$a.R > log_$a.txt 2>&1; done' &
```

6. Comparing results between my run and his:
```
Rscript compare_models.R SCD_100rep SCD_All > comparison.txt
```
