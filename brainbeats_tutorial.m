% BrainBeats tutorial
% Launch each section one by one by clicking in the section and pressing: 
% CTRL/CMD + ENTER

clear; close all; clc
eeglab; close; 
mainDir = fileparts(which('eegplugin_BrainBeats.m')); cd(mainDir);

%% METHOD 1: Process file for HEP analysis

EEG = pop_loadset('filename','sample_data1.set','filepath',fullfile(mainDir,'sample_data'));
EEG = brainbeats_process(EEG,'analysis','hep','heart_signal','ECG', ...
    'heart_channels',{'ECG1' 'ECG2'},'clean_rr','pchip','clean_eeg',false, ...
    'parpool',false,'gpu',false,'vis',true,'false',true); 
% pop_eegplot(EEG,1,1,1);

%% METHOD 2: Extract EEG and HRV features

EEG = pop_loadset('filename','sample_data1.set','filepath',fullfile(mainDir,'sample_data'));
EEG = brainbeats_process(EEG,'analysis','features','heart_signal','ECG', ...
    'heart_channels',{'ECG1' 'ECG2'}, 'clean_rr','pchip','clean_eeg',false,'norm',true,...
    'eeg_features', {'time' 'frequency'}, ...
    'hrv_features', {'time' 'frequency' 'nonlinear'}, ...
    'gpu',false,'parpool',false,'save',true,'vis',true);

%% METHOD 3: Remove heart components from EEG signals

EEG = pop_loadset('filename','sample_data2.set','filepath',fullfile(mainDir,'sample_data'));
EEG = brainbeats_process(EEG,'analysis','rm_heart','heart_signal','ECG', ...
    'heart_channels',{'ECG'},'clean_eeg',false,'save',false,'vis',true);

%% Launch GUI via command line

EEG = brainbeats_process(EEG);