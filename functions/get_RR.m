% Detect R peaks from raw ECG signals and heartbeat onsets (pulse
% waveforms) from PPG signals. 
% 
% ECG: 
%   ECG signal is bandpassed filtered using a custom filter that provides 
%   great performance. QRS detector is based on the P&T method. Energy 
%   threshold is estimated at 99% of amplitude distribution to avoid crash 
%   due to large bumps. 1 s removed for choosing thresh because of filter 
%   lag and often contains artifacts. A search-back algorithm detects missed
%   peaks by lowering the threshold in periods where the RR interval 
%   variability (RRv) is > 1.5*medianRRv. The polarity of the R-peaks is 
%   detected over the first 30 s using max of abs values. The rest of the 
%   peaks are compared to this sign, preventing from alternating between
%   positive/negative detections. 
%
% PPG:
%   Algorithms designed for adult human signals sampled at 125 Hz, but works
%   with any sampling rate (using on-the-fly resampling). 
%
% They are remove/interpolate artifacts
% INPUTS:
%   signal : raw ECG signal (in mV)
%   srate : sampling rate
%   winSize: window size
%   vis: visualize each segment (1) or not (0)
%
% OUTPUTS:
%   rr_peaks:
%

%
% Original code from the Physionet Cardiovascular Signal Processing Toolbox
% function called qppg
% Original authors: W. Zong (1998), revised by G. Moody (2010), Qiao Li
% (2010-2011), Adriana Vest (2011), and Giulia Da Poian (2018).
%
% When using this code, please cite:
% Vest et al. (2018). An Open Source Benchmarked Toolbox for Cardiovascular
%   Waveform and Interval Analysis. Physiological measurement.
%
% Copyright (C) - Cedric Cannard, 2023, BrainBeats toolbox


% REFS:
%
%   [1] Behar Joachim, Jonhson Alistair, Clifford Gari D., Oster Julien A
%   Comparison of Single Channel Foetal ECG Extraction Methods.
%   Annals of Biomedical Engineering. 42(6), 1340-53. 2014
%
%   [2] Johnson Alistair E W, Behar Joachim, Oster Julien and Clifford Gari
%   D. R-Peak Estimation using Multimodal Lead Switching.
%
% Inputs
%   signal     - ecg signal
%   srate      - sample rate
%   winSize    - window size (in s) onto which to perform QRS detection (default = 15)
%   peakThresh     - threshold to be used
%   vis        - visuzalize each segment (1) or not (0)
%
% output
%   r_all       - indexes of detected R peaks (in samples, ms)
%   signal_all  - raw ECG signal filtered
%   sign        - sign of the peaks (positive or negative)
%   en_thres    - P&T energy threshold used
%
% Cedric Cannard, 2023

function [RR, RR_t, maxloc, sig, tm, HR] = get_RR(signal, params)

