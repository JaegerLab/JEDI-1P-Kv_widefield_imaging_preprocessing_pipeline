# JEDI-1P-Kv_widefield_imaging_preprocessing_pipeline
 Preprocessing pipeline that subtracts background fluorescence, corrects photobleaching, and removes hemodynamic and motion artifact.

The pre-processing pipeline is described in manuscript [link] and follows the pipeline shown below:
 ![preprocessing_pipeline](https://user-images.githubusercontent.com/43519726/182520361-486fedad-b434-4a33-8850-63f820cb98c8.png)

 
 ## Function [proc_dff, regressed_traces] = JEDI_preprocessing(reference_raw_trace, JEDI_raw_trace, parameters) requires the following: 
 1. reference_raw_trace, reference trace (raw light intensity)
 2. JEDI_raw)trace, JEDI-1P-Kv trace (raw light intensity from the same region of interest or pixel as reference trace in 1). 
 3. parameters that determine the the frequency ranges for step-wise regression that removes shared non-voltage artifact in both JEDI-1P-Kv and reference channels
    parameters should include:
          (1) frequency range to filter JEDI-1P-Kv channel. e.g. [0, 70] Hz
          (2) frequency range to remove heartbeat. e.g. [10, 30] Hz
          (3) frequency range to remove potential motion artifact. e.g. [1, 10] Hz
          (4) frequency range to remove hemodynamics. e.g. [0, 1] Hz
          (5) steepness for the filter 
          (6) Imaging duration
          (7) Imaging sample rate
          
    The above set of example parameter could be used in awake behaving mice. 
    For lightly anesthetized mice of which the heart rate might be lower, an alternative set of filters could be [4, 20], [1, 4], [0. 1] Hz instead for the reference channel. 


4. An empirically determined photobleaching model is also necessary for the photobleaching correction. An example file is included in this repository. Full path of the file is required for the file to be load properly. 


## Note that the step-wise regression is not limited to 3 steps. The regression steps as well as corresponding frequency ranges can be added or removed based on specific experimental need. 

**Matlab versions tested: 
MATLAB 2020b, 2021b, and 2022a.

**The following toolbox is needed to be installed on Matlab: 
Signal Processing Toolbox

Aside from installing Matlab and necessary toolbox(es), no additional installation is necessary. 

## Demo script:

A demo script is included in this repository: example_script.m. Necessary files for the demo script to run is also included in the repository.

The output should look like the following: 
![output_fig_example_script](https://user-images.githubusercontent.com/43519726/187534783-df115e64-6215-4d07-b524-a4bbea1778d1.png)

Expected runtime for the demo file is 1.1 s. Note that parfor from Parallel Computing Toolbox can be used to speed up the pipeline when running a large number of traces.



