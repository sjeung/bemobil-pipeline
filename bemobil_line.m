% bemobil_line() - Line noise filtering of EEG data. Information about the 
% filter is stored in EEG.etc.filter.line. 
% Zapline is used by default. (See reference link) 
% Filter component number can by optionally specified (default 2).
% 
% Usage:
%   >>  [ ALLEEG EEG CURRENTSET ] = bemobil_line(ALLEEG, EEG, CURRENTSET, frequencies);
%   >>  [ ALLEEG EEG CURRENTSET ] = bemobil_line(ALLEEG, EEG, CURRENTSET, frequencies, out_filename, out_filepath);
%   >>  [ ALLEEG EEG CURRENTSET ] = bemobil_line(ALLEEG, EEG, CURRENTSET, frequencies, out_filename, out_filepath, algorithm, order);
%
% Inputs:
%   ALLEEG                  - complete EEGLAB data set structure
%   EEG                     - current EEGLAB EEG structure
%   CURRENTSET              - index of current EEGLAB EEG structure within ALLEEG
%   frequencies             - array of line noise frequencies to be cleaned
%   out_filename            - OPTIONAL output filename 
%   out_filepath            - OPTIONAL output filepath - File will only be saved on disk
%                             if both a name and a path are provided and not empty)
%	componentNumbers        - OPTIONAL specify the number of noise
%                             components to be removed for each frequency
%                             Array size has to match variable "frequencies"								
%
% Outputs:
%   ALLEEG                  - complete EEGLAB data set structure
%   EEG                     - current EEGLAB EEG structure
%   Currentset              - index of current EEGLAB EEG structure within ALLEEG
%
%   .set data file of current EEGLAB EEG structure stored on disk (OPTIONALLY)
%
% See also:
%   EEGLAB, pop_eegfiltnew, bemobil_preprocess
% 
% Authors: 

function [ ALLEEG EEG CURRENTSET ] = bemobil_line(ALLEEG, EEG, CURRENTSET, frequencies, out_filename, out_filepath, componentNumbers)


% default filter type 
filterType      = 'zapline'; 

% default component number 
defaultNComp    = 2; 

% only save a file on disk if both a name and a path are provided
save_file_on_disk = (exist('out_filename', 'var') && exist('out_filepath', 'var')) && ~isempty(out_filename) && ~isempty(out_filepath);

% check if file already exist and show warning if it does
if save_file_on_disk
    mkdir(out_filepath); % make sure that folder exists, nothing happens if so
    dir_files = dir(out_filepath);
    if ismember(out_filename, {dir_files.name})
        warning([out_filename ' file already exists in: ' out_filepath '. File will be overwritten...']);
    end
end

if ~isempty(frequencies)
    EEG.etc.filter.line.type = filterType;
else
    error('No line noise frequency specified.')
end

if ~isempty(componentNumbers)
    if numel(componentNumbers) == numel(frequencies)
        EEG.etc.filter.line.componentnumbers = componentNumbers;
    else
        error('Component numbers do not match the number of frequencies.')
    end
else
    componentNumbers    = repelem(defaultNComp, 1, numel(frequencies));  
    disp(['Using default component number (' num2str(defaultNComp) ') for cleaning by Zapline.'])
end


% highpass
if ~isempty(lowerPassbandEdge)
   
    figure;
    [EEG, com, b] = pop_eegfiltnew(EEG, lowerPassbandEdge, 0, highPassFilterOrder, 0, [], 1);
    EEG = eeg_checkset( EEG );
    
    if save_file_on_disk; saveas(gcf,[out_filepath '\filter_response_highpass']); end
    
    split1 = strsplit(com, ' ');
    split2 = strsplit(split1{4}, ',');
	highpass_order = str2num(split2{3});
    highpass_passband = lowerPassbandEdge;
	
	if isempty(highPassFilterOrder)
		maxDf = lowerPassbandEdge;
		highpass_transition_bandwidth = min([max([maxDf * 0.25 2]) maxDf]); % this comes from pop_eegfiltnew
	else
		highpass_transition_bandwidth = 3.3 / highpass_order * EEG.srate; % this comes from pop_eegfiltnew
	end
	
    highpass_cutoff = highpass_passband-highpass_transition_bandwidth/2;
    
    disp(['Highpass filtered the data with ' num2str(highpass_passband) 'Hz passband edge, '...
        num2str(highpass_transition_bandwidth) 'Hz transition bandwidth, '...
        num2str(highpass_cutoff) 'Hz cutoff, and '...
        num2str(highpass_order) ' order.']);
    
    % removing and remaking the filed is necessary for the order of the struct fields to be identical
    if isfield(EEG.etc.filter,'highpass');  EEG.etc.filter = rmfield(EEG.etc.filter, 'highpass'); end 
    EEG.etc.filter.highpass.cutoff = highpass_cutoff;
    EEG.etc.filter.highpass.transition_bandwidth = highpass_transition_bandwidth;
    EEG.etc.filter.highpass.passband = highpass_passband;
    EEG.etc.filter.highpass.order = highpass_order;
    close;
else
    
    if ~isfield(EEG.etc.filter,'highpass')
        EEG.etc.filter.highpass = 'not applied'; 
    else
        % removing and remaking the field is necessary for the order of the struct fields to be identical
		% yes I know, but I just have to.
        temp = EEG.etc.filter.highpass;
        EEG.etc.filter = rmfield(EEG.etc.filter, 'highpass');
        EEG.etc.filter.highpass = temp;
    end
    
end

%--------------------------------------------------------------------------
%%% remove line noise from original data

% requires noiseTool
for freqIndex = 1:numel(bemobil_config.selec_lineNoiseFreq{segment})
    
    freq = bemobil_config.selec_lineNoiseFreq{segment}(freqIndex);
    
    x = EEG(segment).data';
    x = nt_demean(x);
    
    % parameters
    FLINE = freq/EEG.srate; % line frequency
    NREMOVE = 3; % number of components to remove
    
    tic;
    [denoised, noise] = nt_zapline(x,FLINE,NREMOVE);
    toc;
    
    EEG.data = denoised';
    
    set(gcf, 'PaperPositionMode', 'auto');
    print ('-dtiff');
    
end


EEG.etc.filter.line.frequency = frequencies;
EEG.etc.filter.line.order = filterOrder;


%--------------------------------------------------------------------------

% new data set in EEGLAB
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'gui', 'off');
EEG = eeg_checkset( EEG );

% save on disk
if save_file_on_disk
    EEG = pop_saveset( EEG, 'filename',out_filename,'filepath', out_filepath);
    disp('...done');
end

[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
