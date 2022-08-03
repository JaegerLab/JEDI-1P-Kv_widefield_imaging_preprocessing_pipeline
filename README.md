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

## Note that the step-wise regression is not limited to 3 steps. The regression steps as well as corresponding frequency ranges can be added or subtracted based on specific experimental need. 

**The following toolbox is needed to be installed on Matlab: 
Signal Processing Toolbox