if strcmp(params.heart_signal, 'ecg')

    % params
    peakThresh = .6;
    search_back = true;     % perform search back
    ref_period = 0.25;      % refractory period
    
    % sign of peaks is determined by the sign on the 1st window and then is forced for the following windows.
    % [tmpQRS, ecg, ecg_filtered, tm] = get_qrs(signal(start-dTminus:stop+dTplus),srate,peakThresh,vis);
    % [qrs_pos, ecg, ecg_filtered, tm, sign, en_thres] = get_qrs(ecg, srate, peakThresh, vis)
    % signal_seg = signal(start-dTminus:stop+dTplus);
    srate = params.fs;
    signal_seg = signal;
    nSamp = size(signal_seg,1);
    % tm = 1/srate:1/srate:ceil(nSamp/srate);
    tm = 1/srate:1/srate:nSamp/srate;
    
    % Constants
    med_smooth_nb_coef = round(srate/100);
    int_nb_coef = round(7*srate/256);   % length is 7 for srate = 256Hz
    max_force = [];                     % to force the energy threshold value
    min_amp = 0.1;                      % if the median of the filtered ECG is inferior to MINAMP then it is likely to be a flatline (ECG must be mV here)
    nSamp = length(signal_seg);       % number of input samples
    
    % Bandpass filter ECG signal. This sombrero hat has shown to give slightly
    % better results than a standard band-pass filter.
    b1 = [-7.757327341237223e-05  -2.357742589814283e-04 -6.689305101192819e-04 -0.001770119249103 ...
        -0.004364327211358 -0.010013251577232 -0.021344241245400 -0.042182820580118 -0.077080889653194...
        -0.129740392318591 -0.200064921294891 -0.280328573340852 -0.352139052257134 -0.386867664739069 ...
        -0.351974030208595 -0.223363323458050 0 0.286427448595213 0.574058766243311 ...
        0.788100265785590 0.867325070584078 0.788100265785590 0.574058766243311 0.286427448595213 0 ...
        -0.223363323458050 -0.351974030208595 -0.386867664739069 -0.352139052257134...
        -0.280328573340852 -0.200064921294891 -0.129740392318591 -0.077080889653194 -0.042182820580118 ...
        -0.021344241245400 -0.010013251577232 -0.004364327211358 -0.001770119249103 -6.689305101192819e-04...
        -2.357742589814283e-04 -7.757327341237223e-05];
    b1 = resample(b1,srate,250);
    sig = filtfilt(b1,1,double(signal_seg))';
    
    % Plot spectra 
    % figure; 
    % subplot(2,1,1)
    % Fs = 250;
    % [pwr, f] = get_psd(sig,Fs*2,'hann',50,[],Fs,[0 60],'psd');
    % plot(f, pwr);
    % subplot(2,1,2)
    % spectrogram(sig,kaiser(256,5),220,512,Fs);
    % view(-45,65); colormap bone; xlim([0 50])
    
    % If 20% of the samples have an absolute amplitude which is higher
    % than min_amp then we are good to go.
    if length(find(abs(sig)>min_amp))/nSamp > 0.20
    
        % P&T operations
        dffecg = diff(sig');  % (4) differentiate (one datum shorter)
        sqrecg = dffecg.*dffecg; % (5) square ecg
        intecg = filter(ones(1,int_nb_coef),1,sqrecg); % (6) integrate
        mdfint = medfilt1(intecg,med_smooth_nb_coef);  % (7) smooth
        delay  = ceil(int_nb_coef/2);
        mdfint = circshift(mdfint,-delay); % remove filter delay for scanning back through ECG
    
        % P&T threshold
        if nSamp/srate>90
            xs = sort(mdfint(srate:srate*90));
        else
            xs = sort(mdfint(srate:end));
        end
    
        if isempty(max_force)
            if nSamp/srate>10
                ind_xs = ceil(98/100*length(xs));
                en_thres = xs(ind_xs); % if more than ten seconds of ecg then 98% CI
            else
                ind_xs = ceil(99/100*length(xs));
                en_thres = xs(ind_xs); % else 99% CI
            end
        else
            en_thres = max_force;
        end
    
        % build an array of segments to look into
        poss_reg = mdfint>(peakThresh*en_thres);
    
        % in case empty because force threshold and crap in the signal
        if isempty(poss_reg)
            poss_reg(10) = 1;
        end
    
        % P&T QRS detection & search back
        if search_back
            indAboveThreshold = find(poss_reg); % ind of samples above threshold
            RRv = diff(tm(indAboveThreshold));  % compute RRv
            medRRv = median(RRv(RRv>0.01));
            indMissedBeat = find(RRv>1.5*medRRv); % missed a peak?
            % find interval onto which a beat might have been missed
            indStart = indAboveThreshold(indMissedBeat);
            indEnd = indAboveThreshold(indMissedBeat+1);
    
            % look for a peak on this interval by lowering the energy threshold
            for i = 1:length(indStart)
                poss_reg(indStart(i):indEnd(i)) = mdfint(indStart(i):indEnd(i))>(0.5*peakThresh*en_thres);
            end
        end
    
        % find indices into boudaries of each segment
        left  = find(diff([0 poss_reg'])==1);  % remember to zero pad at start
        right = find(diff([poss_reg' 0])==-1); % remember to zero pad at end
    
        % looking for max/min?
        nb_s = length(left<30*srate);
        loc  = zeros(1,nb_s);
        for j=1:nb_s
            [~,loc(j)] = max(abs(sig(left(j):right(j))));
            loc(j) = loc(j)-1+left(j);
        end
        sign = median(sig(loc));  % median was mean & sig was signal_seg originally here
    
        % loop through all possibilities
        compt = 1;
        nb_peaks = length(left);
        maxval = zeros(1,nb_peaks);
        maxloc = zeros(1,nb_peaks);
        for i = 1:nb_peaks
            if sign > 0 % if sign is positive then look for positive peaks
                [maxval(compt), maxloc(compt)] = max(sig(left(i):right(i))); % sig was signal_seg originally here
            else % if sign is negative then look for negative peaks
                [maxval(compt), maxloc(compt)] = min(sig(left(i):right(i))); % sig was signal_seg originally here
            end
    
            % add offset of present location
            maxloc(compt) = maxloc(compt)-1+left(i);
    
            % refractory period - improve results
            if compt > 1
                if maxloc(compt)-maxloc(compt-1)<srate*ref_period && abs(maxval(compt))<abs(maxval(compt-1))
                    maxloc(compt)=[];
                    maxval(compt)=[];
                elseif maxloc(compt)-maxloc(compt-1)<srate*ref_period && abs(maxval(compt))>=abs(maxval(compt-1))
                    maxloc(compt-1)=[];
                    maxval(compt-1)=[];
                else
                    compt=compt+1;
                end
            else % if first peak then increment
                compt=compt+1;
            end
        end
    
        % r_pos = maxloc;       % QRS datapoint positions
        % r_t = tm(maxloc);     % QRS timestamp positions
        % r_amp = maxval;       % amplitude at QRS positions
        % hr = 60./diff(r_t);   % heart rate
    
    else
        error('This is a flat line')
        % r_pos = [];
        % r_t = [];
        % r_amp = [];
        % hr = [];
        % sign = [];
        % en_thres = [];
    end
    
    if sign < 0
        fprintf(" - Peaks' polarity: negative \n");
    else
        fprintf(" - Peaks' polarity: positive \n");
    end
    fprintf(' - P&T energy threshold: %g \n', en_thres)

    % RR intervals and HR
    RR = diff(maxloc) ./ params.fs;   % RR intervals in s
    RR_t = maxloc ./ params.fs;       % RR timestamps (always ignore 1st heartbeat)
    % RR_t = cumsum(maxloc);        % alternative method for RR timestamps
    HR = 60 ./ diff(tm(maxloc));   % heart rate (in bpm)

    % Visualize each segment
    % if vis
    %     figure('color','w');
    %     subplot(2,1,1);
    %     plot(tm,sig,'color','#0072BD'); hold on;
    %     plot(r_t,sig(r_pos),'.','MarkerSize',10,'color','#D95319');
    %     % plot(r_t,r_amp,'.','MarkerSize',10,'color','#D95319');
    %     title('Filtered ECG signal + R peaks');
    %     ylabel('mV'); xlim([0 tm(end)]); set(gca,'XTick',[])
    %
    %     subplot(2,1,2);
    %     plot(r_t(1:length(hr)),hr,'--','color','#A2142F','linewidth',1);
    %     xlim([0 tm(end)]);
    %     title('Heart Rate'); xlabel('Time (s)'); ylabel('bpm');
    %
    %     set(findall(gcf,'type','axes'),'fontSize',10,'fontweight','bold');
    % end

else 


end
