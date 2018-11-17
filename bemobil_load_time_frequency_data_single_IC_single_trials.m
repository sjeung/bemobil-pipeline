function time_frequency_data = bemobil_load_time_frequency_data_single_IC_single_trials(input_path, subject, IC, epochs_info_filename,...
    timewarp_name, trial_normalization, times, freqs, freqrange, baseline_start_end, latencyMeans,...
    epoch_rejections, epoch_rejections_for_baseline)

% define frequency and time range of ERSP to plot
if isempty(freqrange)
    freqIndices(1) = freqs(1);
    freqIndices(2) = freqs(end);
else
    freqIndices(1) = find(freqs>freqrange(1),1,'first');
    freqIndices(2) = find(freqs<freqrange(2),1,'last');
end

% load only with the beginning of the baseline
timeIndices(1) = find(times>=baseline_start_end(1),1,'first');
if isempty(latencyMeans)
    disp('No means in latency present, complete ERSP will be loaded.')
    timeIndices(2) = times(end);
else
    disp('Using last timewarp latency mean as time limit of ERSP')
    timeIndices(2) = find(times<latencyMeans(end),1,'last');
end

% load ersp
filepath_ersp_data = [input_path num2str(subject) '/ERSPs/' timewarp_name '/IC_' num2str(IC) '/'];
load([filepath_ersp_data 'all_epochs_ersp'],'all_epochs_ersp')

% load epoch_info. load stores into a struct, so the first element of the struct has to be taken
epochs_info = load([input_path num2str(subject) '/' epochs_info_filename]);
epoch_info_fields = fieldnames(epochs_info);
epochs_info = epochs_info.(epoch_info_fields{1});

all_epochs_ersp = all_epochs_ersp(:, freqIndices(1):freqIndices(2), timeIndices(1):timeIndices(2));

if isempty(epoch_rejections); epoch_rejections = zeros(1,length(epochs_info)); end
if isempty(epoch_rejections_for_baseline); epoch_rejections_for_baseline = zeros(1,length(epochs_info)); end

% save settings
time_frequency_data.info.baseline_start_end = baseline_start_end;
time_frequency_data.info.epoch_rejections_for_ERSPs = epoch_rejections;
time_frequency_data.info.epoch_rejections_for_baseline = epoch_rejections_for_baseline;
time_frequency_data.info.timewarp_name = timewarp_name;
time_frequency_data.freqs = freqs(freqIndices(1):freqIndices(2));
time_frequency_data.times = times(timeIndices(1):timeIndices(2));

% subject_ersp_thisIC_all_epochs_power = NaN(nepochs,length(freqs),length(times));
subject_ersp_thisIC_all_epochs_power = 10.^(all_epochs_ersp/10);
subject_ersp_thisIC_all_epochs_power_unnormalized = subject_ersp_thisIC_all_epochs_power;

if trial_normalization
    full_trial_baselines = nanmean(subject_ersp_thisIC_all_epochs_power,3);
    subject_ersp_thisIC_all_epochs_power = subject_ersp_thisIC_all_epochs_power ./ full_trial_baselines;
end

% save single trials ersp
time_frequency_data.ersp_power = subject_ersp_thisIC_all_epochs_power;

% save single trials baseline
ersps_all_epochs_power_for_baseline = subject_ersp_thisIC_all_epochs_power(~logical(epoch_rejections_for_baseline),:,:);
time_frequency_data.baseline = ersps_all_epochs_power_for_baseline(:,:,find(time_frequency_data.times>baseline_start_end(1),1,'first'):find(time_frequency_data.times<=baseline_start_end(2),1,'last'));


%single(10.*log10(time_frequency_data.grand_average.ersp_power));