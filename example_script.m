%% Example script that preprocesses and plots a set of example traces

%% load example traces and parameter

load('C:\Analysis_Scripts\JEDI-1P-Kv_preprocessing_pipeline\JEDI-1P-Kv_widefield_imaging_preprocessing_pipeline\example_trace_and_parameters.mat')
%%
[proc_dff, regressed_traces] = JEDI_preprocessing(reference_raw_trace, JEDI_raw_trace, parameters);

%% Plot before and after regression

IMG_sampleRate = parameters.IMG_sampleRate;
IMG_duration = parameters.IMG_duration;

IMG_x = 0:(1/IMG_sampleRate):(IMG_duration - 1/IMG_sampleRate);

plot(IMG_x, proc_dff.dff_g_b70Hz * 100, 'LineWidth', 0.5, 'Color', [9, 112, 84]/256) % JEDI-1P-Kv trace filter below 70 Hz
hold on

plot(IMG_x, proc_dff.dff_r * 100, 'LineWidth', 0.5, 'Color', [0.8500 0.3250 0.0980]) % regressed JEDI-1P-Kv trace

plot(IMG_x, regressed_traces.regressed_g_descending_step3 * 100, 'LineWidth', 0.5, 'Color', 'b') % regressed JEDI-1P-Kv trace
xlim([0, max(IMG_duration)])

legend('JEDI-1P-Kv: before regression', 'reference channel', 'JEDI-1P-Kv: after regression', 'FontSize', 12, 'Location', 'northwest')
xlabel('Time (s)', 'FontSize', 12)
ylabel('dF/F %', 'FontSize', 12)
legend box off

ax = gca;
ax.FontSize = 12; 
ax.LineWidth = 1;
set(gca,'box','off')