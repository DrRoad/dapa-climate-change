#!/bin/bash

#$ -l h_rt=04:00:00
#$ -l h_vmem=1G
#$ -l cputype=intel
#$ -cwd -V

LIM_A=$1
GCM_ID=$2
EXP_ID=$3

#get process id based on name of screen
PID=${GCM_ID}_${EXP_ID}_${LIM_A}
THOST="arc1"

#make processing directory if it doesnt exist
if [ ! -d "~/workspace/cmip5_adap/process_${THOST}_${PID}" ]
then
	mkdir ~/workspace/cmip5_adap/process_${THOST}_${PID}
fi

cd ~/workspace/cmip5_adap/process_${THOST}_${PID}

#remove run script if it exists
if [ -f "run.R" ]
then
	rm -vf run.R
fi

#copy run file from local svn repo
cp -vf ~/Repositories/dapa-climate-change/trunk/PhD/0007-crop-modelling/scripts/cmip5/09.glam-adap_batch_ARC1.R run.R

#run R in batch for desired stuff
R CMD BATCH --vanilla --slave "--args lim_a=$LIM_A gcm_id='$GCM_ID' exp_id=$EXP_ID" run.R ~/workspace/outfiles/out_${THOST}_${PID}.out

#remove junk
rm -vf ~/workspace/cmip5_adap/process_${THOST}_${PID}/run.R
rm -f ~/workspace/outfiles/out_${THOST}_${PID}.out
rm -rf ~/workspace/localcopy/copy_${THOST}_${PID}


