function coherence = compute_brainheart_coherence(EEG,params)

disp('Computing brain-heart coherence measures...')
nfft = params.fs*4;  % 4-s windows

% Run multivariate analysis of causal interactions
Su = eye(EEG.nbchan,EEG.nbchan);
[dc,dtf,pdc,gpdc,~,coh,pcoh,~,~,~,~,f] = fdMVAR_5order(EEG.data,Su,nfft,params.fs);

% convert complex numbers to real numbers and positive polarity (0-1)
if ~isreal(coh), coh = abs(coh); end
if ~isreal(pcoh),pcoh = abs(pcoh); end
if ~isreal(dc), dc = abs(dc); end
if ~isreal(pdc), pdc = abs(pdc); end
if ~isreal(gpdc), gpdc = abs(gpdc); end
if ~isreal(dtf), dtf = abs(dtf); end

% Outputs
coherence.freqs = f;
coherence.coh = coh;
coherence.pcoh = pcoh;
coherence.dc = dc;
coherence.pdc = pdc;
coherence.gpdc = gpdc;
coherence.channels = {EEG.chanlocs.labels};

% Plot
if params.vis_outputs

    disp("Plotting brain-heart coherence outputs...")
    
    cardio_chan = strcmpi({EEG.chanlocs.labels},params.heart_channels);
    maxfreq = 40;
    
    % PLOT ALL FREQS AND CHANNELS FOR EACH MEASURE
    figure('color','w')

    subplot(2,2,1) % COHERENCE
    fc = squeeze(coh(cardio_chan,~cardio_chan,f<=maxfreq));  % mean for the band
    imagesc(f(f<maxfreq),1:size(fc,1),fc);  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Coherence','fontsize',12,'fontweight','bold','Rotation',270)
    Ylabels = {EEG.chanlocs.labels}; newticks = 1:2:length(Ylabels); newticks = unique(newticks);
    Ylabels  = Ylabels(newticks); set(gca,'YTick',newticks); set(gca,'YTickLabel', Ylabels,'FontWeight','normal');
    xlabel('Frequency (Hz)'); %title("Coherence")

    subplot(2,2,2)  % PARTIAL COHERENCE
    fc = squeeze(pcoh(cardio_chan,~cardio_chan,f<=maxfreq));  % mean for the band
    imagesc(f(f<maxfreq),1:size(fc,1),fc);  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial coherence','fontsize',12,'fontweight','bold','Rotation',270)
    Ylabels = {EEG.chanlocs.labels}; newticks = 1:2:length(Ylabels); newticks = unique(newticks);
    Ylabels  = Ylabels(newticks); set(gca,'YTick',newticks); set(gca,'YTickLabel', Ylabels,'FontWeight','normal');
    xlabel('Frequency (Hz)'); 
    
    subplot(2,2,3)  % DIRECTED COHERENCE
    fc = squeeze(dc(cardio_chan,~cardio_chan,f<=maxfreq));  % mean for the band
    imagesc(f(f<maxfreq),1:size(fc,1),fc);  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    Ylabels = {EEG.chanlocs.labels}; newticks = 1:2:length(Ylabels); newticks = unique(newticks);
    Ylabels  = Ylabels(newticks); set(gca,'YTick',newticks); set(gca,'YTickLabel', Ylabels,'FontWeight','normal');
    xlabel('Frequency (Hz)'); 
    
    subplot(2,2,4)  % PARTIAL DIRECTED COHERENCE
    fc = squeeze(pdc(cardio_chan,~cardio_chan,f<=maxfreq));  % mean for the band
    imagesc(f(f<maxfreq),1:size(fc,1),fc);  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    Ylabels = {EEG.chanlocs.labels}; newticks = 1:2:length(Ylabels); newticks = unique(newticks);
    Ylabels  = Ylabels(newticks); set(gca,'YTick',newticks); set(gca,'YTickLabel', Ylabels,'FontWeight','normal');
    xlabel('Frequency (Hz)'); 

    % subplot(2,3,5)  % GENERALIZED PARTIAL DIRECTED COHERENCE
    % fc = squeeze(gpdc(cardio_chan,~cardio_chan,f<=maxfreq));  % mean for the band
    % imagesc(f(f<maxfreq),1:size(fc,1),fc);  % cardio in row, EEG in columns
    % clim([0 1]); cb = colorbar; ylabel(cb,'Generalized partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    % Ylabels = {EEG.chanlocs.labels}; newticks = 1:2:length(Ylabels); newticks = unique(newticks);
    % Ylabels  = Ylabels(newticks); set(gca,'YTick',newticks); set(gca,'YTickLabel', Ylabels,'FontWeight','normal');
    % xlabel('Frequency (Hz)'); 
    % 
    % subplot(2,3,6)  % DIRECTED TRANSFER FUNCTION 
    % fc = squeeze(dtf(cardio_chan,~cardio_chan,f<=maxfreq));  % mean for the band
    % imagesc(f(f<maxfreq),1:size(fc,1),fc);  % cardio in row, EEG in columns
    % clim([0 1]); cb = colorbar; ylabel(cb,'Directed transfer function','fontsize',12,'fontweight','bold','Rotation',270)
    % Ylabels = {EEG.chanlocs.labels}; newticks = 1:2:length(Ylabels); newticks = unique(newticks);
    % Ylabels  = Ylabels(newticks); set(gca,'YTick',newticks); set(gca,'YTickLabel', Ylabels,'FontWeight','normal');
    % xlabel('Frequency (Hz)');

    set(findall(gcf,'type','axes'),'fontSize',11,'fontweight','bold');


    % SCALP TOPOGRAPHY FOR EACH BAND: COHERENCE
    figure('color','w')
    subplot(2,2,1)  % delta
    fc = mean(coh(:,:,f<=3),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Delta','fontSize',12,'FontWeight','bold');
    subplot(2,2,2)  % theta
    fc = mean(coh(:,:,f>=3 & f<=7),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Coherence','fontsize',12,'fontweight','bold','Rotation',270)
    ylabel(cb,'Coherence','Rotation',270,'fontSize',12,'fontweight','bold')
    title('Theta','fontSize',12,'FontWeight','bold');
    subplot(2,2,3)  % alpha
    fc = mean(coh(:,:,f>=8 & f<=13),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Alpha','fontSize',12,'FontWeight','bold');
    subplot(2,2,4)  % beta
    fc = mean(coh(:,:,f>13 & f<=30),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Coherence','fontsize',12,'fontweight','bold','Rotation',270)
    ylabel(cb,'Coherence','Rotation',270,'fontSize',12,'fontweight','bold')
    title('Beta','fontSize',12,'FontWeight','bold');
    set(findall(gcf,'type','axes'),'fontSize',11,'fontweight','bold');

    % SCALP TOPOGRAPHY FOR EACH BAND: PARTIAL COHERENCE
    figure('color','w')
    subplot(2,2,1)  % delta
    fc = mean(pcoh(:,:,f<=3),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Delta','fontSize',12,'FontWeight','bold');
    subplot(2,2,2)  % theta
    fc = mean(pcoh(:,:,f>=3 & f<=7),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Theta','fontSize',12,'FontWeight','bold');
    subplot(2,2,3)  % alpha
    fc = mean(pcoh(:,:,f>=8 & f<=13),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Alpha','fontSize',12,'FontWeight','bold');
    subplot(2,2,4)  % beta
    fc = mean(pcoh(:,:,f>13 & f<=30),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Beta','fontSize',12,'FontWeight','bold');
    set(findall(gcf,'type','axes'),'fontSize',11,'fontweight','bold');

    % SCALP TOPOGRAPHY FOR EACH BAND: DIRECTED COHERENCE
    figure('color','w')
    subplot(2,2,1)  % delta
    fc = mean(dc(:,:,f<=3),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Delta','fontSize',12,'FontWeight','bold');
    subplot(2,2,2)  % theta
    fc = mean(dc(:,:,f>=3 & f<=7),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Theta','fontSize',12,'FontWeight','bold');
    subplot(2,2,3)  % alpha
    fc = mean(dc(:,:,f>=8 & f<=13),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Alpha','fontSize',12,'FontWeight','bold');
    subplot(2,2,4)  % beta
    fc = mean(dc(:,:,f>13 & f<=30),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Beta','fontSize',12,'FontWeight','bold');
    set(findall(gcf,'type','axes'),'fontSize',11,'fontweight','bold');

    % SCALP TOPOGRAPHY FOR EACH BAND: PARTIAL DIRECTED COHERENCE
    figure('color','w')
    subplot(2,2,1)  % delta
    fc = mean(pdc(:,:,f<=3),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Delta','fontSize',12,'FontWeight','bold');
    subplot(2,2,2)  % theta
    fc = mean(pdc(:,:,f>=3 & f<=7),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Theta','fontSize',12,'FontWeight','bold');
    subplot(2,2,3)  % alpha
    fc = mean(pdc(:,:,f>=8 & f<=13),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Alpha','fontSize',12,'FontWeight','bold');
    subplot(2,2,4)  % beta
    fc = mean(pdc(:,:,f>13 & f<=30),3,'omitnan');  % mean for the band
    plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    clim([0 1]); cb = colorbar; ylabel(cb,'Partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    title('Beta','fontSize',12,'FontWeight','bold');
    set(findall(gcf,'type','axes'),'fontSize',11,'fontweight','bold');

    % % SCALP TOPOGRAPHY FOR EACH BAND: GENERALIZED PARTIAL DIRECTED COHERENCE
    % figure('color','w')
    % subplot(2,2,1)  % delta
    % fc = mean(gpdc(:,:,f<=3),3,'omitnan');  % mean for the band
    % plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    % clim([0 1]); cb = colorbar; ylabel(cb,'Generalized partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    % title('Delta','fontSize',12,'FontWeight','bold');
    % subplot(2,2,2)  % theta
    % fc = mean(gpdc(:,:,f>=3 & f<=7),3,'omitnan');  % mean for the band
    % plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    % clim([0 1]); cb = colorbar; ylabel(cb,'Generalized partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    % title('Theta','fontSize',12,'FontWeight','bold');
    % subplot(2,2,3)  % alpha
    % fc = mean(gpdc(:,:,f>=8 & f<=13),3,'omitnan');  % mean for the band
    % plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    % clim([0 1]); cb = colorbar; ylabel(cb,'Generalized partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    % title('Alpha','fontSize',12,'FontWeight','bold');
    % subplot(2,2,4)  % beta
    % fc = mean(gpdc(:,:,f>13 & f<=30),3,'omitnan');  % mean for the band
    % plot_topo(fc(cardio_chan,~cardio_chan), params.chanlocs, 1, 'psd');  % cardio in row, EEG in columns
    % clim([0 1]); cb = colorbar; ylabel(cb,'Generalized partial directed coherence','fontsize',12,'fontweight','bold','Rotation',270)
    % title('Beta','fontSize',12,'FontWeight','bold');
    % set(findall(gcf,'type','axes'),'fontSize',11,'fontweight','bold');

    % Course plot
    % subplot(2,2,1)
    % plot(coh_delta,'linewidth',2)
    % labels = {EEG.chanlocs(~cardio_chan).labels};
    % xticks(gca, 1:length(labels));
    % xticklabels(gca, labels);
    % % set(gca, 'XTickLabelRotation', 45);
    % % yticks(gca, mean(get(gca, 'YLim'))); % Position the tick at the middle of the y-axis range
    % % yticklabels(gca, {'ECG'});
    % yticks([]);
    % ylabel('Coherence','FontWeight','bold','FontSize',11)
    % % set(findall(gcf,'type','axes'),'fontSize',10,'fontweight','bold');
    % title('Delta band (<3 hz)','fontSize',12,'FontWeight','bold');
    % box off; grid off

end
