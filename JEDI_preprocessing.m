%% Function that extract voltage signals from imaging traces
function [proc_dff, regressed_traces] = JEDI_preprocessing(reference_raw_trace, JEDI_raw_trace, parameters)
    %% Set up Parameters
    % example set of input frequencies; the exact values can vary based on
    % experimental need. 
    % 
    % parameters.green_pass_fs = [0, 70];
    % parameters.red_pass_heartbeat = [10, 30];     % band pass filter to extract heartbeat
    % parameters.red_pass_motion = [1, 10];         % band pass filter to extract motion artifact
    % parameters.red_pass_slowHemo = [0.01, 1];     % lowpass filter for extracting slow hemodynamics
    % parameters.LFP_pass_fs = [0, 70];
    % parameters.steepness = 0.95;                  % steepness for the filter
    % parameters.IMG_duration = 20.48;              % imaging trial duration
    % parameters.IMG_sampleRate = 200;              % frames/s
    
    % lowpass filter for JEDI-1P-Kv
    green_pass_fs = parameters.green_pass_fs;
    % band pass filter to extract heartbeat at its harmonics (Step 1)
    red_pass_heartbeat = parameters.red_pass_heartbeat;
    % band pass filter to extract potential motion artifact (Step 2)
    red_pass_motion = parameters.red_pass_motion; 
    % lowpass filter to extract slow hemodynamics (Step 3)
    red_pass_slowHemo = parameters.red_pass_slowHemo;
    
    steepness = parameters.steepness;           % steepness for the filter
    IMG_duration = parameters.IMG_duration;     % imaging trial duration
    IMG_sampleRate = parameters.IMG_sampleRate; % frames/s
    
    % Average background fluorescence: 
    % determined experimentally; t
    % the exact value might vary based on the setups and imaging window preparation
    backgroundF_g = 590; 
    backgroundF_r = 276;
    
    %% 1. Subtract baseline fluorescence
    proc_red = reference_raw_trace - backgroundF_r;
    proc_green = JEDI_raw_trace - backgroundF_g;
    
    %% 2. Detrending to correct photobleaching
    
    % load function that describes photobleaching exponential decay 
    % first load p; Note that the decay might be different depending on the setup
    % An example file is included in the repository
    filePath_photobleaching_decay = ''; % full file path for the fitted phtobleaching exponential decay
    
    p = load(filePath_photobleaching_decay);
    
    fields = fieldnames(p);             % should only be one field
    p = p.(cell2mat(fields(1)));        % remove the subfield and use p as struct name
    
    % Create x axis array for creating the vector y
    IMG_x = 0:(1/IMG_sampleRate):(IMG_duration - 1/IMG_sampleRate);
    y = p(IMG_x);
    
    % Detrend JEDI-1P-Kv channel
    proc_green = detrendingFunction(y, proc_green', IMG_sampleRate);
    
    %% 3. Calculate dF/F 
    
    % choose baseline from 2 - 2.5 seconds (range can be changed)
    BaselineFrameN = round(IMG_sampleRate/2);
    BaselineFrameStart = round(IMG_sampleRate * 2 + 1);
    BaselineFrameEnd = BaselineFrameStart + BaselineFrameN;
    
    % calculate baseline
    baseLine_r = mean(proc_red(:, BaselineFrameStart:BaselineFrameEnd), 2);
    baseLine_g = mean(proc_green(:, BaselineFrameStart:BaselineFrameEnd), 2);
    
    % If the readout is close to zero after baseline subtraction
    % make the value in the pixel all 0. 
    % this should only happen to pixel around the edge with no signal from 
    % the brain
    if baseLine_r ~= 0
        dff_r = (proc_red - baseLine_r)./baseLine_r;
    else
        dff_r = zeros(size(proc_red));
    end
    
    dff_g = (proc_green - baseLine_g)./baseLine_g;
    
    %% 4. Filter JEDI-1P-Kv based on high and low frequency 
    % filter voltage channel to get rid of high frequency noise
    dff_g_b70Hz = lowpass(dff_g', green_pass_fs(2), IMG_sampleRate, ...
        'ImpulseResponse', 'iir', ...   % infinite impulse response
        'Steepness', steepness, ...
        'StopbandAttenuation', 60);     % dB default value
    
    %% Filter reference channel to different freuqency ranges
    % Step 1: filter around heartbeat range
    dff_r_heartbeat = lowpass(dff_r', red_pass_heartbeat(2), IMG_sampleRate, ...
        'ImpulseResponse', 'iir', ...
        'Steepness', steepness, ...
        'StopbandAttenuation', 60);
    
    dff_r_heartbeat = highpass(dff_r_heartbeat, red_pass_heartbeat(1), IMG_sampleRate, ...
        'ImpulseResponse', 'iir', ...
        'Steepness', steepness, ...
        'StopbandAttenuation', 60);
    
    % Step 2: filter around [1, 10]Hz that contains potential motion artifact
    dff_r_motion = lowpass(dff_r', red_pass_motion(2), IMG_sampleRate, ...
        'ImpulseResponse', 'iir', ...
        'Steepness', steepness, ...
        'StopbandAttenuation', 60);
    
    dff_r_motion = highpass(dff_r_motion, red_pass_motion(1), IMG_sampleRate, ...
        'ImpulseResponse', 'iir', ...
        'Steepness', steepness, ...
        'StopbandAttenuation', 60);
    
    % Step 3: Filter below 1Hz to extract slow hemodynamic
    dff_r_slowHemo = lowpass(dff_r', red_pass_slowHemo(2), IMG_sampleRate, ...
        'ImpulseResponse', 'iir', ...
        'Steepness', steepness, ...
        'StopbandAttenuation', 60);
    
    %% Sequential Regression (descending in terms of frequency range)
    % Regress JEDI-1P-Kv channel to get high frequency voltage signal 
    [regressed_g_descending_step1, ~, ~] = regressionAB(dff_r_heartbeat, dff_g_b70Hz);
    [regressed_g_descending_step2, ~, ~] = regressionAB(dff_r_motion , regressed_g_descending_step1);
    [regressed_g_descending_step3, ~, ~] = regressionAB(dff_r_slowHemo, regressed_g_descending_step2);
    
    %% Output calculated dF/F before and after filtering for both JEDI-1P-Kv and reference channels
    % g for JEDI-1P-Kv; r for reference/red
    proc_dff.dff_g = dff_g;                     % dF/F of JEDI-1P channel
    proc_dff.dff_g_b70Hz = dff_g_b70Hz;         % dF/F of JEDI-1P channel below 70 Hz
    
    proc_dff.dff_r = dff_r;                     % dF/F of reference channel
    proc_dff.dff_r_heartbeat = dff_r_heartbeat; % dF/F reference around heartbeat
    proc_dff.dff_r_motion = dff_r_motion;       % dF/F reference for potential motion
    proc_dff.dff_r_slowHemo = dff_r_slowHemo;   % dF/F reference for slow hemodynamic
    
    % regressed trace from each regression step
    regressed_traces.regressed_g_descending_step1 = regressed_g_descending_step1;
    regressed_traces.regressed_g_descending_step2 = regressed_g_descending_step2;
    regressed_traces.regressed_g_descending_step3 = regressed_g_descending_step3;
end

%% detrendingFunction uses Ordinary Least Squares method to correct photobleaching
function [regressed_B] = detrendingFunction(trace_A, trace_B, IMG_sampleRate)
    % trace to be regressed: raw JEDI-1P-Kv channel
    trace2regress = trace_B; 
    % trace to regress from: fitted photobleaching decay
    rg = trace_A;

    % To avoid having to permute the matrix mannually in case the size of
    % of the matrix is not the same
    if size(trace2regress) ~= size(rg)
        trace2regress = trace2regress';
    end

    %% Calculate the mean starting from 6s towards the end of the trial
    % Number of frames to calculate idle mean 
    indStart = IMG_sampleRate * 6;  % 6 s
    indEnd = length(trace_B);       % to end of trial
    % The exact start frame can be changed. The goal is to select a period
    % where the trace has stabilized from fast photobleaching. 
    Iidle_mean = mean(trace_B(indStart:indEnd));

    % Calculate beta
    beta = (rg' * rg) \ rg' * trace2regress;

    % regress channel B data and compensate the baseline F
    regressed_B = (trace2regress - rg * beta)' + Iidle_mean;
end

%% regressionAB uses Ordinary Least Squares method to regress out artifacts at different frequency range
function [regressed_B, trace2regress, rg] = regressionAB(trace_A, trace_B)
    % trace to be regressed: JEDI-1P-Kv channel
    trace2regress = trace_B;
    % trace to regress from: reference channel
    rg = trace_A; 

    % To avoid having to permute the matrix mannually in case the size of
    % of the matrix is not the same
    if size(trace2regress) ~= size(rg)
        trace2regress = trace2regress';
    end
    
    % Calculate beta
    beta = (rg' * rg) \ rg' * trace2regress;
    
    % regress channel B data
    regressed_B = (trace2regress - rg * beta)';
end