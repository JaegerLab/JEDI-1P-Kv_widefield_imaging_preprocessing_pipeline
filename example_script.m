%% Example script that preprocesses and plots a set of example traces

%% load example traces and parameter
m = matfile('example_trace.mat');
reference_raw_trace = m.reference_raw_trace;
JEDI_raw_trace = m.JEDI_raw_trace;
parameters = struct(...
    'green_pass_fs', [0, 70], ...       
    'red_pass_heartbeat', [10, 30], ... % band pass filter to extract heartbeat
    'red_pass_motion', [1, 10], ...     % band pass filter to extract motion artifact
    'red_pass_slowHemo', [0.01, 1], ... % lowpass filter for extracting slow hemodynamics
    'steepness', 0.95, ...              % steepness for the filter
    'IMG_duration', 20.48, ...          % imaging trial duration
    'IMG_sampleRate', 200);             % frames/s

%% Process traces
[proc_dff, regressed_traces] = JEDI_preprocessing(reference_raw_trace, JEDI_raw_trace, parameters);

%% Plot before and after regression
IMG_sampleRate = parameters.IMG_sampleRate;
IMG_duration = parameters.IMG_duration;
IMG_x = 0:(1/IMG_sampleRate):(IMG_duration - 1/IMG_sampleRate);

f = figure;
ax = axes(f);
ax.FontSize = 12;
ax.LineWidth = 1;
xlim([0, Inf]);
hold on;

% JEDI-1P-Kv trace filter below 70 Hz
plot(ax, IMG_x, proc_dff.dff_g_b70Hz * 100, ...
    'LineWidth', 0.5, 'Color', [9, 112, 84]/256, ...
    'DisplayName', 'JEDI-1P-Kv: before regression');

% regressed JEDI-1P-Kv trace
plot(ax, IMG_x, proc_dff.dff_r * 100, ...
    'LineWidth', 0.5, 'Color', [0.8500 0.3250 0.0980], ...
    'DisplayName', 'Reference channel');

% regressed JEDI-1P-Kv trace
plot(ax, IMG_x, regressed_traces.regressed_g_descending_step3 * 100, ...
    'LineWidth', 0.5, 'Color', 'b', ...
    'DisplayName', 'JEDI-1P-Kv: after regression');

l = legend('show', 'Location', 'northwest');
l.Box = false;
xlabel('Time (s)');
ylabel('Response, %\DeltaF/F_0');
